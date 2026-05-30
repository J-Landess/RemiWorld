## WelcomeScreen.gd
## =============================================================
## Welcome screen shown after "Start New Game".
## Collects: player name, age, and sex (Boy / Girl).
## Two paths forward:
##   "Create My Avatar" → AvatarCreation scene (recommended)
##   "Enter World Now"  → Skip avatar, go straight to the level
## =============================================================
extends Control

@onready var welcome_label: Label        = $CenterContainer/VBoxContainer/WelcomeLabel
@onready var player_name_field: LineEdit = $CenterContainer/VBoxContainer/NameRow/PlayerNameField
@onready var age_field: LineEdit         = $CenterContainer/VBoxContainer/AgeRow/AgeField
@onready var btn_boy: Button             = $CenterContainer/VBoxContainer/SexRow/BtnBoy
@onready var btn_girl: Button            = $CenterContainer/VBoxContainer/SexRow/BtnGirl
@onready var btn_create_avatar: Button   = $CenterContainer/VBoxContainer/BtnCreateAvatar
@onready var btn_enter_direct: Button    = $CenterContainer/VBoxContainer/BtnEnterDirect
@onready var btn_back: Button            = $CenterContainer/VBoxContainer/BtnBack
@onready var tip_label: Label            = $CenterContainer/VBoxContainer/TipLabel

const SCENE_MAIN_MENU     := "res://scenes/main_menu/MainMenu.tscn"
const SCENE_AVATAR_CREATE := "res://scenes/avatar/AvatarCreation.tscn"
const SCENE_START_AREA    := "res://scenes/levels/v1_start_area/StartArea.tscn"

const TIPS: Array = [
	"💡 Press E to talk to characters you meet!",
	"💡 Press B to open your backpack!",
	"💡 Solve puzzles to earn VIBE tokens!",
	"💡 Visit the store to buy avatar items!",
	"💡 Press Esc to pause the game.",
]

var _selected_sex: String = ""


func _ready() -> void:
	welcome_label.text = "Welcome to Remi's World! 🌟"

	player_name_field.text = GameState.player_name
	player_name_field.placeholder_text = "Your name..."
	player_name_field.max_length = 20

	# Age field — numbers only, max 2 digits
	age_field.placeholder_text = "Your age..."
	age_field.max_length = 2
	# Only accept digit input
	age_field.text_changed.connect(_on_age_text_changed)

	if tip_label:
		tip_label.text = TIPS[randi() % TIPS.size()]

	btn_boy.pressed.connect(_on_boy_pressed)
	btn_girl.pressed.connect(_on_girl_pressed)
	btn_create_avatar.pressed.connect(_on_create_avatar_pressed)
	btn_enter_direct.pressed.connect(_on_enter_direct_pressed)
	btn_back.pressed.connect(_on_back_pressed)

	# Pre-select sex if already set
	if GameState.player_sex == "boy":
		_select_sex("boy")
	elif GameState.player_sex == "girl":
		_select_sex("girl")

	# Fade in
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.6)


# ─────────────────────────────────────────────────────────────
# AGE — only allow digit characters
# ─────────────────────────────────────────────────────────────
func _on_age_text_changed(new_text: String) -> void:
	var digits_only := ""
	for ch in new_text:
		if ch.is_valid_int():
			digits_only += ch
	if digits_only != new_text:
		age_field.text = digits_only
		age_field.caret_column = digits_only.length()


# ─────────────────────────────────────────────────────────────
# SEX SELECTION — Boy / Girl radio-button style
# ─────────────────────────────────────────────────────────────
func _on_boy_pressed() -> void:
	_select_sex("boy")

func _on_girl_pressed() -> void:
	_select_sex("girl")

func _select_sex(sex: String) -> void:
	_selected_sex = sex
	GameState.player_sex = sex
	# Highlight the selected button
	btn_boy.modulate  = Color(0.5, 0.8, 1.0) if sex == "boy"  else Color.WHITE
	btn_girl.modulate = Color(1.0, 0.7, 0.9) if sex == "girl" else Color.WHITE


# ─────────────────────────────────────────────────────────────
# SAVE FORM FIELDS TO GAMESTATE
# ─────────────────────────────────────────────────────────────
func _save_form() -> void:
	if not player_name_field.text.strip_edges().is_empty():
		GameState.player_name = player_name_field.text.strip_edges()
	if not age_field.text.is_empty():
		GameState.player_age = int(age_field.text)


# ─────────────────────────────────────────────────────────────
# BUTTON HANDLERS
# ─────────────────────────────────────────────────────────────
func _on_create_avatar_pressed() -> void:
	_save_form()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	await tween.finished
	get_tree().change_scene_to_file(SCENE_AVATAR_CREATE)


func _on_enter_direct_pressed() -> void:
	_save_form()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	await tween.finished
	get_tree().change_scene_to_file(SCENE_START_AREA)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(SCENE_MAIN_MENU)
