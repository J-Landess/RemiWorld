## WelcomeScreen.gd
## =============================================================
## The welcome screen shown after "Start New Game" is pressed.
## Shows a friendly welcome message and then lets the player
## enter the first playable area.
##
## Attached to: scenes/welcome/WelcomeScreen.tscn
## Node type: Control
## =============================================================
extends Control

# ─────────────────────────────────────────────────────────────
# NODE REFERENCES
# ─────────────────────────────────────────────────────────────
@onready var welcome_label: Label    = $CenterContainer/VBoxContainer/WelcomeLabel
@onready var subtitle_label: Label   = $CenterContainer/VBoxContainer/SubtitleLabel
@onready var player_name_field: LineEdit = $CenterContainer/VBoxContainer/NameContainer/PlayerNameField
@onready var btn_enter: Button       = $CenterContainer/VBoxContainer/BtnEnterWorld
@onready var btn_back: Button        = $CenterContainer/VBoxContainer/BtnBack
@onready var tip_label: Label        = $CenterContainer/VBoxContainer/TipLabel

# ─────────────────────────────────────────────────────────────
# SCENE PATHS
# ─────────────────────────────────────────────────────────────
const SCENE_MAIN_MENU := "res://scenes/main_menu/MainMenu.tscn"
const SCENE_START_AREA := "res://scenes/levels/v1_start_area/StartArea.tscn"

# ─────────────────────────────────────────────────────────────
# TIP MESSAGES — shown at the bottom of the welcome screen
# ─────────────────────────────────────────────────────────────
const TIPS: Array = [
	"💡 Tip: Press E to talk to characters you meet!",
	"💡 Tip: Press B to open your backpack!",
	"💡 Tip: Solve puzzles to earn VIBE tokens!",
	"💡 Tip: Visit the store to buy avatar items!",
	"💡 Tip: Press Esc to pause the game.",
]


# ─────────────────────────────────────────────────────────────
# CALLED WHEN THE SCENE LOADS
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	# Personalize the welcome message
	welcome_label.text = "Welcome to Remi's World! 🌟"
	subtitle_label.text = "A magical place where learning is an adventure!"

	# Pre-fill the name field with the current player name
	if player_name_field:
		player_name_field.text = GameState.player_name
		player_name_field.placeholder_text = "Enter your name..."
		player_name_field.max_length = 20

	# Show a random tip
	if tip_label:
		tip_label.text = TIPS[randi() % TIPS.size()]

	# Connect buttons
	btn_enter.pressed.connect(_on_enter_pressed)
	if btn_back:
		btn_back.pressed.connect(_on_back_pressed)

	# Animate the welcome screen fading in
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.8)

	print("[WelcomeScreen] Welcome screen ready!")


# ─────────────────────────────────────────────────────────────
# BUTTON HANDLERS
# ─────────────────────────────────────────────────────────────
func _on_enter_pressed() -> void:
	# Save the player's chosen name
	if player_name_field and not player_name_field.text.strip_edges().is_empty():
		GameState.player_name = player_name_field.text.strip_edges()

	print("[WelcomeScreen] Entering the world as: ", GameState.player_name)

	# Fade out, then switch to the start area
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	get_tree().change_scene_to_file(SCENE_START_AREA)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(SCENE_MAIN_MENU)
