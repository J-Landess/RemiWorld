## DaisyFetchPanel.gd
## =============================================================
## "Daisy's Fetch Game" mini-game.
##
## A top-down patch of grass with N stick buttons scattered across
## it. Click a stick — Daisy tweens to it, picks it up, tweens back
## to the player. Fetch all the sticks to win.
## =============================================================
extends Control

# ─────────────────────────────────────────────────────────────
# CONSTANTS
# ─────────────────────────────────────────────────────────────
const FIELD_SIZE: Vector2 = Vector2(420, 280)
const STICK_BUTTON_SIZE: Vector2 = Vector2(40, 40)
const DAISY_RUN_SPEED: float = 320.0   # pixels per second
const PLAYER_POS_OFFSET: Vector2 = Vector2(0, 30)   # Relative to player's bottom-centre slot
const DAISY_HOME_OFFSET: Vector2 = Vector2(60, 0)   # Daisy starts next to player

# ─────────────────────────────────────────────────────────────
# NODE REFERENCES
# ─────────────────────────────────────────────────────────────
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var prompt_label: Label = $Panel/VBoxContainer/PromptLabel
@onready var field: Control = $Panel/VBoxContainer/FieldWrap/Field
@onready var feedback_label: Label = $Panel/VBoxContainer/FeedbackLabel
@onready var score_label: Label = $Panel/VBoxContainer/ScoreLabel
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton

# ─────────────────────────────────────────────────────────────
# STATE
# ─────────────────────────────────────────────────────────────
var _mission_data: Dictionary = {}
var _caller: Node = null
var _stick_count: int = 3
var _required_fetches: int = 3
var _fetches_done: int = 0
var _player_pos: Vector2 = Vector2.ZERO
var _daisy_pos: Vector2 = Vector2.ZERO
var _daisy_home: Vector2 = Vector2.ZERO
var _is_busy: bool = false     # True while Daisy is fetching
var _stick_buttons: Array = [] # Currently visible stick Buttons


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	if field:
		field.draw.connect(_on_field_draw)
		field.resized.connect(_on_field_resized)


# ─────────────────────────────────────────────────────────────
# ENTRY POINT
# ─────────────────────────────────────────────────────────────
func show_challenge(mission_data: Dictionary, caller: Node) -> void:
	_mission_data = mission_data
	_caller = caller

	var cfg: Dictionary = mission_data.get("challenge", {})
	_stick_count = int(cfg.get("sticks", 3))
	_required_fetches = int(cfg.get("required_fetches", _stick_count))
	_fetches_done = 0
	_is_busy = false

	if title_label:
		title_label.text = "🐾  %s" % mission_data.get("title", "Daisy's Fetch Game")
	if close_button:
		close_button.text = "Give Up"
	if feedback_label:
		feedback_label.text = ""
	if prompt_label:
		prompt_label.text = "Click each stick to throw it for Daisy!"

	visible = true
	# Wait for the field to size itself
	await get_tree().process_frame
	_layout_positions()
	_spawn_sticks()
	_update_score_label()
	field.queue_redraw()


# ─────────────────────────────────────────────────────────────
# LAYOUT
# ─────────────────────────────────────────────────────────────
func _layout_positions() -> void:
	var size: Vector2 = field.size if field.size != Vector2.ZERO else FIELD_SIZE
	_player_pos = Vector2(size.x * 0.5, size.y - 24.0)
	_daisy_home = _player_pos + DAISY_HOME_OFFSET
	_daisy_pos = _daisy_home


func _on_field_resized() -> void:
	_layout_positions()
	field.queue_redraw()


# ─────────────────────────────────────────────────────────────
# SPAWN STICKS
# ─────────────────────────────────────────────────────────────
func _spawn_sticks() -> void:
	for b in _stick_buttons:
		if is_instance_valid(b):
			b.queue_free()
	_stick_buttons.clear()

	var size: Vector2 = field.size if field.size != Vector2.ZERO else FIELD_SIZE
	var margin := 28.0

	for i in _stick_count:
		var btn := Button.new()
		btn.text = "🦴"
		btn.custom_minimum_size = STICK_BUTTON_SIZE
		btn.add_theme_font_size_override("font_size", 26)
		btn.focus_mode = Control.FOCUS_NONE
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.78, 0.65, 0.40, 0.85)
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override("normal", style)
		var hover_style := style.duplicate()
		hover_style.bg_color = Color(0.95, 0.80, 0.50, 0.95)
		btn.add_theme_stylebox_override("hover", hover_style)

		# Place at random non-overlapping spot in the top half of the field
		var pos := Vector2(
			randf_range(margin, size.x - margin - STICK_BUTTON_SIZE.x),
			randf_range(margin, size.y * 0.55)
		)
		btn.position = pos
		btn.pressed.connect(_on_stick_pressed.bind(btn))
		field.add_child(btn)
		_stick_buttons.append(btn)


# ─────────────────────────────────────────────────────────────
# CLICK A STICK — Daisy runs, picks it up, returns
# ─────────────────────────────────────────────────────────────
func _on_stick_pressed(btn: Button) -> void:
	if _is_busy or not visible:
		return
	if not is_instance_valid(btn) or not btn.visible:
		return

	_is_busy = true
	btn.disabled = true
	AudioManager.play_sfx("click")

	var target_pos: Vector2 = btn.position + STICK_BUTTON_SIZE * 0.5
	# Run Daisy out to the stick
	await _move_daisy_to(target_pos)

	# Pick up: hide the stick + bark
	btn.visible = false
	AudioManager.play_sfx("bark", 0.1)
	if feedback_label:
		feedback_label.text = "🐾  Daisy got it!"
		feedback_label.modulate = Color(0.95, 0.85, 0.35)

	# Run back to player
	await _move_daisy_to(_daisy_home)

	_fetches_done += 1
	_update_score_label()

	if _fetches_done >= _required_fetches or _fetches_done >= _stick_count:
		await get_tree().create_timer(0.6).timeout
		_finish_challenge()
		return

	_is_busy = false


# ─────────────────────────────────────────────────────────────
# MOVE DAISY — tweens at a speed proportional to distance
# ─────────────────────────────────────────────────────────────
func _move_daisy_to(target: Vector2) -> void:
	var distance: float = _daisy_pos.distance_to(target)
	var duration: float = clamp(distance / DAISY_RUN_SPEED, 0.25, 1.5)
	AudioManager.play_sfx("dog_pant", 0.05)

	var tween := create_tween()
	tween.tween_property(self, "_daisy_pos", target, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Redraw the field continuously while tweening
	while tween.is_running():
		field.queue_redraw()
		await get_tree().process_frame
	field.queue_redraw()


func _update_score_label() -> void:
	if score_label:
		score_label.text = "Sticks fetched: %d / %d" % [_fetches_done, _stick_count]


# ─────────────────────────────────────────────────────────────
# DRAW THE GRASS + PLAYER + DAISY
# ─────────────────────────────────────────────────────────────
func _on_field_draw() -> void:
	if not field:
		return
	var size: Vector2 = field.size
	# Grass background
	field.draw_rect(Rect2(Vector2.ZERO, size), Color(0.36, 0.66, 0.32))
	# Lighter patches
	field.draw_circle(Vector2(size.x * 0.3, size.y * 0.4), 60.0, Color(0.44, 0.72, 0.38, 0.55))
	field.draw_circle(Vector2(size.x * 0.75, size.y * 0.6), 50.0, Color(0.42, 0.70, 0.36, 0.50))

	# Player icon (Remi)
	_draw_player_icon(_player_pos)
	# Daisy icon
	_draw_daisy_icon(_daisy_pos)


func _draw_player_icon(pos: Vector2) -> void:
	# Simple two-circle stick figure
	field.draw_circle(pos + Vector2(0, 4), 12.0, Color(0.30, 0.50, 0.80))
	field.draw_circle(pos + Vector2(0, -8), 7.0, Color(0.95, 0.82, 0.62))
	field.draw_string(ThemeDB.fallback_font, pos + Vector2(-14, -22), "You",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.9))


func _draw_daisy_icon(pos: Vector2) -> void:
	# Mini white dog using simple shapes
	var fur := Color(0.98, 0.98, 0.98)
	var ear := Color(0.90, 0.80, 0.70)
	var nose := Color(0.90, 0.55, 0.65)
	var eye := Color(0.12, 0.08, 0.08)
	var collar := Color(1.00, 0.45, 0.10)
	field.draw_circle(pos + Vector2(8, -4), 4.0, fur)        # Tail
	field.draw_rect(Rect2(pos + Vector2(-6, -8), Vector2(16, 10)), fur)   # Body
	field.draw_circle(pos + Vector2(-7, -6), 6.0, fur)       # Head
	field.draw_rect(Rect2(pos + Vector2(-11, -8), Vector2(5, 8)), ear)
	field.draw_circle(pos + Vector2(-9, -7), 1.4, eye)
	field.draw_circle(pos + Vector2(-12, -4), 1.6, nose)
	field.draw_rect(Rect2(pos + Vector2(-11, -10), Vector2(7, 2)), collar)
	# Legs
	field.draw_rect(Rect2(pos + Vector2(-5, 2), Vector2(3, 5)), fur)
	field.draw_rect(Rect2(pos + Vector2(0, 2), Vector2(3, 5)), fur)
	field.draw_rect(Rect2(pos + Vector2(5, 2), Vector2(3, 5)), fur)


# ─────────────────────────────────────────────────────────────
# FINISH
# ─────────────────────────────────────────────────────────────
func _finish_challenge() -> void:
	var success := _fetches_done >= _required_fetches
	visible = false
	if _caller and _caller.has_method("on_challenge_finished"):
		_caller.on_challenge_finished(success)
	var hud := get_parent()
	if hud and hud.has_method("close_all_panels"):
		hud.close_all_panels()


func _on_close_pressed() -> void:
	AudioManager.play_sfx("click")
	_finish_challenge()
