## DaisyDoodles.gd
## =============================================================
## Daisy is a small white fluffy dog who hides in the flowers.
##
## States:
##   HIDING    — invisible inside the flower patch, waiting for
##               the player to get close enough to "touch" them.
##   FLEEING   — runs away from the player at 1.3× player speed.
##               If the player has the leash, Daisy slows to 0.5×
##               and the player can catch her by running into her.
##   CAPTURED  — caught! Daisy is now a loyal companion.
##   COMPANION — follows the player everywhere and barks at any
##               NPC that starts chasing (freezes them briefly).
##
## Drawing: override _draw() — Daisy is a simple white dog shape.
## =============================================================
extends CharacterBody2D

# ─────────────────────────────────────────────────────────────
# CONSTANTS
# ─────────────────────────────────────────────────────────────
const FLEE_SPEED_MULT:     float = 1.3   # Faster than the player normally
const LEASH_SPEED_MULT:    float = 0.5   # Slows down once player has the leash
const CATCH_DISTANCE:      float = 22.0  # Player must be this close to catch her
const EMERGE_DISTANCE:     float = 75.0  # Distance at which she bolts out of flowers
const COMPANION_FOLLOW:    float = 65.0  # Stay this close to the player
const BARK_DETECT_RANGE:   float = 130.0 # Range to detect chasers
const BARK_FREEZE_DURATION:float = 2.5   # Seconds a chaser is frozen after bark
const BARK_COOLDOWN:       float = 3.0   # Min seconds between barks

# ─────────────────────────────────────────────────────────────
# STATE MACHINE
# ─────────────────────────────────────────────────────────────
enum State { HIDING, FLEEING, CAPTURED, COMPANION }

var _state: State = State.HIDING
var _player: Node = null
var _bark_cooldown_timer: float = 0.0

# ─────────────────────────────────────────────────────────────
# DRAWING COLORS
# ─────────────────────────────────────────────────────────────
const C_FUR    := Color(1.00, 1.00, 1.00)       # White fur
const C_EAR    := Color(0.90, 0.80, 0.70)       # Tan inner ear
const C_NOSE   := Color(0.90, 0.55, 0.65)       # Pink nose
const C_EYE    := Color(0.12, 0.08, 0.08)       # Dark brown eyes
const C_COLLAR := Color(1.00, 0.45, 0.10)       # Orange collar (when companion)


# ─────────────────────────────────────────────────────────────
# READY
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	add_to_group("daisy")

	# If Daisy was already caught in a previous session, skip straight to companion
	if GameState.daisy_captured:
		_state = State.COMPANION
		visible = true
	else:
		visible = false   # Hidden inside the flowers until triggered

	print("[DaisyDoodles] Daisy Doodles ready. State: ", State.keys()[_state])


# ─────────────────────────────────────────────────────────────
# PHYSICS LOOP
# ─────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	# Keep a fresh reference in case the player was just spawned
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")

	_bark_cooldown_timer = maxf(_bark_cooldown_timer - delta, 0.0)

	match _state:
		State.HIDING:
			_process_hiding()
		State.FLEEING:
			_process_fleeing()
		State.COMPANION:
			_process_companion(delta)


# ─────────────────────────────────────────────────────────────
# HIDING — emerge once the player is close enough to the flowers
# ─────────────────────────────────────────────────────────────
func _process_hiding() -> void:
	if _player == null:
		return
	if global_position.distance_to(_player.global_position) <= EMERGE_DISTANCE:
		visible = true
		_state = State.FLEEING
		queue_redraw()
		print("[DaisyDoodles] 🐾 Daisy burst out of the flowers!")


# ─────────────────────────────────────────────────────────────
# FLEEING — run away; slow down if player carries the leash
# ─────────────────────────────────────────────────────────────
func _process_fleeing() -> void:
	if _player == null:
		return

	var dist: float = global_position.distance_to(_player.global_position)

	# Base player speed (respects sneak mode)
	var player_speed: float = 150.0
	if _player.has_method("get_current_speed"):
		player_speed = _player.get_current_speed()

	var speed_mult: float = LEASH_SPEED_MULT if GameState.has_leash else FLEE_SPEED_MULT
	var flee_speed: float = player_speed * speed_mult

	# Run directly away from the player
	var away: Vector2 = global_position - _player.global_position
	if away.length() < 0.1:
		away = Vector2(1, 0)  # Fallback direction
	velocity = away.normalized() * flee_speed
	move_and_slide()

	# Can only be caught if the player has the leash
	if GameState.has_leash and dist <= CATCH_DISTANCE:
		_be_caught()


# ─────────────────────────────────────────────────────────────
# CAPTURED — transition to companion, save checkpoint
# ─────────────────────────────────────────────────────────────
func _be_caught() -> void:
	_state = State.CAPTURED
	GameState.daisy_captured = true
	velocity = Vector2.ZERO

	print("[DaisyDoodles] 🐾 Daisy caught! She's your best friend now!")

	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_notification"):
		hud.show_notification("🐾 Daisy is your friend now! She'll protect you!")

	# Save checkpoint right after catching her
	CheckpointManager.save_checkpoint(global_position)

	queue_redraw()
	_state = State.COMPANION


# ─────────────────────────────────────────────────────────────
# COMPANION — follow the player; bark at anyone chasing them
# ─────────────────────────────────────────────────────────────
func _process_companion(_delta: float) -> void:
	if _player == null:
		return

	# Follow behaviour
	var dist: float = global_position.distance_to(_player.global_position)
	if dist > COMPANION_FOLLOW:
		var dir: Vector2 = (_player.global_position - global_position).normalized()
		velocity = dir * 160.0
		move_and_slide()
	else:
		velocity = Vector2.ZERO

	# Check for chasers to bark at
	if _bark_cooldown_timer <= 0.0:
		_scan_for_threats()


# ─────────────────────────────────────────────────────────────
# BARK — detect and freeze any nearby NPC that is currently chasing
# ─────────────────────────────────────────────────────────────
func _scan_for_threats() -> void:
	var chasers := get_tree().get_nodes_in_group("chaser")
	for chaser in chasers:
		if not chaser.has_method("get_is_chasing"):
			continue
		if not chaser.get_is_chasing():
			continue
		if global_position.distance_to(chaser.global_position) > BARK_DETECT_RANGE:
			continue

		# Found a chaser — BARK!
		_bark_at(chaser)
		_bark_cooldown_timer = BARK_COOLDOWN
		break  # One bark per cooldown cycle


func _bark_at(chaser: Node) -> void:
	print("[DaisyDoodles] 🐶 WOOF! Daisy barks at ", chaser.name)
	if chaser.has_method("freeze"):
		chaser.freeze(BARK_FREEZE_DURATION)

	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_notification"):
		hud.show_notification("🐶 Woof! Daisy scared them off! Run!")


# ─────────────────────────────────────────────────────────────
# DRAWING — simple white dog using Godot 2D draw primitives
# Origin (0,0) is the dog's centre-bottom (feet on ground).
# ─────────────────────────────────────────────────────────────
func _draw() -> void:
	if not visible:
		return

	# ── Tail (right, small round nub) ────────────────────────
	draw_circle(Vector2(14, -8), 5.0, C_FUR)

	# ── Body ─────────────────────────────────────────────────
	draw_rect(Rect2(-10, -10, 24, 12), C_FUR)

	# ── Head (front-left) ────────────────────────────────────
	draw_circle(Vector2(-11, -8), 9.0, C_FUR)

	# ── Droopy ear ───────────────────────────────────────────
	draw_rect(Rect2(-17, -10, 8, 11), C_EAR)

	# ── Eye ──────────────────────────────────────────────────
	draw_circle(Vector2(-15, -10), 2.0, C_EYE)

	# ── Nose ─────────────────────────────────────────────────
	draw_circle(Vector2(-19, -5), 2.5, C_NOSE)

	# ── Legs (four short pegs) ───────────────────────────────
	draw_rect(Rect2(-8, 2, 5, 8), C_FUR)
	draw_rect(Rect2(-2, 2, 5, 8), C_FUR)
	draw_rect(Rect2(5, 2, 5, 8), C_FUR)
	draw_rect(Rect2(11, 2, 4, 7), C_FUR)

	# ── Collar (only when companion) ─────────────────────────
	if _state == State.COMPANION:
		draw_rect(Rect2(-17, -13, 12, 4), C_COLLAR)
