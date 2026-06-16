## CloudSaveManager.gd
## =============================================================
## Bridges the existing local managers (GameState, InventoryManager,
## MissionManager, AvatarManager) to Supabase cloud storage.
##
## Only called when AuthManager.is_logged_in() is true.
## Local save always exists as offline fallback.
##
## Key operations:
##   pull()               — download cloud → hydrate all managers
##   push_blob()          — upload story/flag state (non-economy)
##   grant_reward(src_id) — server-side economy grant, returns summary
##   spend_tokens(amount) — server-side atomic spend
##
## Economy (tokens, XP, inventory, NFTs) is NEVER stored in the blob;
## those live in real Postgres tables mutated only through RPCs.
## =============================================================
extends Node

# ─────────────────────────────────────────────────────────────
# SIGNALS
# ─────────────────────────────────────────────────────────────
signal pull_completed()
signal pull_failed(reason: String)
signal push_completed()
signal push_failed(reason: String)
signal economy_synced(summary: Dictionary)


func _ready() -> void:
	# After login, automatically pull the cloud state.
	AuthManager.logged_in.connect(_on_logged_in)


func _on_logged_in(_uid: String) -> void:
	await pull()


# ─────────────────────────────────────────────────────────────
# PULL — cloud → local managers
# ─────────────────────────────────────────────────────────────

## Download all cloud state and hydrate local managers.
## On first login, if there is a local guest save but no cloud save,
## uploads the guest save first (migration).
func pull() -> void:
	if not AuthManager.is_logged_in():
		return

	var uid := AuthManager.user_id()
	print("[CloudSaveManager] Pulling cloud state...")

	# 1. Profile (tokens, xp, level, avatar).
	var profile_res := await SupabaseClient.get_row("profiles", "id=eq." + uid)
	if not profile_res["ok"]:
		emit_signal("pull_failed", "Profile fetch failed: " + profile_res["error"])
		return
	var profile: Dictionary = {}
	if profile_res["data"] is Array and not profile_res["data"].is_empty():
		profile = profile_res["data"][0]

	# 2. Inventory items.
	var inv_res := await SupabaseClient.get_rows("inventory_items", "user_id=eq." + uid)
	var inv_rows: Array = []
	if inv_res["ok"] and inv_res["data"] is Array:
		inv_rows = inv_res["data"]

	# 3. NFTs.
	var nft_res := await SupabaseClient.get_rows("nfts", "user_id=eq." + uid)
	var nft_rows: Array = []
	if nft_res["ok"] and nft_res["data"] is Array:
		nft_rows = nft_res["data"]

	# 4. Story blob (game_saves).
	var save_res := await SupabaseClient.get_row("game_saves", "user_id=eq." + uid)
	var save_blob: Dictionary = {}
	var cloud_has_save := false
	if save_res["ok"] and save_res["data"] is Array and not save_res["data"].is_empty():
		save_blob = save_res["data"][0].get("save_json", {})
		cloud_has_save = true

	# Guest-save migration: if no cloud save yet, push local save up.
	if not cloud_has_save and SaveManager.has_save_file():
		print("[CloudSaveManager] No cloud save found — migrating local guest save.")
		await push_blob()
		# blob was just pushed; pull the blob back isn't strictly needed,
		# but we continue with the local state we already have.
	elif not save_blob.is_empty():
		_apply_blob(save_blob)

	# Apply economy from profile.
	if not profile.is_empty():
		_apply_profile(profile)

	# Apply inventory.
	_apply_inventory(inv_rows, nft_rows)

	emit_signal("pull_completed")
	print("[CloudSaveManager] Pull complete.")


# ─────────────────────────────────────────────────────────────
# PUSH BLOB — non-economy state → game_saves table
# ─────────────────────────────────────────────────────────────

## Upload story flags, position, settings, mission status to cloud.
## Economy data is intentionally excluded.
func push_blob() -> void:
	if not AuthManager.is_logged_in():
		return

	var uid := AuthManager.user_id()
	var blob := _build_blob()

	var result := await SupabaseClient.upsert("game_saves", {
		"user_id":      uid,
		"save_json":    blob,
		"save_version": SaveManager.SAVE_VERSION,
	})

	if result["ok"]:
		emit_signal("push_completed")
		print("[CloudSaveManager] Blob pushed.")
	else:
		emit_signal("push_failed", result["error"])
		push_error("[CloudSaveManager] Push failed: " + result["error"])


# ─────────────────────────────────────────────────────────────
# SERVER-AUTHORITATIVE ECONOMY
# ─────────────────────────────────────────────────────────────

## Grant a reward by mission/source id via the server-side RPC.
## Returns { "ok": bool, "data": {tokens, xp, nft?, item?}, "error": String }
## Also reconciles local GameState / InventoryManager with the server result.
func grant_reward(source_id: String) -> Dictionary:
	if not AuthManager.is_logged_in():
		return {"ok": false, "error": "Not logged in"}

	var result := await SupabaseClient.call_rpc("grant_for_source", {"p_source_id": source_id})
	if result["ok"] and result["data"] is Dictionary:
		var summary: Dictionary = result["data"]
		# Reconcile local state with what the server says was granted.
		if summary.has("tokens"):
			GameState.vibe_tokens += int(summary.get("tokens", 0))
			GameState.emit_signal("tokens_changed", GameState.vibe_tokens)
		if summary.has("xp"):
			GameState.add_xp(int(summary.get("xp", 0)))
		emit_signal("economy_synced", summary)
	else:
		push_error("[CloudSaveManager] grant_reward failed for '%s': %s" % [source_id, result["error"]])

	return result


## Spend tokens via the server-side RPC (atomic balance check).
## Returns { "ok": bool, "data": {spent, balance}, "error": String }
## On success, reconciles local vibe_tokens with the server balance.
func spend_tokens(amount: int) -> Dictionary:
	if not AuthManager.is_logged_in():
		return {"ok": false, "error": "Not logged in"}

	var result := await SupabaseClient.call_rpc("spend_tokens", {"p_amount": amount})
	if result["ok"] and result["data"] is Dictionary:
		# Trust the server's returned balance.
		var new_balance: int = int(result["data"].get("balance", GameState.vibe_tokens - amount))
		GameState.vibe_tokens = new_balance
		GameState.emit_signal("tokens_changed", new_balance)
	else:
		push_error("[CloudSaveManager] spend_tokens failed: " + result.get("error", "unknown"))

	return result


# ─────────────────────────────────────────────────────────────
# APPLY HELPERS
# ─────────────────────────────────────────────────────────────

func _apply_profile(profile: Dictionary) -> void:
	GameState.player_level  = int(profile.get("player_level",  GameState.player_level))
	GameState.player_xp     = int(profile.get("player_xp",     GameState.player_xp))
	GameState.vibe_tokens   = int(profile.get("vibe_tokens",   GameState.vibe_tokens))
	GameState.player_name   = str(profile.get("player_name",   GameState.player_name))
	GameState.player_age    = int(profile.get("player_age",    GameState.player_age))
	GameState.player_sex    = str(profile.get("player_sex",    GameState.player_sex))

	var avatar_data: Variant = profile.get("avatar", null)
	if avatar_data is Dictionary:
		AvatarManager.from_dict(avatar_data)

	GameState.emit_signal("tokens_changed", GameState.vibe_tokens)
	GameState.emit_signal("xp_changed", GameState.player_xp, GameState.player_level)


func _apply_blob(blob: Dictionary) -> void:
	# Restore story flags and mission state from the blob.
	# Economy fields are intentionally ignored even if present.
	if blob.has("game_state"):
		var gs: Dictionary = blob["game_state"]
		GameState.has_leash              = gs.get("has_leash",              GameState.has_leash)
		GameState.daisy_captured         = gs.get("daisy_captured",         GameState.daisy_captured)
		GameState.daisy_haircut          = gs.get("daisy_haircut",          GameState.daisy_haircut)
		GameState.daisy_outfit           = gs.get("daisy_outfit",           GameState.daisy_outfit)
		GameState.password_factory_level = gs.get("password_factory_level", GameState.password_factory_level)
		GameState.is_vip                 = gs.get("is_vip",                 GameState.is_vip)
		GameState.aquarium_entry_paid    = gs.get("aquarium_entry_paid",    GameState.aquarium_entry_paid)
		GameState.aquarium_animals_freed = gs.get("aquarium_animals_freed", GameState.aquarium_animals_freed)
		GameState.road_journey_active    = gs.get("road_journey_active",    GameState.road_journey_active)
		GameState.road_time_remaining    = gs.get("road_time_remaining",    GameState.road_time_remaining)
		GameState.road_milestone         = gs.get("road_milestone",         GameState.road_milestone)
		GameState.zia_curse_active       = gs.get("zia_curse_active",       GameState.zia_curse_active)
		GameState.daisy_is_frog          = gs.get("daisy_is_frog",          GameState.daisy_is_frog)
		GameState.remi_bald              = gs.get("remi_bald",              GameState.remi_bald)
		GameState.current_scene          = gs.get("current_scene",          GameState.current_scene)
		GameState.player_position        = Vector2(
			gs.get("player_position_x", 0.0),
			gs.get("player_position_y", 0.0)
		)
		GameState.has_active_game        = gs.get("has_active_game",        true)
		GameState.music_volume           = gs.get("music_volume",           GameState.music_volume)
		GameState.sfx_volume             = gs.get("sfx_volume",             GameState.sfx_volume)
		GameState.text_speed             = gs.get("text_speed",             GameState.text_speed)
		GameState.accessibility_mode     = gs.get("accessibility_mode",     GameState.accessibility_mode)

	if blob.has("missions"):
		MissionManager.from_dict(blob["missions"])


func _apply_inventory(inv_rows: Array, nft_rows: Array) -> void:
	InventoryManager.clear()

	for row in inv_rows:
		var item: Dictionary = row.get("metadata", {}).duplicate()
		# Ensure the canonical fields are always present (metadata may be partial).
		item["item_id"]  = row.get("item_id",  item.get("item_id", ""))
		item["name"]     = row.get("name",      item.get("name", ""))
		item["category"] = row.get("category",  item.get("category", "Quest Items"))
		item["rarity"]   = row.get("rarity",    item.get("rarity", "common"))
		item["quantity"] = row.get("quantity",  1)
		item["equipped"] = row.get("equipped",  false)
		InventoryManager.add_item(item)

	for row in nft_rows:
		var nft: Dictionary = row.get("metadata", {}).duplicate()
		nft["nft_id"]         = row.get("nft_id",         nft.get("nft_id", ""))
		nft["name"]           = row.get("name",           nft.get("name", ""))
		nft["rarity"]         = row.get("rarity",         nft.get("rarity", "common"))
		nft["discovered_from"]= row.get("discovered_from",nft.get("discovered_from", ""))
		nft["tradeable"]      = row.get("tradeable",      false)
		nft["token_value"]    = row.get("token_value",    0)
		nft["equipped"]       = row.get("equipped",       false)
		InventoryManager.add_nft(nft)


# ─────────────────────────────────────────────────────────────
# BUILD BLOB — snapshot non-economy state for upload
# ─────────────────────────────────────────────────────────────
func _build_blob() -> Dictionary:
	var gs_dict := GameState.to_dict()
	# Strip economy fields — those live in real tables.
	gs_dict.erase("vibe_tokens")
	gs_dict.erase("player_level")
	gs_dict.erase("player_xp")

	return {
		"game_state": gs_dict,
		"missions":   MissionManager.to_dict(),
		"avatar":     AvatarManager.to_dict(),
	}
