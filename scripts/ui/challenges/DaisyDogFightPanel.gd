## DaisyDogFightPanel.gd
## =============================================================
## Punch-Out style dog fight rendered inside a UI panel.
##
## Controls:
##   A / LEFT   — move left  (Daisy turns to face that way)
##   D / RIGHT  — move right (Daisy turns to face that way)
##   W / UP     — JUMP (evades ground attacks while in the air)
##   SPACE      — BITE (deal damage when close enough)
##   SHIFT      — STAND ON TWO FEET (brief invincibility + stuns attacker)
##
## Difficulty ladder: Rex (easy) → Nova (medium) → Brutus (hard)
## =============================================================
extends Control

# ─────────────────────────────────────────────────────────────
# ARENA CONSTANTS
# ─────────────────────────────────────────────────────────────
const ARENA_W:     float = 540.0
const ARENA_H:     float = 265.0
const FLOOR_Y:     float = 215.0

const DAISY_START_X: float = 100.0
const OPP_START_X:   float = 440.0

const MOVE_SPEED:     float = 170.0
const BITE_RANGE:     float = 75.0
const BITE_DAMAGE:    int   = 25
const BITE_COOLDOWN:  float = 0.60
const STAND_DURATION: float = 0.85
const HURT_DURATION:  float = 0.42
const MAX_HP:         int   = 100

const JUMP_SPEED: float = 370.0
const GRAVITY:    float = 720.0
const JUMP_EVADE_HEIGHT: float = 10.0   # Min y_off to evade attacks

# Dog draw colours (Daisy)
const C_FUR    := Color(1.00, 1.00, 1.00)
const C_EAR    := Color(0.90, 0.80, 0.70)
const C_NOSE   := Color(0.90, 0.55, 0.65)
const C_EYE    := Color(0.12, 0.08, 0.08)
const C_COLLAR := Color(1.00, 0.45, 0.10)
const DaisyDraw := preload("res://scripts/npcs/visuals/DaisyDrawHelper.gd")

# ─────────────────────────────────────────────────────────────
# STATE ENUMS
# ─────────────────────────────────────────────────────────────
enum FightState { INTRO, FIGHTING, ROUND_OVER, ALL_DONE }
enum DaisyState { IDLE, STANDING, BITING, HURT }
enum OppState   { IDLE, CHARGING, ATTACKING, HURT }

# ─────────────────────────────────────────────────────────────
# NODE REFERENCES
# ─────────────────────────────────────────────────────────────
@onready var title_label:  Label       = $Panel/VBoxContainer/TitleLabel
@onready var wager_label:  Label       = $Panel/VBoxContainer/WagerLabel
@onready var daisy_hp_bar: ProgressBar = $Panel/VBoxContainer/HPBars/DaisyHP
@onready var opp_hp_bar:   ProgressBar = $Panel/VBoxContainer/HPBars/OppHP
@onready var arena:        Control     = $Panel/VBoxContainer/ArenaWrap/Arena
@onready var owner_label:  Label       = $Panel/VBoxContainer/OwnerLabel
@onready var status_label: Label       = $Panel/VBoxContainer/StatusLabel
@onready var score_label:  Label       = $Panel/VBoxContainer/ScoreLabel
@onready var close_button: Button      = $Panel/VBoxContainer/CloseButton

# ─────────────────────────────────────────────────────────────
# MISSION / WAGER DATA
# ─────────────────────────────────────────────────────────────
var _mission_data:  Dictionary = {}
var _caller:        Node = null
var _owners:        Array = []
var _rounds:        int  = 3
var _required_wins: int  = 2
var _wager_cost:    int  = 6
var _payout_bonus:  int  = 14
var _entry_paid:    bool = false
var _current_round: int  = 0
var _wins:          int  = 0

# ─────────────────────────────────────────────────────────────
# FIGHT STATE
# ─────────────────────────────────────────────────────────────
var _fight_state: FightState = FightState.ALL_DONE

# Daisy
var _daisy_x:            float      = DAISY_START_X
var _daisy_y_off:        float      = 0.0     # Pixels above floor (0 = on floor)
var _daisy_y_vel:        float      = 0.0     # Upward velocity (positive = rising)
var _daisy_facing_right: bool       = true
var _daisy_state:        DaisyState = DaisyState.IDLE
var _daisy_hp:           int        = MAX_HP
var _daisy_stand_timer:  float      = 0.0
var _daisy_bite_timer:   float      = 0.0
var _daisy_hurt_timer:   float      = 0.0

# Opponent
var _opp_x:           float    = OPP_START_X
var _opp_state:       OppState = OppState.IDLE
var _opp_hp:          int      = MAX_HP
var _opp_idle_timer:  float    = 3.0
var _opp_hurt_timer:  float    = 0.0
var _opp_attacking:   bool     = false
var _opp_name:        String   = "Rex"
var _opp_color:       Color    = Color(0.55, 0.35, 0.22)
var _opp_scale:       float    = 1.10
var _opp_damage:      int      = 8
var _opp_charge_speed: float   = 50.0

# Owner display
var _owner_name:  String = "Owner"
var _owner_taunt: String = ""


# ─────────────────────────────────────────────────────────────
# READY
# ─────────────────────────────────────────────────────────────
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

	var cfg: Dictionary = mission_data.get("challenge", {})
	_rounds        = int(cfg.get("rounds", 3))
	_required_wins = int(cfg.get("required_wins", 2))
	_wager_cost    = int(cfg.get("wager_cost", 6))
	_payout_bonus  = int(cfg.get("payout_bonus", 14))
	_owners        = cfg.get("owners", [])

	_current_round = 0
	_wins          = 0
	_entry_paid    = false
	_fight_state   = FightState.ALL_DONE

	if title_label:
		title_label.text = "🥊  %s" % mission_data.get("title", "Dog Pit Bouts")
	if close_button:
		close_button.text = "Forfeit"

	var total_wager := _wager_cost * _rounds
	if not GameState.spend_tokens(total_wager):
		var hud := get_parent()
		if hud and hud.has_method("show_notification"):
			hud.show_notification("❌ Not enough VIBE (%d needed)." % total_wager)
		visible = false
		# Deferred so HUD.show_challenge() finishes its _set_game_paused(true) first,
		# then we unfreeze everything cleanly on the next frame.
		if hud and hud.has_method("close_all_panels"):
			hud.call_deferred("close_all_panels")
		return

	_entry_paid = true
	if wager_label:
		wager_label.text = "Entry: %d VIBE  ·  Win Bonus: +%d VIBE" % [total_wager, _payout_bonus]
	visible = true
	_start_round()


# ─────────────────────────────────────────────────────────────
# ROUND MANAGEMENT
# ─────────────────────────────────────────────────────────────
func _start_round() -> void:
	_current_round += 1
	_reset_fighters()
	_load_opponent_for_round()
	_update_score()

	var owner_data: Dictionary = _get_owner_data(_current_round - 1)
	_owner_name  = owner_data.get("name",  "Pit Owner")
	_owner_taunt = owner_data.get("taunt", "Let's see what Daisy can do!")

	if owner_label:
		owner_label.text = "%s: \"%s\"" % [_owner_name, _owner_taunt]
	if status_label:
		status_label.text = "Round %d of %d — Get ready!" % [_current_round, _rounds]
	_update_hp_bars()

	_fight_state = FightState.INTRO
	arena.queue_redraw()

	await get_tree().create_timer(2.0).timeout
	if _fight_state == FightState.INTRO:
		_fight_state = FightState.FIGHTING
		if status_label:
			status_label.text = "A/D Move  ·  W Jump  ·  SPACE Bite  ·  SHIFT Stand"
		AudioManager.play_sfx("whistle")


func _reset_fighters() -> void:
	_daisy_x            = DAISY_START_X
	_daisy_y_off        = 0.0
	_daisy_y_vel        = 0.0
	_daisy_facing_right = true
	_daisy_state        = DaisyState.IDLE
	_daisy_hp           = MAX_HP
	_daisy_stand_timer  = 0.0
	_daisy_bite_timer   = 0.0
	_daisy_hurt_timer   = 0.0

	_opp_x          = OPP_START_X
	_opp_state      = OppState.IDLE
	_opp_hp         = MAX_HP
	_opp_hurt_timer = 0.0
	_opp_attacking  = false
	# _opp_idle_timer and other stats set by _load_opponent_for_round


func _load_opponent_for_round() -> void:
	match _current_round:
		1:  # Rex — very easy. Slow, telegraphed, weak.
			_opp_name         = "Rex"
			_opp_color        = Color(0.55, 0.35, 0.22)
			_opp_scale        = 1.10
			_opp_damage       = 8
			_opp_charge_speed = 50.0
			_opp_idle_timer   = 3.0
		2:  # Nova — medium speed, moderate damage.
			_opp_name         = "Nova"
			_opp_color        = Color(0.55, 0.50, 0.82)
			_opp_scale        = 1.20
			_opp_damage       = 20
			_opp_charge_speed = 88.0
			_opp_idle_timer   = 1.8
		3:  # Brutus — fast, heavy damage, large.
			_opp_name         = "Brutus"
			_opp_color        = Color(0.22, 0.20, 0.18)
			_opp_scale        = 1.50
			_opp_damage       = 30
			_opp_charge_speed = 115.0
			_opp_idle_timer   = 1.0
		_:
			_opp_name         = "Dog %d" % _current_round
			_opp_color        = Color(0.45, 0.30, 0.22)
			_opp_scale        = 1.0 + (_current_round - 1) * 0.12
			_opp_damage       = 8 + (_current_round - 1) * 11
			_opp_charge_speed = 50.0 + (_current_round - 1) * 30.0
			_opp_idle_timer   = maxf(3.0 - (_current_round - 1) * 0.8, 0.8)


func _get_owner_data(idx: int) -> Dictionary:
	if _owners.is_empty():
		return {}
	return _owners[clampi(idx, 0, _owners.size() - 1)]


# ─────────────────────────────────────────────────────────────
# PROCESS LOOP
# ─────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if not visible or _fight_state != FightState.FIGHTING:
		return
	_update_daisy(delta)
	_update_opponent(delta)
	_update_hp_bars()
	arena.queue_redraw()


func _update_daisy(delta: float) -> void:
	_daisy_bite_timer  = maxf(_daisy_bite_timer  - delta, 0.0)
	_daisy_hurt_timer  = maxf(_daisy_hurt_timer  - delta, 0.0)
	_daisy_stand_timer = maxf(_daisy_stand_timer - delta, 0.0)

	# Jump physics — always applies regardless of other state
	if _daisy_y_off > 0.0 or _daisy_y_vel > 0.0:
		_daisy_y_off += _daisy_y_vel * delta
		_daisy_y_vel -= GRAVITY * delta
		if _daisy_y_off <= 0.0:
			_daisy_y_off = 0.0
			_daisy_y_vel = 0.0

	if _daisy_hurt_timer > 0.0:
		_daisy_state = DaisyState.HURT
		return
	if _daisy_stand_timer > 0.0:
		_daisy_state = DaisyState.STANDING
		return
	if _daisy_state == DaisyState.BITING and _daisy_bite_timer > 0.0:
		return

	# Movement + turning
	if Input.is_action_pressed("move_left"):
		_daisy_x = maxf(_daisy_x - MOVE_SPEED * delta, 18.0)
		_daisy_facing_right = false
	elif Input.is_action_pressed("move_right"):
		_daisy_x = minf(_daisy_x + MOVE_SPEED * delta, ARENA_W - 18.0)
		_daisy_facing_right = true

	_daisy_state = DaisyState.IDLE


func _update_opponent(delta: float) -> void:
	_opp_hurt_timer = maxf(_opp_hurt_timer - delta, 0.0)

	if _opp_hurt_timer > 0.0:
		_opp_state = OppState.HURT
		return

	# ── BUG FIX: recover from HURT when timer expires ─────────
	if _opp_state == OppState.HURT:
		_opp_state     = OppState.IDLE
		_opp_attacking = false
		return

	match _opp_state:
		OppState.IDLE:
			_opp_idle_timer -= delta
			if _opp_idle_timer <= 0.0:
				_opp_state = OppState.CHARGING

		OppState.CHARGING:
			var dir := signf(_daisy_x - _opp_x)
			_opp_x += dir * _opp_charge_speed * delta
			_opp_x = clampf(_opp_x, 30.0, ARENA_W - 30.0)
			if abs(_daisy_x - _opp_x) <= 58.0 and not _opp_attacking:
				_opp_state     = OppState.ATTACKING
				_opp_attacking = true
				_do_attack()

		OppState.ATTACKING, OppState.HURT:
			pass


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

	if _fight_state != FightState.FIGHTING:
		return

	match event.keycode:
		KEY_SPACE:
			get_viewport().set_input_as_handled()
			_try_bite()
		KEY_SHIFT:
			get_viewport().set_input_as_handled()
			_try_stand()
		KEY_W, KEY_UP:
			get_viewport().set_input_as_handled()
			_try_jump()


func _try_bite() -> void:
	if _daisy_bite_timer > 0.0 or _daisy_state == DaisyState.HURT or _daisy_state == DaisyState.STANDING:
		return
	_daisy_state      = DaisyState.BITING
	_daisy_bite_timer = BITE_COOLDOWN
	AudioManager.play_sfx("bark", 0.1)

	if abs(_daisy_x - _opp_x) <= BITE_RANGE and _opp_state != OppState.HURT:
		_opp_hp         = maxi(_opp_hp - BITE_DAMAGE, 0)
		_opp_state      = OppState.HURT
		_opp_hurt_timer = HURT_DURATION
		_opp_attacking  = false
		AudioManager.play_sfx("correct")
		if _opp_hp <= 0:
			_end_round(true)


func _try_stand() -> void:
	if _daisy_stand_timer > 0.0 or _daisy_state == DaisyState.HURT:
		return
	_daisy_state       = DaisyState.STANDING
	_daisy_stand_timer = STAND_DURATION
	AudioManager.play_sfx("reward", 0.05)


func _try_jump() -> void:
	if _daisy_y_off > 0.0 or _daisy_y_vel != 0.0 or _daisy_state == DaisyState.HURT:
		return
	_daisy_y_vel = JUMP_SPEED
	AudioManager.play_sfx("step", 0.08)


# ─────────────────────────────────────────────────────────────
# OPPONENT ATTACK (async — guarded by _opp_attacking flag)
# ─────────────────────────────────────────────────────────────
func _do_attack() -> void:
	AudioManager.play_sfx("wrong", 0.05)

	var evaded := (_daisy_state == DaisyState.STANDING or _daisy_y_off >= JUMP_EVADE_HEIGHT)

	if evaded:
		# Daisy dodged — opponent is stunned
		if status_label:
			if _daisy_y_off >= JUMP_EVADE_HEIGHT:
				status_label.text = "Jumped over the attack! Hit back with SPACE!"
			else:
				status_label.text = "Daisy stood tall! Counter with SPACE!"
		_opp_hurt_timer = HURT_DURATION * 2.5
		_opp_state      = OppState.HURT
	else:
		_daisy_hp         = maxi(_daisy_hp - _opp_damage, 0)
		_daisy_state      = DaisyState.HURT
		_daisy_hurt_timer = HURT_DURATION
		if _daisy_hp <= 0:
			_opp_attacking = false
			_end_round(false)
			return

	await get_tree().create_timer(0.55).timeout

	_opp_attacking = false
	if _fight_state == FightState.FIGHTING and _opp_state == OppState.ATTACKING:
		_opp_state      = OppState.IDLE
		_opp_idle_timer = maxf(_opp_idle_timer * 0.85, 0.45)


# ─────────────────────────────────────────────────────────────
# ROUND END
# ─────────────────────────────────────────────────────────────
func _end_round(daisy_won: bool) -> void:
	if _fight_state != FightState.FIGHTING:
		return
	_fight_state = FightState.ROUND_OVER

	if daisy_won:
		_wins += 1
		AudioManager.play_sfx("goal_cheer")
		if status_label:
			status_label.text = "🏆 Daisy beats %s! Round %d done." % [_opp_name, _current_round]
	else:
		AudioManager.play_sfx("goal_miss")
		if status_label:
			status_label.text = "💔 %s got the better of Daisy..." % _opp_name

	_update_score()
	await get_tree().create_timer(2.5).timeout

	if _fight_state != FightState.ROUND_OVER:
		return
	if _current_round >= _rounds:
		_finish(_wins >= _required_wins)
	else:
		_start_round()


# ─────────────────────────────────────────────────────────────
# FINISH
# ─────────────────────────────────────────────────────────────
func _finish(success: bool) -> void:
	_fight_state = FightState.ALL_DONE
	if success and _entry_paid:
		GameState.add_tokens(_payout_bonus)
	visible = false
	if _caller and _caller.has_method("on_challenge_finished"):
		_caller.on_challenge_finished(success)
	var hud := get_parent()
	if hud and hud.has_method("close_all_panels"):
		hud.close_all_panels()


# ─────────────────────────────────────────────────────────────
# UI UPDATES
# ─────────────────────────────────────────────────────────────
func _update_score() -> void:
	if score_label:
		score_label.text = "Wins: %d / %d  ·  Round %d of %d  ·  Need %d" % [
			_wins, _rounds, _current_round, _rounds, _required_wins
		]


func _update_hp_bars() -> void:
	if daisy_hp_bar:
		daisy_hp_bar.value = _daisy_hp
	if opp_hp_bar:
		opp_hp_bar.value = _opp_hp


# ─────────────────────────────────────────────────────────────
# ── ARENA DRAW ───────────────────────────────────────────────
# ─────────────────────────────────────────────────────────────
func _on_arena_draw() -> void:
	if not arena:
		return

	# Background
	arena.draw_rect(Rect2(0, 0, ARENA_W, ARENA_H), Color(0.20, 0.12, 0.09))

	# Crowd silhouettes (deterministic, no flicker)
	for i in 20:
		var cx: float = 14.0 + i * 26.5
		var cy: float = 22.0 + fmod(cx * 2.7, 24.0)
		var cr: float = 5.0 + fmod(cx * 1.3, 4.0)
		arena.draw_circle(Vector2(cx, cy), cr, Color(0.30, 0.18, 0.14, 0.75))
		arena.draw_circle(Vector2(cx, cy - cr - 3.0), cr * 0.65, Color(0.55, 0.38, 0.28, 0.60))

	# Ropes
	for ry: float in [FLOOR_Y - 55.0, FLOOR_Y - 35.0, FLOOR_Y - 15.0]:
		arena.draw_line(Vector2(0, ry), Vector2(ARENA_W, ry), Color(0.72, 0.60, 0.45, 0.55), 2.0)
	for px: float in [0.0, ARENA_W]:
		arena.draw_line(Vector2(px, FLOOR_Y - 60.0), Vector2(px, FLOOR_Y + 10.0),
			Color(0.55, 0.42, 0.28), 4.0)

	# Floor
	arena.draw_rect(Rect2(0, FLOOR_Y - 4.0, ARENA_W, ARENA_H - FLOOR_Y + 4.0),
		Color(0.52, 0.36, 0.24))
	arena.draw_rect(Rect2(0, FLOOR_Y - 6.0, ARENA_W, 4.0), Color(0.68, 0.50, 0.34))
	arena.draw_line(Vector2(ARENA_W * 0.5, FLOOR_Y - 4.0), Vector2(ARENA_W * 0.5, FLOOR_Y + 25.0),
		Color(0.62, 0.46, 0.30, 0.40), 2.0)

	# Owner
	_draw_owner(Vector2(OPP_START_X + 36.0, FLOOR_Y - 48.0))

	# Opponent + Daisy
	_draw_opp_dog()
	_draw_daisy()


# ─────────────────────────────────────────────────────────────
# OWNER FIGURE
# ─────────────────────────────────────────────────────────────
func _draw_owner(pos: Vector2) -> void:
	var body_c  := Color(0.62, 0.36, 0.26)
	var pants_c := Color(0.28, 0.36, 0.62)
	var skin_c  := Color(0.88, 0.72, 0.55)
	arena.draw_circle(pos + Vector2(0, 2), 13.0, Color(0, 0, 0, 0.18))
	arena.draw_rect(Rect2(pos.x - 10, pos.y + 10, 8, 22), pants_c)
	arena.draw_rect(Rect2(pos.x + 2,  pos.y + 10, 8, 22), pants_c)
	arena.draw_rect(Rect2(pos.x - 14, pos.y - 24, 28, 36), body_c)
	arena.draw_rect(Rect2(pos.x - 22, pos.y - 14, 10, 6), body_c)
	arena.draw_rect(Rect2(pos.x + 12, pos.y - 14, 10, 6), body_c)
	arena.draw_circle(pos + Vector2(0, -34), 14.0, skin_c)
	arena.draw_line(pos + Vector2(-7, -36), pos + Vector2(-2, -35), C_EYE, 2.0)
	arena.draw_line(pos + Vector2(2,  -36), pos + Vector2(7,  -35), C_EYE, 2.0)
	arena.draw_arc(pos + Vector2(0, -28), 5.0, 0.2, PI - 0.2, 6, C_EYE, 1.5)
	arena.draw_rect(Rect2(pos.x - 17, pos.y - 50, 34, 5), Color(0.18, 0.14, 0.10))
	arena.draw_rect(Rect2(pos.x - 12, pos.y - 66, 24, 18), Color(0.18, 0.14, 0.10))


# ─────────────────────────────────────────────────────────────
# OPPONENT DOG (faces LEFT — head on left side)
# ─────────────────────────────────────────────────────────────
func _draw_opp_dog() -> void:
	var s  := _opp_scale
	var x  := _opp_x
	var y  := FLOOR_Y
	var c  := _opp_color
	var cd := c.darkened(0.28)
	if _opp_state == OppState.HURT:
		c  = c.lightened(0.55)
		cd = c.darkened(0.1)
	arena.draw_circle(Vector2(x, y + 5.0), 18.0 * s, Color(0, 0, 0, 0.22))
	arena.draw_circle(Vector2(x + 15 * s, y - 9 * s), 5.5 * s, c)
	arena.draw_rect(Rect2(x - 12 * s, y - 13 * s, 28 * s, 15 * s), c)
	arena.draw_circle(Vector2(x - 14 * s, y - 11 * s), 12.0 * s, c)
	arena.draw_rect(Rect2(x - 10 * s, y - 22 * s, 10 * s, 15 * s), cd)
	arena.draw_circle(Vector2(x - 20 * s, y - 13 * s), 2.8 * s, C_EYE)
	arena.draw_line(Vector2(x - 25 * s, y - 17 * s), Vector2(x - 14 * s, y - 15 * s), C_EYE, 2.0)
	arena.draw_circle(Vector2(x - 24 * s, y - 7 * s), 3.2 * s, C_NOSE)
	for i in 4:
		var lx: float = x + (float(i) * 7.0 - 9.0) * s
		arena.draw_rect(Rect2(lx, y + 2 * s, 5.5 * s, 10 * s), c)
	if _opp_state == OppState.CHARGING or _opp_state == OppState.ATTACKING:
		arena.draw_circle(Vector2(x - 28 * s, y - 9 * s), 4.5 * s, Color(1, 0.75, 0.2, 0.75))
		arena.draw_circle(Vector2(x - 33 * s, y - 5 * s), 3.0 * s, Color(1, 0.55, 0.2, 0.55))
	# Name tag
	arena.draw_rect(Rect2(x - 22 * s, y - 32 * s, 44 * s, 14 * s), Color(0.12, 0.08, 0.06, 0.72))


# ─────────────────────────────────────────────────────────────
# DAISY (player controlled, faces the direction she's moving)
# Uses draw_set_transform to mirror when facing left.
# ─────────────────────────────────────────────────────────────
func _draw_daisy() -> void:
	var draw_y := FLOOR_Y - _daisy_y_off

	# Shadow stays on floor; shrinks as Daisy jumps
	var shadow_r := maxf(16.0 - _daisy_y_off * 0.20, 4.0)
	arena.draw_circle(Vector2(_daisy_x, FLOOR_Y + 5.0), shadow_r, Color(0, 0, 0, 0.22))

	# Flip transform when facing left
	if not _daisy_facing_right:
		arena.draw_set_transform(Vector2(2.0 * _daisy_x, 0.0), 0.0, Vector2(-1.0, 1.0))

	var c := C_FUR
	if _daisy_state == DaisyState.HURT:
		c = Color(1.0, 0.50, 0.50)

	match _daisy_state:
		DaisyState.STANDING:
			_draw_daisy_standing(_daisy_x, draw_y, c)
			_apply_groomer_look(_daisy_x, draw_y - 42.0)
		DaisyState.BITING:
			var lunge := 14.0
			_draw_daisy_biting(_daisy_x, draw_y, c)
			_apply_groomer_look(_daisy_x + 14.0 + lunge, draw_y - 9.0)
		_:
			DaisyDraw.draw_idle_dog(arena, _daisy_x, draw_y, 1.0, _daisy_facing_right)

	# Reset transform
	if not _daisy_facing_right:
		arena.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_daisy_standing(x: float, y: float, c: Color) -> void:
	arena.draw_rect(Rect2(x - 7, y - 2,  7, 14), c)   # Back legs
	arena.draw_rect(Rect2(x + 0, y - 2,  7, 14), c)
	arena.draw_rect(Rect2(x - 9, y - 32, 18, 32), c)  # Upright body
	arena.draw_rect(Rect2(x - 22, y - 26, 14, 5), c)  # Left paw
	arena.draw_rect(Rect2(x + 9,  y - 26, 14, 5), c)  # Right paw
	arena.draw_circle(Vector2(x, y - 42), 11.0, c)    # Head
	arena.draw_rect(Rect2(x + 6, y - 50, 8, 12), C_EAR)
	arena.draw_circle(Vector2(x + 5, y - 43), 2.2, C_EYE)
	arena.draw_circle(Vector2(x + 10, y - 38), 2.8, C_NOSE)
	arena.draw_rect(Rect2(x - 9, y - 32, 18, 4), C_COLLAR)
	# Golden invincibility ring
	arena.draw_arc(Vector2(x, y - 22), 28.0, 0, TAU, 24, Color(1.0, 0.9, 0.3, 0.55), 3.0)


func _draw_daisy_biting(x: float, y: float, c: Color) -> void:
	var lunge := 14.0
	arena.draw_colored_polygon(PackedVector2Array([
		Vector2(x - 12,          y - 4),
		Vector2(x + 14 + lunge,  y - 12),
		Vector2(x + 14 + lunge,  y + 1),
		Vector2(x - 12,          y + 5),
	]), c)
	arena.draw_circle(Vector2(x + 14 + lunge, y - 9), 10.0, c)
	arena.draw_arc(Vector2(x + 24 + lunge, y - 6), 6.0, -0.5, 0.5, 8, Color(0.75, 0.18, 0.18), 2.5)
	arena.draw_rect(Rect2(x + 10 + lunge, y - 16, 9, 12), C_EAR)
	arena.draw_circle(Vector2(x + 17 + lunge, y - 11), 2.2, C_EYE)
	arena.draw_rect(Rect2(x - 10, y + 2, 5, 9), c)
	arena.draw_rect(Rect2(x - 3,  y + 2, 5, 9), c)
	arena.draw_rect(Rect2(x + 5 + lunge * 0.4, y - 15, 12, 4), C_COLLAR)


func _apply_groomer_look(head_x: float, head_y: float) -> void:
	DaisyDraw.draw_haircut_only(arena, head_x, head_y, 1.0, _daisy_facing_right)
	DaisyDraw.draw_outfit_only(arena, _daisy_x, FLOOR_Y - _daisy_y_off, 1.0, _daisy_facing_right)


# ─────────────────────────────────────────────────────────────
# CLOSE / FORFEIT
# ─────────────────────────────────────────────────────────────
func _on_close_pressed() -> void:
	AudioManager.play_sfx("click")
	_fight_state = FightState.ALL_DONE
	_finish(false)
