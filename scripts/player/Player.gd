## Player.gd
## =============================================================
## Controls the player character in the 2D world.
##
## Movement: WASD / Arrow keys
## Interact:  E  (talk to NPCs)
## Backpack:  B
## Pause:     Esc
##
## The player's visual is an AvatarRenderer child node that draws
## the character built in the AvatarCreation screen.
## =============================================================
extends CharacterBody2D

# ─────────────────────────────────────────────────────────────
# SIGNALS
# ─────────────────────────────────────────────────────────────
signal player_interacted(target: Node)

# ─────────────────────────────────────────────────────────────
# SETTINGS
# ─────────────────────────────────────────────────────────────
@export var move_speed: float = 150.0

# ─────────────────────────────────────────────────────────────
# NODE REFERENCES
# ─────────────────────────────────────────────────────────────
@onready var avatar_renderer: Node2D = $AvatarRenderer
@onready var interact_area: Area2D   = $InteractArea
@onready var interaction_label: Label = $InteractionLabel

# ─────────────────────────────────────────────────────────────
# INTERNAL STATE
# ─────────────────────────────────────────────────────────────
var _nearby_interactable: Node = null
var _can_move: bool = true
var _facing_direction: Vector2 = Vector2.DOWN


# ─────────────────────────────────────────────────────────────
# READY
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	interact_area.body_entered.connect(_on_interactable_entered)
	interact_area.body_exited.connect(_on_interactable_exited)
	interact_area.area_entered.connect(_on_interact_area_entered)
	interact_area.area_exited.connect(_on_interact_area_exited)

	if interaction_label:
		interaction_label.visible = false

	# Load the avatar config into the renderer
	_refresh_avatar()

	# Re-apply if the avatar is updated later (e.g. store purchase)
	AvatarManager.avatar_updated.connect(_on_avatar_updated)

	print("[Player] Player ready!")


# ─────────────────────────────────────────────────────────────
# APPLY AVATAR TO THE RENDERER
# ─────────────────────────────────────────────────────────────
func _refresh_avatar() -> void:
	if avatar_renderer and avatar_renderer.has_method("apply_config"):
		avatar_renderer.apply_config(AvatarManager.get_config())


func _on_avatar_updated(_config: Dictionary) -> void:
	_refresh_avatar()


# ─────────────────────────────────────────────────────────────
# GAME LOOP
# ─────────────────────────────────────────────────────────────
func _physics_process(_delta: float) -> void:
	if not _can_move:
		return
	_handle_movement()
	_handle_input()


# ─────────────────────────────────────────────────────────────
# MOVEMENT
# ─────────────────────────────────────────────────────────────
func _handle_movement() -> void:
	var direction := Vector2.ZERO
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")

	if direction.length() > 1.0:
		direction = direction.normalized()

	velocity = direction * move_speed
	move_and_slide()

	_update_facing(direction)


func _update_facing(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return

	var new_facing: String
	# Prefer vertical facing for up/down movement
	if abs(direction.y) >= abs(direction.x):
		new_facing = "up" if direction.y < 0 else "down"
	else:
		new_facing = "left" if direction.x < 0 else "right"

	_facing_direction = direction

	# Tell the renderer which way to face (affects eye/hair rendering)
	if avatar_renderer and avatar_renderer.has_method("set_facing"):
		avatar_renderer.set_facing(new_facing)


# ─────────────────────────────────────────────────────────────
# INPUT (button presses, not movement)
# ─────────────────────────────────────────────────────────────
func _handle_input() -> void:
	if Input.is_action_just_pressed("interact"):
		_try_interact()
	if Input.is_action_just_pressed("open_backpack"):
		_open_backpack()


# ─────────────────────────────────────────────────────────────
# INTERACTION
# ─────────────────────────────────────────────────────────────
func _try_interact() -> void:
	if _nearby_interactable == null:
		return
	if _nearby_interactable.has_method("on_player_interact"):
		_nearby_interactable.on_player_interact(self)
	emit_signal("player_interacted", _nearby_interactable)


# ─────────────────────────────────────────────────────────────
# BACKPACK
# ─────────────────────────────────────────────────────────────
func _open_backpack() -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("toggle_backpack"):
		hud.toggle_backpack()


# ─────────────────────────────────────────────────────────────
# MOVEMENT CONTROL (disabled during dialogue)
# ─────────────────────────────────────────────────────────────
func set_movement_enabled(enabled: bool) -> void:
	_can_move = enabled
	if not enabled:
		velocity = Vector2.ZERO


# ─────────────────────────────────────────────────────────────
# INTERACTION ZONE
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
# SAVE / LOAD
# ─────────────────────────────────────────────────────────────
func save_position() -> void:
	GameState.player_position = global_position

func load_position() -> void:
	if GameState.player_position != Vector2.ZERO:
		global_position = GameState.player_position
