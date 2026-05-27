## Player.gd
## =============================================================
## Controls the player character in the 2D world.
##
## This script handles:
##   - Moving with WASD / arrow keys
##   - Interacting with NPCs (press E)
##   - Opening the Backpack (press B)
##   - Camera following the player
##   - Detecting nearby NPCs/objects to interact with
##
## Attached to: scenes/player/Player.tscn
## Node type: CharacterBody2D
## =============================================================
extends CharacterBody2D

# ─────────────────────────────────────────────────────────────
# SIGNALS
# ─────────────────────────────────────────────────────────────
signal player_interacted(target: Node)  # Fired when player presses E near something

# ─────────────────────────────────────────────────────────────
# MOVEMENT SETTINGS
# ─────────────────────────────────────────────────────────────
@export var move_speed: float = 150.0  # Pixels per second

# ─────────────────────────────────────────────────────────────
# NODE REFERENCES
# @onready means these variables are set when the scene loads.
# The "$" shorthand finds a child node by name.
# ─────────────────────────────────────────────────────────────
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interact_area: Area2D = $InteractArea
@onready var interaction_label: Label = $InteractionLabel

# ─────────────────────────────────────────────────────────────
# INTERNAL STATE
# ─────────────────────────────────────────────────────────────
var _nearby_interactable: Node = null  # The NPC or object we can interact with
var _can_move: bool = true             # Set to false during dialogue/cutscenes
var _facing_direction: Vector2 = Vector2.DOWN  # Which way the player is facing


# ─────────────────────────────────────────────────────────────
# CALLED ONCE WHEN THE SCENE IS READY
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	# Connect our interact area signals so we know when NPCs are nearby
	interact_area.body_entered.connect(_on_interactable_entered)
	interact_area.body_exited.connect(_on_interactable_exited)
	interact_area.area_entered.connect(_on_interact_area_entered)
	interact_area.area_exited.connect(_on_interact_area_exited)

	# Hide the "Press E to talk" label until something is nearby
	if interaction_label:
		interaction_label.visible = false

	# Start with idle animation
	_play_animation("idle_down")

	print("[Player] Player ready!")


# ─────────────────────────────────────────────────────────────
# CALLED EVERY FRAME — this is the game loop
# "delta" is the time since the last frame (keeps movement smooth)
# ─────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if not _can_move:
		return  # Don't move during dialogue or cutscenes

	_handle_movement()
	_handle_input()


# ─────────────────────────────────────────────────────────────
# MOVEMENT — reads input and moves the player
# ─────────────────────────────────────────────────────────────
func _handle_movement() -> void:
	# Read the input direction using our custom actions (set up in GameState)
	var direction := Vector2.ZERO
	direction.x = Input.get_axis("move_left", "move_right")  # -1, 0, or 1
	direction.y = Input.get_axis("move_up", "move_down")     # -1, 0, or 1

	# Normalize so diagonal movement isn't faster
	if direction.length() > 1.0:
		direction = direction.normalized()

	# Set velocity (Godot's CharacterBody2D uses "velocity" for movement)
	velocity = direction * move_speed

	# Move the character (handles collision automatically!)
	move_and_slide()

	# Update animation based on movement
	_update_animation(direction)


# ─────────────────────────────────────────────────────────────
# INPUT — handles button presses (not movement)
# ─────────────────────────────────────────────────────────────
func _handle_input() -> void:
	# Press E to interact with nearby NPCs/objects
	if Input.is_action_just_pressed("interact"):
		_try_interact()

	# Press B to open the backpack
	if Input.is_action_just_pressed("open_backpack"):
		_open_backpack()


# ─────────────────────────────────────────────────────────────
# ANIMATION — plays the right animation based on movement
# ─────────────────────────────────────────────────────────────
func _update_animation(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		# Player is standing still — play idle animation
		match _facing_direction:
			Vector2.UP:    _play_animation("idle_up")
			Vector2.DOWN:  _play_animation("idle_down")
			Vector2.LEFT:  _play_animation("idle_left")
			Vector2.RIGHT: _play_animation("idle_right")
		return

	# Player is moving — update which way they're facing
	if direction.y < 0:
		_facing_direction = Vector2.UP
		_play_animation("walk_up")
	elif direction.y > 0:
		_facing_direction = Vector2.DOWN
		_play_animation("walk_down")
	elif direction.x < 0:
		_facing_direction = Vector2.LEFT
		_play_animation("walk_left")
	elif direction.x > 0:
		_facing_direction = Vector2.RIGHT
		_play_animation("walk_right")


func _play_animation(anim_name: String) -> void:
	if not sprite:
		return
	# Only switch animation if it's different (prevents restart glitching)
	if sprite.animation != anim_name:
		# If the animation doesn't exist, fall back to a default
		if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
			sprite.play(anim_name)
		elif sprite.sprite_frames and sprite.sprite_frames.has_animation("idle_down"):
			sprite.play("idle_down")


# ─────────────────────────────────────────────────────────────
# INTERACTION — when the player presses E near an NPC
# ─────────────────────────────────────────────────────────────
func _try_interact() -> void:
	if _nearby_interactable == null:
		return

	# Tell the NPC/object that the player interacted with them
	if _nearby_interactable.has_method("on_player_interact"):
		_nearby_interactable.on_player_interact(self)

	emit_signal("player_interacted", _nearby_interactable)


# ─────────────────────────────────────────────────────────────
# BACKPACK
# ─────────────────────────────────────────────────────────────
func _open_backpack() -> void:
	# Find the HUD and tell it to open the backpack
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("toggle_backpack"):
		hud.toggle_backpack()


# ─────────────────────────────────────────────────────────────
# MOVEMENT CONTROL — used by dialogue/cutscene system
# ─────────────────────────────────────────────────────────────
func set_movement_enabled(enabled: bool) -> void:
	_can_move = enabled
	if not enabled:
		velocity = Vector2.ZERO  # Stop moving when disabled


# ─────────────────────────────────────────────────────────────
# INTERACTION ZONE — detects nearby NPCs
# ─────────────────────────────────────────────────────────────
func _on_interactable_entered(body: Node) -> void:
	if body.is_in_group("interactable"):
		_set_nearby_interactable(body)


func _on_interactable_exited(body: Node) -> void:
	if body == _nearby_interactable:
		_clear_nearby_interactable()


func _on_interact_area_entered(area: Area2D) -> void:
	var parent := area.get_parent()
	if parent and parent.is_in_group("interactable"):
		_set_nearby_interactable(parent)


func _on_interact_area_exited(area: Area2D) -> void:
	var parent := area.get_parent()
	if parent == _nearby_interactable:
		_clear_nearby_interactable()


func _set_nearby_interactable(node: Node) -> void:
	_nearby_interactable = node
	if interaction_label:
		interaction_label.visible = true
		interaction_label.text = "[E] Talk" if node.is_in_group("npc") else "[E] Examine"


func _clear_nearby_interactable() -> void:
	_nearby_interactable = null
	if interaction_label:
		interaction_label.visible = false


# ─────────────────────────────────────────────────────────────
# SAVE / LOAD SUPPORT
# ─────────────────────────────────────────────────────────────
func save_position() -> void:
	GameState.player_position = global_position


func load_position() -> void:
	if GameState.player_position != Vector2.ZERO:
		global_position = GameState.player_position
