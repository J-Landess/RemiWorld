## SaveManager.gd
## =============================================================
## Handles saving and loading the game to/from a local JSON file.
##
## The save file lives at: user://remiworld_save.json
## On Mac: ~/Library/Application Support/Godot/app_userdata/Remi's World/
## On Windows: %APPDATA%/Godot/app_userdata/Remi's World/
##
## Usage from any script:
##   SaveManager.save_game()
##   SaveManager.load_game()
##   SaveManager.has_save_file()
## =============================================================
extends Node

# ─────────────────────────────────────────────────────────────
# SIGNALS
# ─────────────────────────────────────────────────────────────
signal game_saved()
signal game_loaded()
signal save_failed(reason: String)
signal load_failed(reason: String)

# ─────────────────────────────────────────────────────────────
# CONSTANTS
# ─────────────────────────────────────────────────────────────
const SAVE_FILE_PATH: String = "user://remiworld_save.json"
const SAVE_VERSION: int = 1  # Increment this if save format changes


# ─────────────────────────────────────────────────────────────
# CHECK IF A SAVE FILE EXISTS
# ─────────────────────────────────────────────────────────────
func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)


# ─────────────────────────────────────────────────────────────
# SAVE GAME
# Gathers data from all managers and writes it to a JSON file.
# ─────────────────────────────────────────────────────────────
func save_game() -> bool:
	print("[SaveManager] Saving game...")

	# Build the save data dictionary by asking each manager for its data
	var save_data: Dictionary = {
		"save_version": SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(),
		"game_state": GameState.to_dict(),
		"inventory": InventoryManager.to_dict(),
		"missions": MissionManager.to_dict(),
		"avatar": AvatarManager.to_dict(),
	}

	# Convert the dictionary to a JSON string
	var json_string: String = JSON.stringify(save_data, "\t")  # "\t" makes it human-readable

	# Open (or create) the save file and write to it
	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file == null:
		var error_msg := "Could not open save file for writing."
		push_error("[SaveManager] " + error_msg)
		emit_signal("save_failed", error_msg)
		return false

	file.store_string(json_string)
	file.close()

	print("[SaveManager] Game saved successfully!")
	emit_signal("game_saved")
	return true


# ─────────────────────────────────────────────────────────────
# LOAD GAME
# Reads the JSON file and restores all manager states.
# ─────────────────────────────────────────────────────────────
func load_game() -> bool:
	print("[SaveManager] Loading game...")

	if not has_save_file():
		var error_msg := "No save file found."
		print("[SaveManager] " + error_msg)
		emit_signal("load_failed", error_msg)
		return false

	# Open and read the save file
	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file == null:
		var error_msg := "Could not open save file for reading."
		push_error("[SaveManager] " + error_msg)
		emit_signal("load_failed", error_msg)
		return false

	var json_string: String = file.get_as_text()
	file.close()

	# Parse the JSON string back into a dictionary
	var json := JSON.new()
	var parse_result := json.parse(json_string)
	if parse_result != OK:
		var error_msg := "Save file is corrupted or invalid."
		push_error("[SaveManager] " + error_msg)
		emit_signal("load_failed", error_msg)
		return false

	var save_data: Dictionary = json.get_data()

	# Restore each manager's state from the saved data
	if save_data.has("game_state"):
		GameState.from_dict(save_data["game_state"])
	if save_data.has("inventory"):
		InventoryManager.from_dict(save_data["inventory"])
	if save_data.has("missions"):
		MissionManager.from_dict(save_data["missions"])
	if save_data.has("avatar"):
		AvatarManager.from_dict(save_data["avatar"])

	print("[SaveManager] Game loaded successfully!")
	emit_signal("game_loaded")
	return true


# ─────────────────────────────────────────────────────────────
# DELETE SAVE (used for "Start New Game" or testing)
# ─────────────────────────────────────────────────────────────
func delete_save() -> void:
	if has_save_file():
		DirAccess.remove_absolute(SAVE_FILE_PATH)
		print("[SaveManager] Save file deleted.")


# ─────────────────────────────────────────────────────────────
# GET SAVE INFO (used to show "Last saved: ...")
# ─────────────────────────────────────────────────────────────
func get_save_info() -> Dictionary:
	if not has_save_file():
		return {}

	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file == null:
		return {}

	var json_string: String = file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(json_string) != OK:
		return {}

	var data: Dictionary = json.get_data()
	return {
		"timestamp": data.get("timestamp", "Unknown"),
		"player_name": data.get("game_state", {}).get("player_name", "Remi"),
		"player_level": data.get("game_state", {}).get("player_level", 1),
		"vibe_tokens": data.get("game_state", {}).get("vibe_tokens", 0),
	}
