## RoadSkateRunner.gd — side-view roller skate run (Excitebike-style).
class_name RoadSkateRunner
extends Control

signal section_cleared(section_index: int)
signal reached_zia
signal stumble_hit
signal air_trick

const PLAYER_X: float = 200.0
const GROUND_Y: float = 500.0
const LANE_GAP: float = 52.0
const GRAVITY: float = 1400.0
const JUMP_VEL: float = -480.0
const BASE_SPEED: float = 240.0
const STUMBLE_MULT: float = 0.3
const STUMBLE_TIME: float = 1.3
const TIME_PENALTY: float = 5.0
const TRICK_TIME_BONUS: float = 1.0

const SECTIONS: Array = [
	{"name": "Fallen Oak", "length": 1600.0, "gap": 420.0},
	{"name": "River Crossing", "length": 1600.0, "gap": 380.0},
	{"name": "Traveler's Hill", "length": 1600.0, "gap": 340.0},
	{"name": "Sassy Kid Alley", "length": 1600.0, "gap": 310.0},
	{"name": "Storm Stretch", "length": 1600.0, "gap": 280.0},
]
const FINISH_PAD: float = 350.0

const C_SKY_TOP := Color(0.55, 0.78, 0.95)
const C_SKY_BOT := Color(0.82, 0.90, 0.98)
const C_ROAD := Color(0.42, 0.40, 0.36)
const C_LINE := Color(0.95, 0.88, 0.45, 0.55)
const C_PLAYER := Color(0.95, 0.45, 0.65)
const C_WHEEL := Color(0.25, 0.25, 0.28)

var distance: float = 0.0
var total_length: float = 0.0
var speed: float = BASE_SPEED
var lane: int = 0
var jump_y: float = 0.0
var vel_y: float = 0.0
var on_ground: bool = true
var stumble_timer: float = 0.0
var invuln_timer: float = 0.0
var trick_spin: float = 0.0
var trick_done: bool = false
var section_idx: int = 0
var _section_banner: String = ""
var _banner_timer: float = 0.0
var _finished: bool = false
var _active: bool = false
var _roll_timer: float = 0.0

# {world_x, lane, kind, w, h} — world_x is distance along the road
var _obstacles: Array = []
var _next_spawn_at: float = 500.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for s: Dictionary in SECTIONS:
		total_length += s.length
	total_length += FINISH_PAD
	# Resume mid-run saves
	section_idx = mini(GameState.road_milestone, SECTIONS.size())
	for i in section_idx:
		distance += SECTIONS[i].length
	_next_spawn_at = distance + 480.0
	_spawn_obstacles_for_section()
	_active = true
	_show_banner(SECTIONS[mini(section_idx, SECTIONS.size() - 1)].name)


func _show_banner(text: String) -> void:
	_section_banner = text
	_banner_timer = 2.4


func _lane_y(which: int) -> float:
	return GROUND_Y - float(which) * LANE_GAP


func _player_y() -> float:
	return _lane_y(lane) + jump_y


func _process(delta: float) -> void:
	if not _active or _finished:
		return
	queue_redraw()

	if _banner_timer > 0.0:
		_banner_timer -= delta

	if stumble_timer > 0.0:
		stumble_timer -= delta
		speed = BASE_SPEED * STUMBLE_MULT
	else:
		speed = BASE_SPEED

	if invuln_timer > 0.0:
		invuln_timer -= delta

	_handle_input()
	_update_jump(delta)
	distance += speed * delta
	_tick_roll_sfx(delta)
	_try_spawn_obstacles()
	_check_section_crossing()
	_check_collisions()

	if trick_spin > 0.0:
		trick_spin = move_toward(trick_spin, 0.0, 8.0 * delta)

	if distance >= total_length:
		_finish_run()


func _handle_input() -> void:
	if stumble_timer > 0.0:
		return

	if on_ground:
		if Input.is_action_just_pressed("move_up"):
			lane = 1
		if Input.is_action_just_pressed("move_down"):
			lane = 0
		if Input.is_action_just_pressed("jump"):
			vel_y = JUMP_VEL
			on_ground = false
			trick_done = false
			AudioManager.play_sfx("kick", 0.05)
	else:
		if not trick_done and (Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right")):
			_do_air_trick()


func _do_air_trick() -> void:
	trick_done = true
	trick_spin = 1.0
	AudioManager.play_sfx("correct", 0.12)
	emit_signal("air_trick")


func _update_jump(delta: float) -> void:
	if on_ground:
		jump_y = 0.0
		vel_y = 0.0
		return
	vel_y += GRAVITY * delta
	jump_y += vel_y * delta
	if jump_y >= 0.0:
		jump_y = 0.0
		vel_y = 0.0
		on_ground = true


func _tick_roll_sfx(delta: float) -> void:
	if stumble_timer > 0.0:
		return
	_roll_timer -= delta
	if _roll_timer <= 0.0:
		AudioManager.play_sfx("step", 0.08)
		_roll_timer = 0.28


func _try_spawn_obstacles() -> void:
	if section_idx >= SECTIONS.size():
		return
	var sec: Dictionary = SECTIONS[section_idx]
	while _next_spawn_at < distance + 900.0 and _next_spawn_at < _section_end_x():
		_spawn_obstacle(_next_spawn_at, sec)
		_next_spawn_at += sec.gap + _rng.randf_range(-60.0, 90.0)


func _section_end_x() -> float:
	var end := 0.0
	for i in range(section_idx + 1):
		end += SECTIONS[i].length
	return end


func _spawn_obstacles_for_section() -> void:
	pass


func _spawn_obstacle(at_x: float, _sec: Dictionary) -> void:
	var kinds := ["log", "puddle", "cone", "branch"]
	var kind: String = kinds[_rng.randi_range(0, kinds.size() - 1)]
	var obs_lane := _rng.randi_range(0, 1)
	var w := 36.0
	var h := 28.0
	match kind:
		"log":
			obs_lane = 0
			w = 48.0
			h = 22.0
		"puddle":
			obs_lane = 0
			w = 40.0
			h = 12.0
		"branch":
			obs_lane = 1
			w = 44.0
			h = 18.0
		"cone":
			w = 26.0
			h = 32.0
	_obstacles.append({"x": at_x, "lane": obs_lane, "kind": kind, "w": w, "h": h})


func _screen_x(world_x: float) -> float:
	return world_x - distance + PLAYER_X


func _check_collisions() -> void:
	if invuln_timer > 0.0:
		return
	var py := _player_y()
	var pw := 34.0
	var ph := 46.0
	for obs: Dictionary in _obstacles:
		var sx := _screen_x(obs.x)
		if sx < PLAYER_X - 60.0 or sx > PLAYER_X + 60.0:
			continue
		if obs.lane != lane:
			continue
		# Jump clears low obstacles
		if not on_ground and jump_y < -22.0 and obs.kind in ["log", "puddle", "cone"]:
			continue
		var ox: float = sx - obs.w * 0.5
		var oy: float = _lane_y(obs.lane) - obs.h
		if Rect2(PLAYER_X - pw * 0.5, py - ph, pw, ph).intersects(Rect2(ox, oy, obs.w, obs.h)):
			_stumble()
			return


func _stumble() -> void:
	stumble_timer = STUMBLE_TIME
	invuln_timer = STUMBLE_TIME + 0.3
	vel_y = 80.0
	on_ground = false
	trick_spin = 0.0
	AudioManager.play_sfx("wrong", 0.06)
	emit_signal("stumble_hit")


func get_time_penalty() -> float:
	return TIME_PENALTY


func get_trick_bonus() -> float:
	return TRICK_TIME_BONUS


func _check_section_crossing() -> void:
	if section_idx >= SECTIONS.size():
		return
	var boundary := 0.0
	for i in range(section_idx + 1):
		boundary += SECTIONS[i].length
	if distance >= boundary:
		emit_signal("section_cleared", section_idx)
		section_idx += 1
		if section_idx < SECTIONS.size():
			_show_banner(SECTIONS[section_idx].name)
			_next_spawn_at = distance + 420.0


func _finish_run() -> void:
	if _finished:
		return
	_finished = true
	_active = false
	emit_signal("reached_zia")


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 1.0:
		w = 1280.0
		h = 720.0

	# Sky
	draw_rect(Rect2(0, 0, w, h), C_SKY_BOT)
	for i in 8:
		var t := float(i) / 8.0
		draw_rect(Rect2(0, 0, w, h * (1.0 - t * 0.55)), C_SKY_TOP.lerp(C_SKY_BOT, t))

	# Distant hills (parallax)
	var hill_off := fmod(distance * 0.08, 280.0)
	for i in range(-1, 6):
		var hx := float(i) * 280.0 - hill_off
		draw_colored_polygon(PackedVector2Array([
			Vector2(hx, GROUND_Y - 80),
			Vector2(hx + 140, GROUND_Y - 140 - float(i % 3) * 20.0),
			Vector2(hx + 280, GROUND_Y - 80),
		]), Color(0.52, 0.72, 0.48, 0.55))

	# Road surface
	draw_rect(Rect2(0, GROUND_Y - 8, w, h - GROUND_Y + 8), C_ROAD)
	for i in range(-2, int(w / 80.0) + 3):
		var lx := fmod(distance * 0.5 + float(i) * 80.0, 80.0) + float(i) * 0.0
		lx = fmod(distance, 80.0) * -1.0 + float(i) * 80.0
		draw_rect(Rect2(lx, GROUND_Y + 18, 40, 4), C_LINE)

	# Lane guides
	for ln in 2:
		var ly := _lane_y(ln)
		draw_line(Vector2(0, ly + 6), Vector2(w, ly + 6), Color(1, 1, 1, 0.08), 2.0)

	# Finish cottage
	var finish_x := _screen_x(total_length - FINISH_PAD * 0.5)
	if finish_x < w + 120.0:
		_draw_cottage(Vector2(finish_x, GROUND_Y - 95.0))

	# Obstacles
	for obs: Dictionary in _obstacles:
		var sx := _screen_x(obs.x)
		if sx < -80.0 or sx > w + 80.0:
			continue
		_draw_obstacle(obs, sx)

	# Player
	_draw_player()

	# HUD hints
	_draw_hud(w)

	# Prune old obstacles
	var kept: Array = []
	for obs: Dictionary in _obstacles:
		if _screen_x(obs.x) > -100.0:
			kept.append(obs)
	_obstacles = kept


func _draw_obstacle(obs: Dictionary, sx: float) -> void:
	var ly := _lane_y(obs.lane)
	match obs.kind:
		"log":
			draw_rect(Rect2(sx - obs.w * 0.5, ly - obs.h, obs.w, obs.h), Color(0.45, 0.30, 0.18))
		"puddle":
			draw_rect(Rect2(sx - obs.w * 0.5, ly - 6, obs.w, 8), Color(0.35, 0.55, 0.85, 0.75))
		"branch":
			draw_rect(Rect2(sx - obs.w * 0.5, ly - obs.h - 20, obs.w, 8), Color(0.35, 0.55, 0.25))
			draw_rect(Rect2(sx - 6, ly - obs.h - 20, 12, obs.h + 20), Color(0.40, 0.28, 0.15))
		"cone":
			draw_colored_polygon(PackedVector2Array([
				Vector2(sx, ly - obs.h),
				Vector2(sx - 14, ly),
				Vector2(sx + 14, ly),
			]), Color(1.0, 0.55, 0.15))
		_:
			draw_rect(Rect2(sx - obs.w * 0.5, ly - obs.h, obs.w, obs.h), Color(0.5, 0.5, 0.5))


func _draw_cottage(pos: Vector2) -> void:
	draw_rect(Rect2(pos.x - 50, pos.y, 100, 70), Color(0.72, 0.55, 0.42))
	draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-58, 0),
		pos + Vector2(0, -42),
		pos + Vector2(58, 0),
	]), Color(0.55, 0.28, 0.32))
	draw_rect(Rect2(pos.x - 14, pos.y + 28, 28, 42), Color(0.35, 0.22, 0.15))
	draw_string(ThemeDB.fallback_font, pos + Vector2(-32, -52), "Zia's", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.95, 0.9, 1.0))


func _draw_player() -> void:
	var px := PLAYER_X
	var py := _player_y()
	var flash := invuln_timer > 0.0 and int(invuln_timer * 20.0) % 2 == 0
	if flash:
		return

	var bob := sin(distance * 0.35) * 2.0 if on_ground else 0.0
	py += bob

	# Shadow
	_draw_shadow_oval(Vector2(px, GROUND_Y + 14), Vector2(22, 6), Color(0, 0, 0, 0.2))

	# Skates
	draw_circle(Vector2(px - 12, py + 4), 7, C_WHEEL)
	draw_circle(Vector2(px + 12, py + 4), 7, C_WHEEL)

	# Body with trick spin
	var rot := trick_spin * PI * 2.0
	var body_pts := PackedVector2Array([
		Vector2(-14, -38), Vector2(14, -38), Vector2(12, 0), Vector2(-12, 0),
	])
	if rot != 0.0:
		for i in body_pts.size():
			body_pts[i] = body_pts[i].rotated(rot) + Vector2(px, py - 18)
		draw_colored_polygon(body_pts, C_PLAYER)
	else:
		draw_rect(Rect2(px - 14, py - 38, 28, 38), C_PLAYER)

	# Head
	draw_circle(Vector2(px, py - 46), 12, Color(0.98, 0.82, 0.72))
	if GameState.remi_bald:
		draw_circle(Vector2(px, py - 50), 10, Color(0.98, 0.82, 0.72))
	else:
		draw_arc(Vector2(px, py - 48), 12, PI, TAU, 16, Color(0.55, 0.25, 0.65), 5.0)

	if stumble_timer > 0.0:
		draw_string(ThemeDB.fallback_font, Vector2(px - 30, py - 62), "Oof!", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 0.4, 0.35))


func _draw_hud(w: float) -> void:
	if _banner_timer > 0.0:
		draw_rect(Rect2(w * 0.5 - 160, 100, 320, 36), Color(0, 0, 0, 0.45))
		draw_string(ThemeDB.fallback_font, Vector2(w * 0.5 - 150, 124), _section_banner, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 0.95, 0.7))

	draw_string(ThemeDB.fallback_font, Vector2(16, 28), "🛼 Road to Boston", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.2, 0.15, 0.35))
	draw_string(ThemeDB.fallback_font, Vector2(16, 48), "W/S or ↑↓ lane  ·  Space jump  ·  ←→ air trick", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.25, 0.2, 0.3, 0.85))

	var prog := clampf(distance / total_length, 0.0, 1.0)
	draw_rect(Rect2(16, 58, w - 32, 8), Color(0, 0, 0, 0.25))
	draw_rect(Rect2(16, 58, (w - 32) * prog, 8), Color(0.45, 0.75, 0.95))


func _draw_shadow_oval(center: Vector2, radii: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * float(i) / 16.0
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_colored_polygon(pts, col)
