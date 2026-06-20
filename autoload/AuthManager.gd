## AuthManager.gd
## =============================================================
## Manages the Supabase auth session entirely inside Godot.
## Works in the browser (WASM) and on iOS — no postMessage bridge.
##
## Configure credentials in your .env equivalent by setting:
##   AuthManager.SUPABASE_URL  and  AuthManager.SUPABASE_ANON_KEY
## (or export them via a build step / Godot project settings export var).
##
## Usage:
##   await AuthManager.sign_up("email", "pass")
##   await AuthManager.sign_in("email", "pass")
##   AuthManager.sign_out()
##   AuthManager.is_logged_in()
##   AuthManager.user_id()          -> String
##   AuthManager.display_name()     -> String
## =============================================================
extends Node

# ─────────────────────────────────────────────────────────────
# SIGNALS
# ─────────────────────────────────────────────────────────────
signal logged_in(user_id: String)
signal logged_out()
signal auth_failed(reason: String)

# ─────────────────────────────────────────────────────────────
# CREDENTIALS — override these via ProjectSettings exports or
# a GDScript config file that is git-ignored.
# ─────────────────────────────────────────────────────────────
const SUPABASE_URL:      String = "https://urzcegnzxswdkyazqrlt.supabase.co"
const SUPABASE_ANON_KEY: String = "sb_publishable_WUBl9NlHrb4AbmN07K5w9Q_UcVBFXV_ "

const SESSION_FILE: String = "user://session.json"
const TOKEN_REFRESH_MARGIN_SEC: float = 60.0  # Refresh this many seconds before expiry

# ─────────────────────────────────────────────────────────────
# SESSION STATE
# ─────────────────────────────────────────────────────────────
var _session: Dictionary = {}  # access_token, refresh_token, expires_at, user{}
var _refresh_timer: Timer


func _ready() -> void:
	SupabaseClient.configure(SUPABASE_URL, SUPABASE_ANON_KEY)

	_refresh_timer = Timer.new()
	_refresh_timer.one_shot = true
	_refresh_timer.timeout.connect(_on_refresh_timer)
	add_child(_refresh_timer)

	_load_session()


# ─────────────────────────────────────────────────────────────
# PUBLIC API
# ─────────────────────────────────────────────────────────────
func is_logged_in() -> bool:
	return _session.has("access_token") and _session["access_token"] != ""


func user_id() -> String:
	return _session.get("user", {}).get("id", "")


func display_name() -> String:
	return _session.get("user", {}).get("email", "")


## Sign up with email + password.
## Returns { "ok": bool, "error": String }.
func sign_up(email: String, password: String) -> Dictionary:
	var result := await SupabaseClient.post(
		"auth/v1/signup",
		{"email": email, "password": password}
	)
	if result["ok"]:
		_apply_session(result["data"])
		print("[AuthManager] Signed up: ", email)
	else:
		emit_signal("auth_failed", result["error"])
		print("[AuthManager] Sign-up failed: ", result["error"])
	return result


## Sign in with email + password.
## Returns { "ok": bool, "error": String }.
func sign_in(email: String, password: String) -> Dictionary:
	var result := await SupabaseClient.post(
		"auth/v1/token?grant_type=password",
		{"email": email, "password": password}
	)
	if result["ok"]:
		_apply_session(result["data"])
		print("[AuthManager] Signed in: ", email)
		emit_signal("logged_in", user_id())
	else:
		emit_signal("auth_failed", result["error"])
		print("[AuthManager] Sign-in failed: ", result["error"])
	return result


## Sign out and clear the local session.
func sign_out() -> void:
	if is_logged_in():
		# Best-effort server-side logout (ignore failures).
		await SupabaseClient.post("auth/v1/logout", {}, true)

	_clear_session()
	emit_signal("logged_out")
	print("[AuthManager] Signed out.")


## Manually refresh the access token. Called automatically by the timer.
func refresh_token() -> Dictionary:
	var rt: String = _session.get("refresh_token", "")
	if rt.is_empty():
		return {"ok": false, "error": "No refresh token"}

	var result := await SupabaseClient.post(
		"auth/v1/token?grant_type=refresh_token",
		{"refresh_token": rt}
	)
	if result["ok"]:
		_apply_session(result["data"])
		print("[AuthManager] Token refreshed.")
	else:
		print("[AuthManager] Token refresh failed: ", result["error"])
		_clear_session()
		emit_signal("logged_out")
	return result


# ─────────────────────────────────────────────────────────────
# SESSION HELPERS
# ─────────────────────────────────────────────────────────────
func _apply_session(data: Dictionary) -> void:
	if data == null or not data is Dictionary:
		return

	_session = {
		"access_token":  data.get("access_token",  ""),
		"refresh_token": data.get("refresh_token", ""),
		"expires_at":    data.get("expires_at",    0),   # unix timestamp
		"token_type":    data.get("token_type",    "bearer"),
		"user":          data.get("user",          {}),
	}

	SupabaseClient.set_access_token(_session["access_token"])
	_save_session()
	_schedule_refresh()


func _clear_session() -> void:
	_session = {}
	SupabaseClient.clear_access_token()
	_delete_session_file()
	_refresh_timer.stop()


func _schedule_refresh() -> void:
	var expires_at: float = float(_session.get("expires_at", 0))
	var now: float = float(Time.get_unix_time_from_system())
	var wait: float = expires_at - now - TOKEN_REFRESH_MARGIN_SEC
	if wait > 0:
		_refresh_timer.start(wait)
	else:
		# Already near expiry — refresh immediately.
		_on_refresh_timer()


func _on_refresh_timer() -> void:
	if is_logged_in():
		await refresh_token()


# ─────────────────────────────────────────────────────────────
# SESSION PERSISTENCE (stay logged in across app restarts)
# ─────────────────────────────────────────────────────────────
func _save_session() -> void:
	var file := FileAccess.open(SESSION_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_session))
		file.close()


func _load_session() -> void:
	if not FileAccess.file_exists(SESSION_FILE):
		return

	var file := FileAccess.open(SESSION_FILE, FileAccess.READ)
	if file == null:
		return

	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return
	file.close()

	var data: Dictionary = json.get_data()
	if not data.has("access_token") or not data.has("refresh_token"):
		return

	# Check if the token has already expired.
	var expires_at: float = float(data.get("expires_at", 0))
	var now: float = float(Time.get_unix_time_from_system())

	if now >= expires_at - TOKEN_REFRESH_MARGIN_SEC:
		# Attempt silent refresh with the stored refresh token.
		_session = data
		SupabaseClient.set_access_token(data.get("access_token", ""))
		await refresh_token()
	else:
		_apply_session(data)
		emit_signal("logged_in", user_id())
		print("[AuthManager] Restored session for: ", display_name())


func _delete_session_file() -> void:
	if FileAccess.file_exists(SESSION_FILE):
		DirAccess.remove_absolute(SESSION_FILE)
