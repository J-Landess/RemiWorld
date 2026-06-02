## SoccerKickPanel.gd
## =============================================================
## "Goal Kicker" mini-game.
##
## Side-on soccer field rendered inside the panel:
##   1. Press SPACE to stop the oscillating POWER bar.
##   2. Press SPACE again to stop the oscillating AIM arrow.
##   3. The ball tweens toward the goal — the goalkeeper covers part
##      of the goalmouth.
##   4. Score 2 of 3 shots to win.
## =============================================================
extends Control

# ─────────────────────────────────────────────────────────────
# CONSTANTS
# ─────────────────────────────────────────────────────────────
const FIELD_SIZE: Vector2 = Vector2(420, 320)
const GOAL_WIDTH: float = 220.0          # Half-width 110 either side of centre
const KEEPER_HALF_WIDTH: float = 28.0    # Saves anything that passes within this distance
const POWER_SPEED: float = 1.4           # Cycles per second
const AIM_SPEED: float = 1.2

# ─────────────────────────────────────────────────────────────
# STATE
# ─────────────────────────────────────────────────────────────
enum State { READY, POWER, AIM, KICKING, RESULT, DONE }

@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var prompt_label: Label = $Panel/VBoxContainer/PromptLabel
@onready var field: Control = $Panel/VBoxContainer/FieldWrap/Field
@onready var power_bar: ProgressBar = $Panel/VBoxContainer/PowerBar
@onready var feedback_label: Label = $Panel/VBoxContainer/FeedbackLabel
@onready var score_label: Label = $Panel/VBoxContainer/ScoreLabel
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton

var _mission_data: Dictionary = {}
var _caller: Node = null
var _shots: int = 3
var _required_goals: int = 2
var _current_shot: int = 0
var _goals: int = 0

var _state: State = State.READY
var _power_t: float = 0.0       # Oscillator phase
var _aim_t: float = 0.0
var _locked_power: float = 0.0
var _locked_aim: float = 0.0
var _keeper_x: float = 0.0

# Field-local positions: ball at bottom-center, goal at top
var _ball_pos: Vector2 = Vector2.ZERO
var _ball_radius: float = 8.0


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	if field:
		field.draw.connect(_on_field_draw)
		field.gui_input.connect(_on_field_input)


# ─────────────────────────────────────────────────────────────
# ENTRY POINT
# ─────────────────────────────────────────────────────────────
func show_challenge(mission_data: Dictionary, caller: Node) -> void:
	_mission_data = mission_data
	_caller = caller

	var cfg: Dictionary = mission_data.get("challenge", {})
	_shots = int(cfg.get("shots", 3))
	_required_goals = int(cfg.get("required_goals", 2))
	_current_shot = 0
	_goals = 0

	if title_label:
		title_label.text = "⚽  %s" % mission_data.get("title", "Goal Kicker")
	if close_button:
		close_button.text = "Give Up"

	visible = true
	_start_shot()


# ─────────────────────────────────────────────────────────────
# SHOT FLOW
# ─────────────────────────────────────────────────────────────
func _start_shot() -> void:
	_current_shot += 1
	_state = State.READY
	_power_t = 0.0
	_aim_t = 0.0
	_locked_power = 0.0
	_locked_aim = 0.0
	_keeper_x = randf_range(-GOAL_WIDTH * 0.4, GOAL_WIDTH * 0.4)
	_ball_pos = Vector2(FIELD_SIZE.x * 0.5, FIELD_SIZE.y - 40.0)

	if power_bar:
		power_bar.value = 0.0
	if feedback_label:
		feedback_label.text = ""
	_update_score_label()
	if prompt_label:
		prompt_label.text = "Shot %d / %d  ·  Press SPACE to start the POWER meter." % [_current_shot, _shots]

	field.queue_redraw()
	# Auto-start the power meter after the brief prompt
	await get_tree().create_timer(0.6).timeout
	if _state == State.READY:
		_state = State.POWER
		AudioManager.play_sfx("whistle")
		if prompt_label:
			prompt_label.text = "Press SPACE to set POWER!"


# ─────────────────────────────────────────────────────────────
# OSCILLATORS — driven from _process
# ─────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if not visible:
		return
	match _state:
		State.POWER:
			_power_t += delta * POWER_SPEED
			var p: float = 0.5 + 0.5 * sin(_power_t * TAU - PI * 0.5)
			if power_bar:
				power_bar.value = p * 100.0
		State.AIM:
			_aim_t += delta * AIM_SPEED
		State.KICKING, State.RESULT, State.READY, State.DONE:
			pass
	field.queue_redraw()


# ─────────────────────────────────────────────────────────────
# INPUT
# ─────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if not visible:
		return
	if not (event is InputEventKey) or not event.pressed or event.is_echo():
		return
	if event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_on_close_pressed()
		return
	if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
		get_viewport().set_input_as_handled()
		_advance()


func _on_field_input(event: InputEvent) -> void:
	# Mouse click works the same as Space
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()


func _advance() -> void:
	match _state:
		State.POWER:
			var p_val: float = 0.5
			if power_bar:
				p_val = power_bar.value / 100.0
			_locked_power = p_val
			AudioManager.play_sfx("click")
			_state = State.AIM
			if prompt_label:
				prompt_label.text = "Press SPACE to set AIM!"
		State.AIM:
			# Aim oscillator yields a horizontal target offset
			_locked_aim = sin(_aim_t * TAU - PI * 0.5)
			AudioManager.play_sfx("kick")
			_state = State.KICKING
			if prompt_label:
				prompt_label.text = "Kicking..."
			_kick_ball()
		_:
			pass


# ─────────────────────────────────────────────────────────────
# THE KICK
# ─────────────────────────────────────────────────────────────
func _kick_ball() -> void:
	# Target X at the goal line, based on aim. Power affects how
	# high (further up the field) the ball reaches before slowing.
	var target_x: float = FIELD_SIZE.x * 0.5 + _locked_aim * (GOAL_WIDTH * 0.7)
	var target_y: float = 60.0   # Goal line

	# Low power means the shot stops short.
	if _locked_power < 0.35:
		target_y = FIELD_SIZE.y * (1.0 - _locked_power) - 20.0

	var tween := create_tween()
	tween.tween_property(self, "_ball_pos", Vector2(target_x, target_y), 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished

	_resolve_shot(target_x, target_y)


func _resolve_shot(target_x: float, target_y: float) -> void:
	var is_goal := true

	# 1. Power too low — didn't reach the goal
	if _locked_power < 0.35:
		is_goal = false

	# 2. Aim wide of the goal
	var goal_left: float = FIELD_SIZE.x * 0.5 - GOAL_WIDTH * 0.5
	var goal_right: float = FIELD_SIZE.x * 0.5 + GOAL_WIDTH * 0.5
	if target_x < goal_left or target_x > goal_right:
		is_goal = false

	# 3. Goalkeeper save
	var keeper_world_x: float = FIELD_SIZE.x * 0.5 + _keeper_x
	if abs(target_x - keeper_world_x) <= KEEPER_HALF_WIDTH and target_y < 100.0:
		is_goal = false

	_state = State.RESULT

	if is_goal:
		_goals += 1
		AudioManager.play_sfx("goal_cheer")
		if feedback_label:
			feedback_label.text = "🎉  GOAL!"
			feedback_label.modulate = Color(0.30, 1.0, 0.40)
	else:
		AudioManager.play_sfx("goal_miss")
		if feedback_label:
			feedback_label.text = "❌  Missed!"
			feedback_label.modulate = Color(1.0, 0.50, 0.50)

	_update_score_label()
	await get_tree().create_timer(1.5).timeout

	if _current_shot >= _shots:
		_finish_challenge()
	else:
		_start_shot()


func _update_score_label() -> void:
	if score_label:
		score_label.text = "Goals: %d / %d   ·   Need %d to win" % [_goals, _shots, _required_goals]


# ─────────────────────────────────────────────────────────────
# DRAW THE FIELD + BALL + KEEPER
# ─────────────────────────────────────────────────────────────
func _on_field_draw() -> void:
	if not field:
		return
	# Pitch
	field.draw_rect(Rect2(Vector2.ZERO, FIELD_SIZE), Color(0.32, 0.62, 0.32))
	# Stripes
	for i in 6:
		var stripe_y: float = i * 50.0
		var alpha := 0.15 if (i % 2 == 0) else 0.0
		if alpha > 0.0:
			field.draw_rect(Rect2(0, stripe_y, FIELD_SIZE.x, 50.0), Color(0.20, 0.50, 0.22, alpha))
	# Goal line
	var goal_left: float = FIELD_SIZE.x * 0.5 - GOAL_WIDTH * 0.5
	field.draw_line(Vector2(goal_left, 60), Vector2(goal_left + GOAL_WIDTH, 60), Color(0.95, 0.95, 0.95), 3.0)
	# Goal posts (just visual)
	field.draw_rect(Rect2(goal_left - 4, 40, 4, 22), Color(0.95, 0.95, 0.95))
	field.draw_rect(Rect2(goal_left + GOAL_WIDTH, 40, 4, 22), Color(0.95, 0.95, 0.95))
	field.draw_rect(Rect2(goal_left - 4, 36, GOAL_WIDTH + 8, 4), Color(0.95, 0.95, 0.95))

	# Keeper (yellow rectangle)
	var keeper_world_x: float = FIELD_SIZE.x * 0.5 + _keeper_x
	field.draw_rect(Rect2(keeper_world_x - KEEPER_HALF_WIDTH, 50, KEEPER_HALF_WIDTH * 2.0, 22), Color(0.96, 0.85, 0.30))
	# Keeper face dot
	field.draw_circle(Vector2(keeper_world_x, 56), 3.5, Color(0.30, 0.18, 0.12))

	# Aim arrow (only while aiming or as a preview)
	if _state == State.AIM or _state == State.POWER or _state == State.READY:
		var aim_val: float = sin(_aim_t * TAU - PI * 0.5) if _state == State.AIM else 0.0
		var arrow_end: Vector2 = Vector2(FIELD_SIZE.x * 0.5 + aim_val * (GOAL_WIDTH * 0.7), 80)
		field.draw_line(_ball_pos, arrow_end, Color(0.98, 0.85, 0.30, 0.85), 2.0)
		# Arrow head
		var head: Array = [
			arrow_end + Vector2(-6, 8),
			arrow_end + Vector2(6, 8),
			arrow_end,
		]
		field.draw_colored_polygon(PackedVector2Array(head), Color(0.98, 0.85, 0.30, 0.85))

	# Ball
	field.draw_circle(_ball_pos, _ball_radius, Color(0.98, 0.98, 0.98))
	field.draw_arc(_ball_pos, _ball_radius, 0, TAU, 16, Color(0.15, 0.15, 0.18), 1.2)
	field.draw_circle(_ball_pos + Vector2(-2, -1), 1.4, Color(0.15, 0.15, 0.18))
	field.draw_circle(_ball_pos + Vector2(3, 1), 1.4, Color(0.15, 0.15, 0.18))


# ─────────────────────────────────────────────────────────────
# FINISH
# ─────────────────────────────────────────────────────────────
func _finish_challenge() -> void:
	_state = State.DONE
	var success := _goals >= _required_goals
	visible = false
	if _caller and _caller.has_method("on_challenge_finished"):
		_caller.on_challenge_finished(success)
	var hud := get_parent()
	if hud and hud.has_method("close_all_panels"):
		hud.close_all_panels()


func _on_close_pressed() -> void:
	AudioManager.play_sfx("click")
	_finish_challenge()
