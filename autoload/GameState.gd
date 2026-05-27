## GameState.gd
## =============================================================
## This is the "brain" of the game. It stores everything about
## the current player's session: their name, XP, tokens, etc.
##
## Because this is an Autoload (singleton), you can access it
## from any script in the project like this:
##   GameState.player_name
##   GameState.vibe_tokens
##   GameState.add_xp(25)
## =============================================================
extends Node

# ─────────────────────────────────────────────────────────────
# SIGNALS — these broadcast events to any script that listens
# ─────────────────────────────────────────────────────────────
signal tokens_changed(new_amount: int)
signal xp_changed(new_xp: int, new_level: int)
signal player_name_changed(new_name: String)
signal game_state_ready()

# ─────────────────────────────────────────────────────────────
# CONSTANTS
# ─────────────────────────────────────────────────────────────
const GAME_VERSION: String = "0.1.0"
const XP_PER_LEVEL: int = 100  # How much XP needed to level up

# ─────────────────────────────────────────────────────────────
# PLAYER DATA — these are the values that get saved/loaded
# ─────────────────────────────────────────────────────────────
var player_name: String = "Remi"
var player_level: int = 1
var player_xp: int = 0
var vibe_tokens: int = 0     # In-game currency (like coins)
var current_scene: String = ""
var player_position: Vector2 = Vector2.ZERO

# Whether a game has been started (vs. first launch)
var has_active_game: bool = false

# ─────────────────────────────────────────────────────────────
# SETTINGS — these are the player's preferences
# ─────────────────────────────────────────────────────────────
var music_volume: float = 0.8   # 0.0 to 1.0
var sfx_volume: float = 1.0     # 0.0 to 1.0
var text_speed: float = 0.05    # Seconds per character in dialogue
var accessibility_mode: bool = false

# ─────────────────────────────────────────────────────────────
# CALLED WHEN THE GAME STARTS
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	# Set up our custom input actions so players can use
	# WASD, arrow keys, and special buttons for the game.
	_setup_input_actions()
	print("[GameState] Game State initialized. Version: ", GAME_VERSION)
	emit_signal("game_state_ready")


# ─────────────────────────────────────────────────────────────
# INPUT ACTIONS SETUP
# Register all keyboard shortcuts the game needs.
# ─────────────────────────────────────────────────────────────
func _setup_input_actions() -> void:
	# Helper: safely add an action with a key
	_add_key_action("move_up",    [KEY_W, KEY_UP])
	_add_key_action("move_down",  [KEY_S, KEY_DOWN])
	_add_key_action("move_left",  [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("interact",   [KEY_E])       # Talk to NPCs, examine objects
	_add_key_action("open_backpack", [KEY_B])    # Open the backpack/inventory
	_add_key_action("pause",      [KEY_ESCAPE])  # Pause / Settings


func _add_key_action(action_name: String, keys: Array) -> void:
	# Only create the action if it doesn't already exist in the project
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
		for key in keys:
			var event := InputEventKey.new()
			event.keycode = key
			InputMap.action_add_event(action_name, event)


# ─────────────────────────────────────────────────────────────
# TOKEN MANAGEMENT
# ─────────────────────────────────────────────────────────────
func add_tokens(amount: int) -> void:
	vibe_tokens += amount
	emit_signal("tokens_changed", vibe_tokens)
	print("[GameState] +%d VIBE Tokens. Total: %d" % [amount, vibe_tokens])


func spend_tokens(amount: int) -> bool:
	# Returns true if the purchase was successful, false if not enough tokens
	if vibe_tokens >= amount:
		vibe_tokens -= amount
		emit_signal("tokens_changed", vibe_tokens)
		print("[GameState] Spent %d VIBE. Remaining: %d" % [amount, vibe_tokens])
		return true
	else:
		print("[GameState] Not enough VIBE! Have: %d, Need: %d" % [vibe_tokens, amount])
		return false


# ─────────────────────────────────────────────────────────────
# XP AND LEVELING
# ─────────────────────────────────────────────────────────────
func add_xp(amount: int) -> void:
	player_xp += amount
	# Check if the player has earned enough XP to level up
	while player_xp >= XP_PER_LEVEL:
		player_xp -= XP_PER_LEVEL
		player_level += 1
		print("[GameState] LEVEL UP! Now Level %d" % player_level)
	emit_signal("xp_changed", player_xp, player_level)


func get_xp_progress() -> float:
	# Returns a value from 0.0 to 1.0 showing XP progress to next level
	return float(player_xp) / float(XP_PER_LEVEL)


# ─────────────────────────────────────────────────────────────
# GAME RESET (used when starting a new game)
# ─────────────────────────────────────────────────────────────
func reset_for_new_game(new_player_name: String = "Remi") -> void:
	player_name = new_player_name
	player_level = 1
	player_xp = 0
	vibe_tokens = 0
	current_scene = "res://scenes/levels/v1_start_area/StartArea.tscn"
	player_position = Vector2.ZERO
	has_active_game = true
	print("[GameState] New game started for: ", player_name)


# ─────────────────────────────────────────────────────────────
# SERIALIZATION — Convert state to/from a dictionary for saving
# ─────────────────────────────────────────────────────────────
func to_dict() -> Dictionary:
	return {
		"player_name": player_name,
		"player_level": player_level,
		"player_xp": player_xp,
		"vibe_tokens": vibe_tokens,
		"current_scene": current_scene,
		"player_position_x": player_position.x,
		"player_position_y": player_position.y,
		"has_active_game": has_active_game,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"text_speed": text_speed,
		"accessibility_mode": accessibility_mode,
		"game_version": GAME_VERSION,
	}


func from_dict(data: Dictionary) -> void:
	player_name = data.get("player_name", "Remi")
	player_level = data.get("player_level", 1)
	player_xp = data.get("player_xp", 0)
	vibe_tokens = data.get("vibe_tokens", 0)
	current_scene = data.get("current_scene", "")
	player_position = Vector2(
		data.get("player_position_x", 0.0),
		data.get("player_position_y", 0.0)
	)
	has_active_game = data.get("has_active_game", false)
	music_volume = data.get("music_volume", 0.8)
	sfx_volume = data.get("sfx_volume", 1.0)
	text_speed = data.get("text_speed", 0.05)
	accessibility_mode = data.get("accessibility_mode", false)
