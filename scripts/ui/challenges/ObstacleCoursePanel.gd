## ObstacleCoursePanel.gd
## =============================================================
## Daisy's obedience obstacle course mini-game.
##
## Five obstacles appear in sequence. Press the prompted key
## within the time window to complete each one.
##
## Commands:
##   JUMP  (hurdle)  — W or UP arrow
##   SIT   (mat)     — S or DOWN arrow
##   SPIN  (barrel)  — A or LEFT arrow
##   BARK  (bell)    — SPACE
##   FETCH (ball)    — D or RIGHT arrow
##
## Need 3 out of 5 to pass.
## =============================================================
extends Control

# ─────────────────────────────────────────────────────────────
# CONSTANTS
# ─────────────────────────────────────────────────────────────
const ARENA_W: float = 480.0
const ARENA_H: float = 200.0
const FLOOR_Y: float = 155.0
const DAISY_X: float = 90.0
const OBS_X:   float = 370.0

const TIME_WINDOW: float = 1.8
const REQUIRED:    int   = 3

const C_FUR    := Color(1.00, 1.00, 1.00)
const C_EAR    := Color(0.90, 0.80, 0.70)
const C_NOSE   := Color(0.90, 0.55, 0.65)
const C_EYE    := Color(0.12, 0.08, 0.08)
const C_COLLAR := Color(1.00, 0.45, 0.10)

# ─────────────────────────────────────────────────────────────
# OBSTACLE DEFINITIONS
# Each entry: [name, prompt text, key codes, obstacle_type]
# ─────────────────────────────────────────────────────────────
const OBSTACLES := [
	{"name": "Hurdle",  "prompt": "JUMP!",  "keys": [KEY_W, KEY_UP],    "type": "hurdle"},
	{"name": "Sit Mat", "prompt": "SIT!",   "keys": [KEY_S, KEY_DOWN],  "type": "mat"},
	{"name": "Barrel",  "prompt": "SPIN!",  "keys": [KEY_A, KEY_LEFT],  "type": "barrel"},
	{"name": "Bell",    "prompt": "BARK!",  "keys": [KEY_SPACE],        "type": "bell"},
	{"name": "Ball",    "prompt": "FETCH!", "keys": [KEY_D, KEY_RIGHT],  "type": "ball"},
]

# ─────────────────────────────────────────────────────────────
# STATE
# ─────────────────────────────────────────────────────────────
enum CourseState { IDLE, WAITING, SUCCESS_FLASH, FAIL_FLASH, DONE }

var _state:          CourseState = CourseState.IDLE
var _current_obs:    int   = 0
var _score:          int   = 0
var _timer:          float = 0.0
var _flash_timer:    float = 0.0
var _last_success:   bool  = false
var _daisy_anim:     String = "idle"   # idle | jump | sit | spin | bark | fetch
var _daisy_y_off:    float = 0.0
var _mission_data:   Dictionary = {}
var _caller:         Node = null

# ─────────────────────────────────────────────────────────────
# NODE REFERENCES
# ─────────────────────────────────────────────────────────────
@onready var title_label:   Label       = $Panel/VBoxContainer/TitleLabel
@onready var arena:         Control     = $Panel/VBoxContainer/ArenaWrap/Arena
@onready var prompt_label:  Label       = $Panel/VBoxContainer/PromptLabel
@onready var timer_bar:     ProgressBar = $Panel/VBoxContainer/TimerBar
@onready var score_label:   Label       = $Panel/VBoxContainer/ScoreLabel
@onready var status_label:  Label       = $Panel/VBoxContainer/StatusLabel
@onready var close_button:  Button      = $Panel/VBoxContainer/CloseButton


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	if arena:
		arena.draw.connect(_on_arena_draw)


# ─────────────────────────────────────────────────────────────
# ENTRY POINT
# ─────────────────────────────────────────────────────────────
func show_challenge(mission_data: Dictionary, caller: Node) -> void:
	_mission_data = mission_data
	_caller       = caller
	_current_obs  = 0
	_score        = 0
	_daisy_anim   = "idle"
	_daisy_y_off  = 0.0

	if title_label:
		title_label.text = "🏋️  %s" % mission_data.get("title", "Obedience Course")
	visible = true
	_run_next_obstacle()


# ─────────────────────────────────────────────────────────────
# OBSTACLE FLOW
# ─────────────────────────────────────────────────────────────
func _run_next_obstacle() -> void:
	if _current_obs >= OBSTACLES.size():
		_finish()
		return

	var obs: Dictionary = OBSTACLES[_current_obs]
	_timer        = TIME_WINDOW
	_state        = CourseState.WAITING
	_daisy_anim   = "idle"
	_daisy_y_off  = 0.0

	if prompt_label:
		prompt_label.text = obs.prompt
		prompt_label.modulate = Color(1, 1, 0.4, 1)
	if timer_bar:
		timer_bar.max_value = TIME_WINDOW
		timer_bar.value     = TIME_WINDOW
	_update_score_label()
	arena.queue_redraw()


func _on_correct_input() -> void:
	_state       = CourseState.SUCCESS_FLASH
	_flash_timer = 0.5
	_score       += 1
	_last_success = true
	_daisy_anim   = OBSTACLES[_current_obs].type
	AudioManager.play_sfx("correct")
	if status_label:
		status_label.text = "✅ Good " + OBSTACLES[_current_obs].name + "!"
	if prompt_label:
		prompt_label.modulate = Color(0.4, 1, 0.4, 1)
	_update_score_label()


func _on_timeout_or_wrong() -> void:
	_state        = CourseState.FAIL_FLASH
	_flash_timer  = 0.5
	_last_success = false
	AudioManager.play_sfx("wrong", 0.05)
	if status_label:
		status_label.text = "❌ Missed the " + OBSTACLES[_current_obs].name + "!"
	if prompt_label:
		prompt_label.modulate = Color(1, 0.4, 0.4, 1)
	_update_score_label()


func _finish() -> void:
	_state = CourseState.DONE
	var success := _score >= REQUIRED
	AudioManager.play_sfx("goal_cheer" if success else "goal_miss")
	if status_label:
		status_label.text = "Course done! %d / %d  — %s" % [
			_score, OBSTACLES.size(),
			"Great job!" if success else "Keep practising!"
		]
	if prompt_label:
		prompt_label.text = ""

	await get_tree().create_timer(2.0).timeout
	visible = false
	if _caller and _caller.has_method("on_challenge_finished"):
		_caller.on_challenge_finished(success)
	var hud := get_parent()
	if hud and hud.has_method("close_all_panels"):
		hud.close_all_panels()


func _update_score_label() -> void:
	if score_label:
		var dots := ""
		for i in OBSTACLES.size():
			if i < _current_obs:
				dots += "✅ " if i < _score + (0 if _last_success else 1) else "❌ "
			elif i == _current_obs:
				dots += "▶ "
			else:
				dots += "○ "
		score_label.text = dots.strip_edges()


# ─────────────────────────────────────────────────────────────
# PROCESS
# ─────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if not visible:
		return

	match _state:
		CourseState.WAITING:
			_timer -= delta
			if timer_bar:
				timer_bar.value = _timer
			# Jump animation physics
			if _daisy_y_off > 0.0:
				_daisy_y_off -= 200.0 * delta
				_daisy_y_off = maxf(_daisy_y_off, 0.0)
			if _timer <= 0.0:
				_on_timeout_or_wrong()
			arena.queue_redraw()

		CourseState.SUCCESS_FLASH, CourseState.FAIL_FLASH:
			_flash_timer -= delta
			if _flash_timer <= 0.0:
				_current_obs += 1
				_run_next_obstacle()
			arena.queue_redraw()


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

	if _state != CourseState.WAITING:
		return

	var obs: Dictionary = OBSTACLES[_current_obs]
	if event.keycode in obs.keys:
		get_viewport().set_input_as_handled()
		if obs.type == "hurdle":
			_daisy_y_off = 38.0
		_on_correct_input()
	elif _key_is_any_course_key(event.keycode):
		# Pressed the wrong key
		get_viewport().set_input_as_handled()
		_on_timeout_or_wrong()


func _key_is_any_course_key(kc: int) -> bool:
	for obs: Dictionary in OBSTACLES:
		if kc in obs.keys:
			return true
	return false


# ─────────────────────────────────────────────────────────────
# DRAW
# ─────────────────────────────────────────────────────────────
func _on_arena_draw() -> void:
	if not arena:
		return

	# Sky
	arena.draw_rect(Rect2(0, 0, ARENA_W, ARENA_H), Color(0.55, 0.75, 0.95))
	# Grass
	arena.draw_rect(Rect2(0, FLOOR_Y, ARENA_W, ARENA_H - FLOOR_Y), Color(0.30, 0.62, 0.30))
	# Ground stripe
	arena.draw_rect(Rect2(0, FLOOR_Y, ARENA_W, 4), Color(0.25, 0.52, 0.20))
	# Dashed track
	for i in 8:
		var lx: float = 40.0 + i * 52.0
		arena.draw_rect(Rect2(lx, FLOOR_Y - 2, 30, 3), Color(1, 1, 1, 0.35))

	# Progress pips
	for i in OBSTACLES.size():
		var px: float = 40.0 + i * 96.0
		var pc := Color(0.9, 0.9, 0.9, 0.45)
		if i < _current_obs:
			pc = Color(0.3, 0.9, 0.3)
		elif i == _current_obs:
			pc = Color(1.0, 0.9, 0.2)
		arena.draw_circle(Vector2(px, 20), 8.0, pc)

	# Obstacle
	if _current_obs < OBSTACLES.size():
		var obs_type: String = OBSTACLES[_current_obs].type
		var flash_ok := _state == CourseState.SUCCESS_FLASH
		var flash_fail := _state == CourseState.FAIL_FLASH
		_draw_obstacle(obs_type, OBS_X, FLOOR_Y, flash_ok, flash_fail)

	# Daisy
	_draw_daisy_course()


func _draw_obstacle(obs_type: String, x: float, y: float, ok: bool, fail: bool) -> void:
	var accent := Color(0.82, 0.18, 0.12)
	if ok:
		accent = Color(0.2, 0.85, 0.2)
	elif fail:
		accent = Color(0.9, 0.3, 0.3)

	match obs_type:
		"hurdle":
			arena.draw_rect(Rect2(x - 4, y - 46, 8, 46), Color(0.70, 0.45, 0.22))
			arena.draw_rect(Rect2(x + 28, y - 46, 8, 46), Color(0.70, 0.45, 0.22))
			arena.draw_rect(Rect2(x - 4, y - 46, 40, 9), accent)
		"mat":
			arena.draw_rect(Rect2(x - 24, y - 8, 52, 12), Color(0.88, 0.68, 0.35))
			arena.draw_rect(Rect2(x - 22, y - 6, 48, 8),  accent)
			arena.draw_circle(Vector2(x + 2, y - 2), 4.0, Color(1, 1, 1, 0.6))
		"barrel":
			arena.draw_rect(Rect2(x - 18, y - 36, 40, 36), Color(0.62, 0.38, 0.20))
			for br_y: float in [y - 28.0, y - 14.0]:
				arena.draw_rect(Rect2(x - 20, br_y, 44, 4), accent)
		"bell":
			arena.draw_rect(Rect2(x - 4, y - 52, 8, 52), Color(0.62, 0.48, 0.25))
			arena.draw_circle(Vector2(x, y - 52), 14.0, Color(0.88, 0.78, 0.28))
			arena.draw_circle(Vector2(x, y - 52), 11.0, accent)
			arena.draw_circle(Vector2(x, y - 45), 4.5,  Color(0.68, 0.55, 0.18))
		"ball":
			arena.draw_circle(Vector2(x, y - 14), 14.0, accent)
			arena.draw_circle(Vector2(x - 4, y - 18), 4.0, Color(1, 1, 1, 0.35))


func _draw_daisy_course() -> void:
	var x := DAISY_X
	var y := FLOOR_Y - _daisy_y_off
	var c := C_FUR

	# Flash colors
	if _state == CourseState.SUCCESS_FLASH:
		c = Color(0.6, 1.0, 0.6)
	elif _state == CourseState.FAIL_FLASH:
		c = Color(1.0, 0.6, 0.6)

	# Shadow
	var shadow_r := maxf(14.0 - _daisy_y_off * 0.25, 4.0)
	arena.draw_circle(Vector2(x, FLOOR_Y + 4), shadow_r, Color(0, 0, 0, 0.2))

	match _daisy_anim:
		"sit":
			_draw_daisy_sit(x, y, c)
		"spin":
			_draw_daisy_spin(x, y, c)
		"fetch":
			_draw_daisy_fetch(x, y, c)
		"bark":
			_draw_daisy_bark(x, y, c)
		_:
			_draw_daisy_run(x, y, c)


func _draw_daisy_run(x: float, y: float, c: Color) -> void:
	arena.draw_circle(Vector2(x - 14, y - 8), 5.0, c)
	arena.draw_rect(Rect2(x - 12, y - 11, 26, 13), c)
	arena.draw_circle(Vector2(x + 12, y - 9), 10.0, c)
	arena.draw_rect(Rect2(x + 9, y - 16, 9, 12), C_EAR)
	arena.draw_circle(Vector2(x + 17, y - 11), 2.2, C_EYE)
	arena.draw_circle(Vector2(x + 21, y - 6),  2.8, C_NOSE)
	arena.draw_rect(Rect2(x - 10, y + 2, 5, 9), c)
	arena.draw_rect(Rect2(x - 3,  y + 2, 5, 9), c)
	arena.draw_rect(Rect2(x + 5,  y + 2, 5, 9), c)
	arena.draw_rect(Rect2(x + 12, y + 2, 4, 7), c)
	arena.draw_rect(Rect2(x + 3, y - 15, 14, 4), C_COLLAR)


func _draw_daisy_sit(x: float, y: float, c: Color) -> void:
	# Haunches on ground
	arena.draw_rect(Rect2(x - 12, y - 4, 24, 10), c)
	# Upright body (shorter)
	arena.draw_rect(Rect2(x - 8, y - 22, 16, 20), c)
	# Head
	arena.draw_circle(Vector2(x + 10, y - 28), 9.0, c)
	arena.draw_rect(Rect2(x + 7, y - 34, 8, 10), C_EAR)
	arena.draw_circle(Vector2(x + 15, y - 29), 2.0, C_EYE)
	arena.draw_circle(Vector2(x + 18, y - 25), 2.5, C_NOSE)
	arena.draw_rect(Rect2(x + 2, y - 22, 12, 4), C_COLLAR)
	# Front paws resting
	arena.draw_rect(Rect2(x - 12, y - 2, 8, 6), c)
	arena.draw_rect(Rect2(x + 6,  y - 2, 8, 6), c)


func _draw_daisy_spin(x: float, y: float, c: Color) -> void:
	# Draw a tilted/spinning Daisy
	arena.draw_colored_polygon(PackedVector2Array([
		Vector2(x - 16, y - 4),
		Vector2(x + 16, y - 10),
		Vector2(x + 16, y + 2),
		Vector2(x - 16, y + 4),
	]), c)
	# Spinning effect arcs
	arena.draw_arc(Vector2(x, y - 8), 22.0, 0, TAU * 0.75, 16, Color(1, 1, 1, 0.45), 2.5)
	arena.draw_circle(Vector2(x + 14, y - 8), 9.0, c)
	arena.draw_circle(Vector2(x + 14, y - 9), 2.0, C_EYE)


func _draw_daisy_bark(x: float, y: float, c: Color) -> void:
	arena.draw_circle(Vector2(x - 14, y - 8), 5.0, c)
	arena.draw_rect(Rect2(x - 12, y - 11, 26, 13), c)
	arena.draw_circle(Vector2(x + 12, y - 9), 10.0, c)
	arena.draw_rect(Rect2(x + 9, y - 16, 9, 12), C_EAR)
	arena.draw_circle(Vector2(x + 17, y - 11), 2.2, C_EYE)
	# Open mouth
	arena.draw_arc(Vector2(x + 22, y - 5), 5.0, -0.4, 0.4, 6, Color(0.8, 0.2, 0.2), 2.5)
	# Sound waves
	for wave in [12.0, 19.0, 26.0]:
		arena.draw_arc(Vector2(x + 26, y - 7), wave, -0.6, 0.6, 8, Color(1, 0.85, 0.3, 0.5), 1.5)
	arena.draw_rect(Rect2(x - 10, y + 2, 5, 9), c)
	arena.draw_rect(Rect2(x + 3, y - 15, 14, 4), C_COLLAR)


func _draw_daisy_fetch(x: float, y: float, c: Color) -> void:
	var lunge := 18.0
	arena.draw_colored_polygon(PackedVector2Array([
		Vector2(x - 12,          y - 4),
		Vector2(x + 14 + lunge,  y - 12),
		Vector2(x + 14 + lunge,  y + 1),
		Vector2(x - 12,          y + 5),
	]), c)
	arena.draw_circle(Vector2(x + 14 + lunge, y - 9), 10.0, c)
	arena.draw_circle(Vector2(x + 14 + lunge + 14, y - 9), 6.0, Color(0.85, 0.22, 0.22))
	arena.draw_rect(Rect2(x + 10 + lunge, y - 16, 9, 12), C_EAR)
	arena.draw_circle(Vector2(x + 17 + lunge, y - 11), 2.2, C_EYE)
	arena.draw_rect(Rect2(x - 10, y + 2, 5, 9), c)
	arena.draw_rect(Rect2(x + 5 + lunge * 0.4, y - 15, 12, 4), C_COLLAR)


func _on_close_pressed() -> void:
	AudioManager.play_sfx("click")
	visible = false
	if _caller and _caller.has_method("on_challenge_finished"):
		_caller.on_challenge_finished(false)
	var hud := get_parent()
	if hud and hud.has_method("close_all_panels"):
		hud.close_all_panels()
