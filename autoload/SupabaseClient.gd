## SupabaseClient.gd
## =============================================================
## Thin HTTPRequest wrapper for the Supabase REST API.
## Queues requests so concurrent calls don't clash.
##
## Configure before first use (called by AuthManager on _ready):
##   SupabaseClient.configure(url, anon_key)
##
## Usage:
##   var result = await SupabaseClient.call_rpc("spend_tokens", {"p_amount": 5})
##   var result = await SupabaseClient.post("auth/v1/token?grant_type=password", body)
##   var result = await SupabaseClient.get_row("profiles", "id=eq." + user_id)
## =============================================================
extends Node

# ─────────────────────────────────────────────────────────────
# SIGNALS
# ─────────────────────────────────────────────────────────────
signal request_failed(path: String, error: String)

# ─────────────────────────────────────────────────────────────
# CONFIG — set via configure() from AuthManager
# ─────────────────────────────────────────────────────────────
var _url:      String = ""
var _anon_key: String = ""
var _access_token: String = ""  # Set by AuthManager after login

# ─────────────────────────────────────────────────────────────
# QUEUE — one HTTPRequest node handles one call at a time
# ─────────────────────────────────────────────────────────────
var _queue: Array = []
var _busy:  bool  = false

var _http: HTTPRequest


func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)


# ─────────────────────────────────────────────────────────────
# PUBLIC API
# ─────────────────────────────────────────────────────────────
func configure(supabase_url: String, anon_key: String) -> void:
	_url      = supabase_url.trim_suffix("/")
	_anon_key = anon_key
	print("[SupabaseClient] Configured for: ", _url)


func set_access_token(token: String) -> void:
	_access_token = token


func clear_access_token() -> void:
	_access_token = ""


## Call a Supabase Postgres RPC function.
## Returns { "ok": bool, "data": Variant, "error": String }.
func call_rpc(function_name: String, params: Dictionary = {}) -> Dictionary:
	return await _enqueue(
		HTTPClient.METHOD_POST,
		"/rest/v1/rpc/" + function_name,
		params,
		true
	)


## POST to any Supabase endpoint (auth, etc.).
func post(path: String, body: Dictionary, authed: bool = false) -> Dictionary:
	return await _enqueue(HTTPClient.METHOD_POST, "/" + path.trim_prefix("/"), body, authed)


## GET a single row from a table using a PostgREST filter string.
## e.g. get_row("profiles", "id=eq.some-uuid")
func get_row(table: String, filter: String) -> Dictionary:
	var path := "/rest/v1/%s?%s&limit=1" % [table, filter]
	return await _enqueue(HTTPClient.METHOD_GET, path, {}, true)


## GET all rows from a table matching a filter.
func get_rows(table: String, filter: String = "") -> Dictionary:
	var path := "/rest/v1/%s" % table
	if filter != "":
		path += "?" + filter
	return await _enqueue(HTTPClient.METHOD_GET, path, {}, true)


## Upsert a row into a table.
func upsert(table: String, body: Dictionary) -> Dictionary:
	return await _enqueue(
		HTTPClient.METHOD_POST,
		"/rest/v1/" + table,
		body,
		true,
		{"Prefer": "resolution=merge-duplicates,return=representation"}
	)


## PATCH (partial update) rows matching a filter.
func patch(table: String, filter: String, body: Dictionary) -> Dictionary:
	var path := "/rest/v1/%s?%s" % [table, filter]
	return await _enqueue(HTTPClient.METHOD_PATCH, path, body, true)


# ─────────────────────────────────────────────────────────────
# QUEUE IMPLEMENTATION
# ─────────────────────────────────────────────────────────────
func _enqueue(
	method: HTTPClient.Method,
	path:   String,
	body:   Dictionary,
	authed: bool,
	extra_headers: Dictionary = {}
) -> Dictionary:
	# Build a one-shot signal node so we can await per-request.
	var waiter := _RequestWaiter.new()
	_queue.append({
		"method":         method,
		"path":           path,
		"body":           body,
		"authed":         authed,
		"extra_headers":  extra_headers,
		"waiter":         waiter,
	})
	add_child(waiter)
	_process_queue()
	return await waiter.done


func _process_queue() -> void:
	if _busy or _queue.is_empty():
		return
	_busy = true
	var req: Dictionary = _queue.pop_front()
	_dispatch(req)


func _dispatch(req: Dictionary) -> void:
	if _url.is_empty():
		_finish_request(req, {"ok": false, "data": null, "error": "SupabaseClient not configured"})
		return

	var headers: PackedStringArray = [
		"Content-Type: application/json",
		"apikey: " + _anon_key,
		"Accept: application/json",
		"Prefer: return=representation",
	]

	if req["authed"] and _access_token != "":
		headers.append("Authorization: Bearer " + _access_token)

	for key in req["extra_headers"]:
		headers.append(key + ": " + req["extra_headers"][key])

	var full_url: String = _url + req["path"]
	var body_str := ""
	if not req["body"].is_empty() or req["method"] == HTTPClient.METHOD_POST:
		body_str = JSON.stringify(req["body"])

	var _err := _http.request(full_url, headers, req["method"], body_str)
	if _err != OK:
		_finish_request(req, {"ok": false, "data": null, "error": "HTTPRequest error: %d" % _err})
		return

	# Store current request so _on_request_completed can access it.
	_current_req = req


var _current_req: Dictionary = {}


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var req := _current_req
	_current_req = {}

	if result != HTTPRequest.RESULT_SUCCESS:
		_finish_request(req, {"ok": false, "data": null, "error": "Network error: %d" % result})
		return

	var text := body.get_string_from_utf8()
	var json := JSON.new()
	var parse_ok := json.parse(text)

	var data: Variant = null
	if parse_ok == OK:
		data = json.get_data()

	var ok := response_code >= 200 and response_code < 300
	var err_msg := ""
	if not ok:
		if data is Dictionary:
			err_msg = data.get("message", data.get("error_description", data.get("error", text)))
		else:
			err_msg = "HTTP %d" % response_code

	_finish_request(req, {"ok": ok, "data": data, "error": err_msg, "code": response_code})


func _finish_request(req: Dictionary, result: Dictionary) -> void:
	var waiter: _RequestWaiter = req.get("waiter")
	if waiter:
		waiter.resolve(result)
		# Remove on next frame so signal delivery is clean.
		waiter.queue_free()

	_busy = false
	_process_queue()


# ─────────────────────────────────────────────────────────────
# INNER CLASS — per-request awaitable
# ─────────────────────────────────────────────────────────────
class _RequestWaiter extends Node:
	signal done(result: Dictionary)

	func resolve(result: Dictionary) -> void:
		emit_signal("done", result)
