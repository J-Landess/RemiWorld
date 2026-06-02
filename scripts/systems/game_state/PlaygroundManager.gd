## PlaygroundManager.gd
## =============================================================
## Manages the Playground/Park level scene.
## Handles: spawning the player, HUD, the 3 challenge NPCs,
## optionally Daisy (if she's already a companion), and the
## exit zone back to the Start Area.
##
## Attached to: scenes/levels/v1_playground/Playground.tscn (root)
## =============================================================
extends Node2D

# ─────────────────────────────────────────────────────────────
# SCENE REFERENCES (preloaded for fast instantiation)
# ─────────────────────────────────────────────────────────────
const PlayerScene     := preload("res://scenes/player/Player.tscn")
const HUDScene        := preload("res://scenes/ui/HUD.tscn")
const ChessTutorScene := preload("res://scenes/npcs/ChessTutor.tscn")
const CoachKickScene  := preload("res://scenes/npcs/CoachKick.tscn")
const ArtistPipScene  := preload("res://scenes/npcs/ArtistPip.tscn")
const DaisyScene      := preload("res://scenes/npcs/DaisyDoodles.tscn")

const START_AREA_PATH := "res://scenes/levels/v1_start_area/StartArea.tscn"

# ─────────────────────────────────────────────────────────────
# INTERNAL REFERENCES
# ─────────────────────────────────────────────────────────────
var _player: Node = null
var _hud: Node = null
var _near_exit: bool = false
var _exit_hint_label: Label = null


func _ready() -> void:
	print("[Playground] Loading Remi's Playground...")
	GameState.current_scene = "res://scenes/levels/v1_playground/Playground.tscn"

	_spawn_hud()
	_spawn_player()
	_spawn_npcs()
	_spawn_daisy_if_companion()
	_setup_exit_zone()
	_setup_checkpoint_zone()

	print("[Playground] Playground ready!")


# ─────────────────────────────────────────────────────────────
# PROCESS — E-key to exit back to Start Area
# ─────────────────────────────────────────────────────────────
func _process(_delta: float) -> void:
	if _near_exit and Input.is_action_just_pressed("interact"):
		_exit_to_start_area()


# ─────────────────────────────────────────────────────────────
# SPAWN HUD + PLAYER
# ─────────────────────────────────────────────────────────────
func _spawn_hud() -> void:
	_hud = HUDScene.instantiate()
	add_child(_hud)


func _spawn_player() -> void:
	_player = PlayerScene.instantiate()
	var sort_layer := get_node_or_null("SortLayer")
	if sort_layer:
		sort_layer.add_child(_player)
	else:
		add_child(_player)

	var spawn_point := get_node_or_null("PlayerSpawn")
	if spawn_point:
		_player.global_position = spawn_point.global_position
	else:
		_player.global_position = Vector2(0, 320)
	print("[Playground] Player spawned at: ", _player.global_position)


# ─────────────────────────────────────────────────────────────
# SPAWN THE CHALLENGE NPCS
# ─────────────────────────────────────────────────────────────
func _spawn_npcs() -> void:
	var npc_parent := get_node_or_null("SortLayer/NPCs")
	if not npc_parent:
		push_warning("[Playground] NPCs container not found.")
		return

	_spawn_npc_at(npc_parent, ChessTutorScene, "Zones/ChessMarker", "ChessTutor")
	_spawn_npc_at(npc_parent, CoachKickScene,  "Zones/SoccerMarker", "CoachKick")
	_spawn_npc_at(npc_parent, ArtistPipScene,  "Zones/ArtMarker", "ArtistPip")


func _spawn_npc_at(parent: Node, scene: PackedScene, marker_path: String, label: String) -> void:
	var marker := get_node_or_null(marker_path)
	if not marker:
		push_warning("[Playground] Missing marker: %s" % marker_path)
		return
	var npc := scene.instantiate()
	npc.global_position = marker.global_position
	parent.add_child(npc)
	print("[Playground] %s spawned at %s" % [label, npc.global_position])


# ─────────────────────────────────────────────────────────────
# SPAWN DAISY (only if already a companion)
# Players who haven't found Daisy yet won't see her here —
# they have to go catch her in the Start Area first.
# ─────────────────────────────────────────────────────────────
func _spawn_daisy_if_companion() -> void:
	if not GameState.daisy_captured:
		# Add a hint label instead
		var hint := Label.new()
		hint.text = "Find Daisy first..."
		hint.position = Vector2(440, 220)
		hint.add_theme_font_size_override("font_size", 11)
		hint.modulate = Color(0.4, 0.3, 0.2, 0.7)
		add_child(hint)
		return

	var marker := get_node_or_null("Zones/DaisyMarker")
	if not marker:
		return
	var daisy := DaisyScene.instantiate()
	daisy.global_position = marker.global_position
	var sort_layer := get_node_or_null("SortLayer")
	if sort_layer:
		sort_layer.add_child(daisy)
	else:
		add_child(daisy)
	print("[Playground] Daisy spawned at her fetch spot.")


# ─────────────────────────────────────────────────────────────
# EXIT ZONE — at the bottom of the scene; press E to leave
# ─────────────────────────────────────────────────────────────
func _setup_exit_zone() -> void:
	var exit := Area2D.new()
	exit.name = "ExitZone"
	exit.collision_layer = 4
	exit.collision_mask = 2

	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(120, 40)
	shape_node.shape = shape
	exit.add_child(shape_node)
	exit.global_position = Vector2(0, 420)
	add_child(exit)

	exit.body_entered.connect(_on_exit_entered)
	exit.body_exited.connect(_on_exit_exited)

	var arrow := Label.new()
	arrow.text = "🚪"
	arrow.position = Vector2(-10, -16)
	arrow.add_theme_font_size_override("font_size", 26)
	exit.add_child(arrow)

	var hint := Label.new()
	hint.text = "[E] Leave Playground"
	hint.position = Vector2(-66, -42)
	hint.add_theme_font_size_override("font_size", 12)
	hint.modulate = Color(1, 1, 0.4, 1)
	hint.visible = false
	exit.add_child(hint)
	_exit_hint_label = hint


func _on_exit_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_near_exit = true
		if _exit_hint_label:
			_exit_hint_label.visible = true


func _on_exit_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_near_exit = false
		if _exit_hint_label:
			_exit_hint_label.visible = false


func _exit_to_start_area() -> void:
	if _player:
		GameState.player_position = Vector2.ZERO   # Let Start Area use its own spawn
	get_tree().change_scene_to_file(START_AREA_PATH)


# ─────────────────────────────────────────────────────────────
# CHECKPOINT — take one when entering the playground
# ─────────────────────────────────────────────────────────────
func _setup_checkpoint_zone() -> void:
	var spawn := get_node_or_null("PlayerSpawn")
	var pos: Vector2 = spawn.global_position if spawn else Vector2(0, 320)
	CheckpointManager.save_checkpoint(pos)


# ─────────────────────────────────────────────────────────────
# AUTO-SAVE WHEN EXITING THE SCENE
# ─────────────────────────────────────────────────────────────
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		if _player:
			GameState.player_position = _player.global_position
		SaveManager.save_game()
