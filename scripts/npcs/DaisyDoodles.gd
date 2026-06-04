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

const CharacterShadowScene := preload("res://scenes/effects/CharacterShadow.tscn")
const DaisyDraw := preload("res://scripts/npcs/visuals/DaisyDrawHelper.gd")

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
var _is_talking: bool = false   # Prevents double-interaction during fetch dialogue

const FETCH_MISSION_ID: String = "daisy_fetch_game"

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
	add_to_group("daisy_appearance")

	if not get_node_or_null("CharacterShadow"):
		var shadow := CharacterShadowScene.instantiate()
		shadow.position = Vector2(0, 10)
		shadow.scale = Vector2(0.65, 0.65)
		add_child(shadow)
		move_child(shadow, 0)

	# If Daisy was already caught in a previous session, skip straight to companion
	if GameState.daisy_captured:
		_state = State.COMPANION
		visible = true
		_become_interactable()
	else:
		visible = false   # Hidden inside the flowers until triggered

	print("[DaisyDoodles] Daisy Doodles ready. State: ", State.keys()[_state])


# Marks Daisy as a talk-target for the player's [E] interact key
# (only used after she becomes a companion).
func _become_interactable() -> void:
	if not is_in_group("interactable"):
		add_to_group("interactable")
	if not is_in_group("npc"):
		add_to_group("npc")


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
	AudioManager.play_sfx("bark", 0.1)

	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_notification"):
		hud.show_notification("🐾 Daisy is your friend now! Press [E] to play fetch!")

	# Save checkpoint right after catching her
	CheckpointManager.save_checkpoint(global_position)

	queue_redraw()
	_state = State.COMPANION
	_become_interactable()


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
	AudioManager.play_sfx("bark", 0.05)
	if chaser.has_method("freeze"):
		chaser.freeze(BARK_FREEZE_DURATION)

	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_notification"):
		hud.show_notification("🐶 Woof! Daisy scared them off! Run!")


# ─────────────────────────────────────────────────────────────
# INTERACT — opens the fetch mini-game (only when companion).
# Called by Player.gd when the player presses [E] near Daisy.
# ─────────────────────────────────────────────────────────────
func on_player_interact(_player_node: Node) -> void:
	if _is_talking:
		return
	if _state != State.COMPANION:
		return

	_is_talking = true
	AudioManager.play_sfx("bark", 0.1)
	var mission: Dictionary = MissionDatabase.get_mission(FETCH_MISSION_ID)
	var dialogue_box := _find_dialogue_box()

	if MissionManager.is_mission_complete(FETCH_MISSION_ID):
		if dialogue_box:
			dialogue_box.show_dialogue("Daisy", mission.get("dialogue_complete", []), self)
		else:
			_is_talking = false
		return

	MissionManager.start_mission(FETCH_MISSION_ID)
	if dialogue_box:
		dialogue_box.show_dialogue("Daisy", mission.get("dialogue_intro", []), self, true)
	else:
		_present_puzzle()


# Called by DialogueBox when intro dialogue finishes (show_puzzle_after flag).
func _present_puzzle() -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_challenge"):
		var mission: Dictionary = MissionDatabase.get_mission(FETCH_MISSION_ID)
		hud.show_challenge("DaisyFetchPanel", mission, self)


# Called when the fetch panel finishes.
func on_challenge_finished(success: bool) -> void:
	var mission: Dictionary = MissionDatabase.get_mission(FETCH_MISSION_ID)
	var dialogue_box := _find_dialogue_box()

	if success:
		var rewards: Dictionary = mission.get("rewards", {})
		RewardManager.grant_reward(rewards)
		MissionManager.complete_mission(FETCH_MISSION_ID, rewards)
		SaveManager.save_game()
		if dialogue_box:
			dialogue_box.show_dialogue("Daisy", mission.get("dialogue_success", []), self)
	else:
		if dialogue_box:
			dialogue_box.show_dialogue("Daisy", mission.get("dialogue_failure", []), self)
		await get_tree().create_timer(0.5).timeout
		_is_talking = false


func on_dialogue_finished() -> void:
	_is_talking = false


func refresh_appearance() -> void:
	queue_redraw()


# Reuses the same dialogue-box lookup used by NPC.gd.
func _find_dialogue_box() -> Node:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		return hud.get_node_or_null("DialogueBox")
	return null


# ─────────────────────────────────────────────────────────────
# DRAWING — simple white dog using Godot 2D draw primitives
# Origin (0,0) is the dog's centre-bottom (feet on ground).
# ─────────────────────────────────────────────────────────────
func _draw() -> void:
	if not visible:
		return
	# World Daisy faces left; groomer items read from GameState.
	DaisyDraw.draw_idle_dog(self, 0.0, 0.0, 1.0, false)
