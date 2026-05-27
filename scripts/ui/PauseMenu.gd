## PauseMenu.gd
## =============================================================
## The pause menu shown when the player presses Escape.
##
## Options:
##   - Resume Game
##   - Open Backpack
##   - Open Avatar Closet
##   - Settings
##   - Save Game
##   - Return to Main Menu
##
## Attached to: scenes/ui/HUD.tscn → PauseMenu node
## Node type: Control
## =============================================================
extends Control

# ─────────────────────────────────────────────────────────────
# NODE REFERENCES
# ─────────────────────────────────────────────────────────────
@onready var btn_resume: Button    = $CenterContainer/VBoxContainer/BtnResume
@onready var btn_backpack: Button  = $CenterContainer/VBoxContainer/BtnBackpack
@onready var btn_closet: Button    = $CenterContainer/VBoxContainer/BtnCloset
@onready var btn_settings: Button  = $CenterContainer/VBoxContainer/BtnSettings
@onready var btn_save: Button      = $CenterContainer/VBoxContainer/BtnSave
@onready var btn_main_menu: Button = $CenterContainer/VBoxContainer/BtnMainMenu
@onready var save_label: Label     = $CenterContainer/VBoxContainer/SaveLabel

# ─────────────────────────────────────────────────────────────
# SCENE PATH
# ─────────────────────────────────────────────────────────────
const SCENE_SETTINGS  := "res://scenes/ui/SettingsScreen.tscn"
const SCENE_MAIN_MENU := "res://scenes/main_menu/MainMenu.tscn"


# ─────────────────────────────────────────────────────────────
# READY
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	visible = false

	if btn_resume:
		btn_resume.pressed.connect(_on_resume)
	if btn_backpack:
		btn_backpack.pressed.connect(_on_backpack)
	if btn_closet:
		btn_closet.pressed.connect(_on_closet)
	if btn_save:
		btn_save.pressed.connect(_on_save)
	if btn_main_menu:
		btn_main_menu.pressed.connect(_on_main_menu)

	if save_label:
		save_label.text = ""


# ─────────────────────────────────────────────────────────────
# BUTTON HANDLERS
# ─────────────────────────────────────────────────────────────
func _on_resume() -> void:
	var hud := get_parent()
	if hud and hud.has_method("close_all_panels"):
		hud.close_all_panels()
	visible = false


func _on_backpack() -> void:
	visible = false
	var hud := get_parent()
	if hud and hud.has_method("toggle_backpack"):
		hud.toggle_backpack()


func _on_closet() -> void:
	visible = false
	var hud := get_parent()
	if hud and hud.has_method("open_avatar_closet"):
		hud.open_avatar_closet()


func _on_save() -> void:
	var success := SaveManager.save_game()
	if save_label:
		save_label.text = "✅ Game saved!" if success else "❌ Save failed!"
		await get_tree().create_timer(2.0).timeout
		save_label.text = ""


func _on_main_menu() -> void:
	SaveManager.save_game()
	get_tree().paused = false
	get_tree().change_scene_to_file(SCENE_MAIN_MENU)
