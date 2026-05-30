## MsHuffy.gd
## =============================================================
## Ms. Huffy is the grumpy school librarian.
## She loves silence — and she WILL chase you if you wake her.
##
## States:
##   SLEEPING  — resting at her desk. ZZZ label is visible.
##               Wakes up when the player enters her detection radius.
##               Sneak (Shift) halves that radius.
##   ALERTED   — one-frame transition: just woke up, starts chasing.
##   CHASING   — moves toward the player at 90 % of the player's speed.
##               If the player escapes beyond GIVE_UP_DIST she gives up.
##               If she touches the player: Game Over → respawn.
##   RETURNING — trotting back to her desk after losing the player.
##   FROZEN    — briefly stopped by Daisy's bark.
##
## Drawing: _draw() renders a round, plump librarian figure with
##          blonde hair piled up and thick library glasses.
## =============================================================
extends CharacterBody2D

# ─────────────────────────────────────────────────────────────
# CONSTANTS
# ─────────────────────────────────────────────────────────────
const DETECT_RADIUS:       float = 95.0   # Wake-up distance (normal walk)
const DETECT_RADIUS_SNEAK: float = 46.0   # Wake-up distance (player tiptoeing)
const CATCH_RADIUS:        float = 22.0   # Distance at which she catches the player
const GIVE_UP_DIST:        float = 420.0  # Gives up chase beyond this distance
const CHASE_SPEED_MULT:    float = 0.90   # 90 % of player's current speed
const RETURN_SPEED:        float = 70.0   # Slow trot back to desk

# ─────────────────────────────────────────────────────────────
# STATE MACHINE
# ─────────────────────────────────────────────────────────────
enum State { SLEEPING, ALERTED, CHASING, RETURNING, FROZEN }

var _state: State = State.SLEEPING
var _player: Node = null
var _home_position: Vector2 = Vector2.ZERO
var _freeze_timer: float = 0.0

# ─────────────────────────────────────────────────────────────
# DRAWING COLORS
# ─────────────────────────────────────────────────────────────
const C_SKIN    := Color(0.97, 0.84, 0.71)
const C_BLONDE  := Color(0.98, 0.88, 0.22)
const C_DRESS   := Color(0.58, 0.38, 0.72)   # Librarian purple
const C_GLASSES := Color(0.15, 0.20, 0.75)
const C_DARK    := Color(0.10, 0.08, 0.08)
const C_ANGRY   := Color(0.82, 0.12, 0.12)

# ─────────────────────────────────────────────────────────────
# CHILD NODES
# ─────────────────────────────────────────────────────────────
var _zzz_label: Label = null


# ─────────────────────────────────────────────────────────────
# READY
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	add_to_group("chaser")
	_home_position = global_position

	# ZZZ label — floating above her head when sleeping
	_zzz_label = Label.new()
	_zzz_label.text = "💤 z z z"
	_zzz_label.position = Vector2(-20, -72)
	_zzz_label.add_theme_font_size_override("font_size", 12)
	_zzz_label.modulate = Color(0.7, 0.8, 1.0, 1.0)
	add_child(_zzz_label)

	print("[MsHuffy] Ms. Huffy ready. Shhh — she's sleeping!")


# ─────────────────────────────────────────────────────────────
# PHYSICS LOOP
# ─────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")

	match _state:
		State.SLEEPING:
			_process_sleeping()
		State.ALERTED:
			_wake_up()
		State.CHASING:
			_process_chasing(delta)
		State.RETURNING:
			_process_returning()
		State.FROZEN:
			_process_frozen(delta)

	_zzz_label.visible = (_state == State.SLEEPING or _state == State.RETURNING)


# ─────────────────────────────────────────────────────────────
# SLEEPING — wait until the player wanders too close
# ─────────────────────────────────────────────────────────────
func _process_sleeping() -> void:
	if _player == null:
		return

	var dist: float = global_position.distance_to(_player.global_position)

	# Sneaking halves the detection radius
	var radius := DETECT_RADIUS
	if _player.has_method("is_player_sneaking") and _player.is_player_sneaking():
		radius = DETECT_RADIUS_SNEAK

	if dist <= radius:
		_state = State.ALERTED


# ─────────────────────────────────────────────────────────────
# ALERTED — one frame, then chase
# ─────────────────────────────────────────────────────────────
func _wake_up() -> void:
	print("[MsHuffy] 😡 HEY! NO RUNNING IN THE LIBRARY!")
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_notification"):
		hud.show_notification("😡 Ms. Huffy woke up! Run!")
	_state = State.CHASING
	queue_redraw()


# ─────────────────────────────────────────────────────────────
# CHASING — follow the player at 90 % of their speed
# ─────────────────────────────────────────────────────────────
func _process_chasing(_delta: float) -> void:
	if _player == null:
		return

	var dist: float = global_position.distance_to(_player.global_position)

	# Give up if the player has run far enough away
	if dist > GIVE_UP_DIST:
		_state = State.RETURNING
		queue_redraw()
		return

	# Catch the player
	if dist <= CATCH_RADIUS:
		_catch_player()
		return

	# Move toward player
	var player_speed: float = 150.0
	if _player.has_method("get_current_speed"):
		player_speed = _player.get_current_speed()
	var chase_speed := player_speed * CHASE_SPEED_MULT

	var dir: Vector2 = (_player.global_position - global_position).normalized()
	velocity = dir * chase_speed
	move_and_slide()


# ─────────────────────────────────────────────────────────────
# RETURNING — walk back to the desk after losing the player
# ─────────────────────────────────────────────────────────────
func _process_returning() -> void:
	var dist: float = global_position.distance_to(_home_position)
	if dist < 5.0:
		global_position = _home_position
		velocity = Vector2.ZERO
		_state = State.SLEEPING
		queue_redraw()
		return

	var dir: Vector2 = (_home_position - global_position).normalized()
	velocity = dir * RETURN_SPEED
	move_and_slide()


# ─────────────────────────────────────────────────────────────
# FROZEN — temporarily stunned by Daisy's bark
# ─────────────────────────────────────────────────────────────
func _process_frozen(delta: float) -> void:
	_freeze_timer -= delta
	if _freeze_timer <= 0.0:
		# Resume chasing or go home depending on distance
		if _player and global_position.distance_to(_player.global_position) < GIVE_UP_DIST:
			_state = State.CHASING
		else:
			_state = State.RETURNING
		queue_redraw()


# ─────────────────────────────────────────────────────────────
# Called by DaisyDoodles.bark_at() to temporarily freeze her
# ─────────────────────────────────────────────────────────────
func freeze(duration: float) -> void:
	print("[MsHuffy] 🐶 Frozen by Daisy's bark! Duration: ", duration)
	_state = State.FROZEN
	_freeze_timer = duration
	velocity = Vector2.ZERO
	queue_redraw()


# ─────────────────────────────────────────────────────────────
# Called by DaisyDoodles to check if she should bark
# ─────────────────────────────────────────────────────────────
func get_is_chasing() -> bool:
	return _state == State.CHASING


# ─────────────────────────────────────────────────────────────
# CATCH PLAYER — trigger the game over overlay
# ─────────────────────────────────────────────────────────────
func _catch_player() -> void:
	print("[MsHuffy] 📚 Caught you! No running in the library!")
	velocity = Vector2.ZERO
	_state = State.SLEEPING

	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_game_over"):
		hud.show_game_over("Ms. Huffy")
	else:
		# Fallback if no HUD: go straight to respawn
		CheckpointManager.trigger_respawn()


# ─────────────────────────────────────────────────────────────
# DRAWING — plump round librarian figure
# ─────────────────────────────────────────────────────────────
func _draw() -> void:
	var chasing := (_state == State.CHASING)
	var frozen  := (_state == State.FROZEN)

	# ── Rounded body (wide) ──────────────────────────────────
	draw_circle(Vector2(0, 10), 20.0, C_DRESS)
	draw_rect(Rect2(-18, -8, 36, 28), C_DRESS)

	# ── Arms ─────────────────────────────────────────────────
	draw_rect(Rect2(-28, -2, 12, 22), C_SKIN)
	draw_rect(Rect2(16, -2, 12, 22), C_SKIN)

	# ── Head ─────────────────────────────────────────────────
	draw_circle(Vector2(0, -22), 17.0, C_SKIN)

	# ── Big blonde hair piled on top ─────────────────────────
	draw_circle(Vector2(0, -37), 15.0, C_BLONDE)
	draw_rect(Rect2(-17, -46, 34, 18), C_BLONDE)

	# ── Thick glasses ────────────────────────────────────────
	var glass_col := C_ANGRY if (chasing or frozen) else C_GLASSES
	draw_rect(Rect2(-16, -26, 11, 7), glass_col)
	draw_rect(Rect2(5, -26, 11, 7), glass_col)
	draw_rect(Rect2(-5, -24, 10, 4), glass_col)  # Bridge

	# ── Eyes ─────────────────────────────────────────────────
	draw_circle(Vector2(-10, -22), 2.0, C_DARK)
	draw_circle(Vector2(10, -22), 2.0, C_DARK)

	# ── Eyebrows (angry when chasing) ────────────────────────
	if chasing or frozen:
		draw_rect(Rect2(-14, -31, 10, 3), C_DARK)   # Left brow, angled
		draw_rect(Rect2(4, -31, 10, 3), C_DARK)     # Right brow

	# ── Mouth ────────────────────────────────────────────────
	if chasing:
		draw_rect(Rect2(-8, -14, 16, 3), C_DARK)    # Wide angry mouth
	else:
		draw_rect(Rect2(-5, -14, 10, 2), C_DARK)    # Neutral / sleeping
