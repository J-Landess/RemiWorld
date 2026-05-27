## MainMenu.gd
## =============================================================
## The first screen the player sees when they launch the game.
##
## Buttons:
##   - Start New Game → Welcome Screen → Start Area
##   - Load Game → loads save file → Start Area
##   - Game Settings → Settings screen
##   - Exit Game → closes the application
##
## Attached to: scenes/main_menu/MainMenu.tscn
## Node type: Control
## =============================================================
extends Control

# ─────────────────────────────────────────────────────────────
# NODE REFERENCES — matched to scene node names
# ─────────────────────────────────────────────────────────────
@onready var btn_new_game: Button  = $CenterContainer/VBoxContainer/BtnNewGame
@onready var btn_load_game: Button = $CenterContainer/VBoxContainer/BtnLoadGame
@onready var btn_settings: Button  = $CenterContainer/VBoxContainer/BtnSettings
@onready var btn_exit: Button      = $CenterContainer/VBoxContainer/BtnExit
@onready var version_label: Label  = $VersionLabel
@onready var save_info_label: Label = $CenterContainer/VBoxContainer/SaveInfoLabel

# ─────────────────────────────────────────────────────────────
# SCENE PATHS
# ─────────────────────────────────────────────────────────────
const SCENE_WELCOME  := "res://scenes/welcome/WelcomeScreen.tscn"
const SCENE_SETTINGS := "res://scenes/ui/SettingsScreen.tscn"
const SCENE_GAME     := "res://scenes/levels/v1_start_area/StartArea.tscn"


# ─────────────────────────────────────────────────────────────
# CALLED WHEN THE MENU LOADS
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	# Show the game version in the corner
	if version_label:
		version_label.text = "v" + GameState.GAME_VERSION

	# Check if a save file exists and update the Load button
	_update_load_button()

	# Connect button signals — when clicked, call the matching function
	btn_new_game.pressed.connect(_on_new_game_pressed)
	btn_load_game.pressed.connect(_on_load_game_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_exit.pressed.connect(_on_exit_pressed)

	print("[MainMenu] Main menu loaded.")


# ─────────────────────────────────────────────────────────────
# UPDATE LOAD BUTTON STATE
# ─────────────────────────────────────────────────────────────
func _update_load_button() -> void:
	var has_save := SaveManager.has_save_file()
	btn_load_game.disabled = not has_save

	if save_info_label:
		if has_save:
			var info := SaveManager.get_save_info()
			save_info_label.text = "Last save: %s (Lv.%d — %d VIBE)" % [
				info.get("player_name", "Remi"),
				info.get("player_level", 1),
				info.get("vibe_tokens", 0),
			]
			save_info_label.visible = true
		else:
			save_info_label.text = "No save file found."
			save_info_label.visible = true


# ─────────────────────────────────────────────────────────────
# BUTTON HANDLERS
# ─────────────────────────────────────────────────────────────
func _on_new_game_pressed() -> void:
	print("[MainMenu] Starting new game...")
	# Reset all managers for a fresh start
	GameState.reset_for_new_game("Remi")
	InventoryManager.clear()

	# Go to the Welcome Screen
	get_tree().change_scene_to_file(SCENE_WELCOME)


func _on_load_game_pressed() -> void:
	print("[MainMenu] Loading game...")
	var success := SaveManager.load_game()
	if success:
		# Load directly into the last scene the player was in
		var scene_to_load := GameState.current_scene
		if scene_to_load.is_empty() or not ResourceLoader.exists(scene_to_load):
			scene_to_load = SCENE_GAME
		get_tree().change_scene_to_file(scene_to_load)
	else:
		# Show a friendly error message
		if save_info_label:
			save_info_label.text = "Could not load save! Starting fresh..."
		await get_tree().create_timer(2.0).timeout
		_on_new_game_pressed()


func _on_settings_pressed() -> void:
	print("[MainMenu] Opening settings...")
	get_tree().change_scene_to_file(SCENE_SETTINGS)


func _on_exit_pressed() -> void:
	print("[MainMenu] Exiting game. Goodbye!")
	get_tree().quit()
