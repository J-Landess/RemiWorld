## SettingsScreen.gd
## =============================================================
## The Game Settings screen, accessible from the Main Menu.
##
## Settings:
##   - Music Volume (slider)
##   - Sound Effects Volume (slider)
##   - Text Speed (slow/normal/fast)
##   - Accessibility Mode (toggle)
##   - Back button
##
## Attached to: scenes/ui/SettingsScreen.tscn
## Node type: Control
## =============================================================
extends Control

# ─────────────────────────────────────────────────────────────
# NODE REFERENCES
# ─────────────────────────────────────────────────────────────
@onready var music_slider: HSlider      = $CenterContainer/VBoxContainer/MusicRow/MusicSlider
@onready var music_value_label: Label   = $CenterContainer/VBoxContainer/MusicRow/MusicValueLabel
@onready var sfx_slider: HSlider        = $CenterContainer/VBoxContainer/SFXRow/SFXSlider
@onready var sfx_value_label: Label     = $CenterContainer/VBoxContainer/SFXRow/SFXValueLabel
@onready var text_speed_group: HBoxContainer = $CenterContainer/VBoxContainer/TextSpeedRow
@onready var accessibility_toggle: CheckButton = $CenterContainer/VBoxContainer/AccessibilityRow/AccessibilityToggle
@onready var btn_back: Button           = $CenterContainer/VBoxContainer/BtnBack
@onready var save_status_label: Label   = $CenterContainer/VBoxContainer/SaveStatusLabel

# ─────────────────────────────────────────────────────────────
# TEXT SPEED OPTIONS
# ─────────────────────────────────────────────────────────────
const TEXT_SPEEDS: Dictionary = {
	"Slow":   0.08,
	"Normal": 0.05,
	"Fast":   0.02,
	"Instant": 0.0,
}

var _text_speed_buttons: Array = []

# ─────────────────────────────────────────────────────────────
# SCENE PATH
# ─────────────────────────────────────────────────────────────
const SCENE_MAIN_MENU := "res://scenes/main_menu/MainMenu.tscn"


# ─────────────────────────────────────────────────────────────
# CALLED WHEN SCENE LOADS
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	# Initialize sliders with current settings
	if music_slider:
		music_slider.min_value = 0.0
		music_slider.max_value = 1.0
		music_slider.step = 0.05
		music_slider.value = GameState.music_volume
		music_slider.value_changed.connect(_on_music_volume_changed)
		_update_volume_label(music_value_label, GameState.music_volume)

	if sfx_slider:
		sfx_slider.min_value = 0.0
		sfx_slider.max_value = 1.0
		sfx_slider.step = 0.05
		sfx_slider.value = GameState.sfx_volume
		sfx_slider.value_changed.connect(_on_sfx_volume_changed)
		_update_volume_label(sfx_value_label, GameState.sfx_volume)

	# Build text speed buttons
	_build_text_speed_buttons()

	# Accessibility toggle
	if accessibility_toggle:
		accessibility_toggle.button_pressed = GameState.accessibility_mode
		accessibility_toggle.toggled.connect(_on_accessibility_toggled)

	# Back button
	if btn_back:
		btn_back.pressed.connect(_on_back_pressed)

	if save_status_label:
		save_status_label.text = ""

	print("[SettingsScreen] Settings screen ready.")


# ─────────────────────────────────────────────────────────────
# TEXT SPEED BUTTON GROUP
# ─────────────────────────────────────────────────────────────
func _build_text_speed_buttons() -> void:
	if not text_speed_group:
		return

	# Clear existing
	for child in text_speed_group.get_children():
		if child is Button:
			child.queue_free()

	for speed_name in TEXT_SPEEDS:
		var btn := Button.new()
		btn.text = speed_name
		btn.toggle_mode = true

		# Mark current speed as selected
		if abs(TEXT_SPEEDS[speed_name] - GameState.text_speed) < 0.01:
			btn.button_pressed = true

		btn.toggled.connect(_on_text_speed_selected.bind(speed_name, btn))
		text_speed_group.add_child(btn)
		_text_speed_buttons.append(btn)


# ─────────────────────────────────────────────────────────────
# VALUE CHANGE HANDLERS
# ─────────────────────────────────────────────────────────────
func _on_music_volume_changed(value: float) -> void:
	GameState.music_volume = value
	_update_volume_label(music_value_label, value)
	# Future: AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))
	_show_saved()


func _on_sfx_volume_changed(value: float) -> void:
	GameState.sfx_volume = value
	_update_volume_label(sfx_value_label, value)
	_show_saved()


func _on_text_speed_selected(pressed: bool, speed_name: String, selected_btn: Button) -> void:
	if not pressed:
		return

	# Unpress all other text speed buttons
	for btn in _text_speed_buttons:
		if btn != selected_btn:
			btn.button_pressed = false

	GameState.text_speed = TEXT_SPEEDS[speed_name]
	_show_saved()


func _on_accessibility_toggled(pressed: bool) -> void:
	GameState.accessibility_mode = pressed
	_show_saved()


func _update_volume_label(label: Label, value: float) -> void:
	if label:
		label.text = "%d%%" % int(value * 100)


func _show_saved() -> void:
	if save_status_label:
		save_status_label.text = "✅ Settings saved!"
		# Fade the message out after a moment
		await get_tree().create_timer(2.0).timeout
		save_status_label.text = ""


# ─────────────────────────────────────────────────────────────
# BACK BUTTON
# ─────────────────────────────────────────────────────────────
func _on_back_pressed() -> void:
	# If we came from in-game, go back to the game
	# For now, always go back to main menu
	get_tree().change_scene_to_file(SCENE_MAIN_MENU)
