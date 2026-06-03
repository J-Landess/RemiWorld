## DogFightingPitManager.gd
## =============================================================
## Manages Daisy's Dog Pit level.
## =============================================================
extends Node2D

const PlayerScene     := preload("res://scenes/player/Player.tscn")
const HUDScene        := preload("res://scenes/ui/HUD.tscn")
const PitBossScene    := preload("res://scenes/npcs/PitBossMara.tscn")
const DaisyScene      := preload("res://scenes/npcs/DaisyDoodles.tscn")
const CourseCoachScene := preload("res://scenes/npcs/CourseCoach.tscn")
const GroomerScene    := preload("res://scenes/npcs/GroomerGreta.tscn")

const PLAYGROUND_PATH := "res://scenes/levels/v1_playground/Playground.tscn"

var _player: Node = null
var _near_exit: bool = false
var _exit_hint_label: Label = null


func _ready() -> void:
	get_tree().paused = false   # Safety: ensure no paused state leaks from previous scene
	GameState.current_scene = "res://scenes/levels/v1_dog_fighting_pit/DogFightingPit.tscn"
	_spawn_hud()
	_spawn_player()
	_spawn_pit_npcs()
	_setup_exit_zone()
	_setup_checkpoint_zone()


func _process(_delta: float) -> void:
	if _near_exit and Input.is_action_just_pressed("interact"):
		_exit_to_playground()


func _spawn_hud() -> void:
	add_child(HUDScene.instantiate())


func _spawn_player() -> void:
	_player = PlayerScene.instantiate()
	var sort_layer := get_node_or_null("SortLayer")
	if sort_layer:
		sort_layer.add_child(_player)
	else:
		add_child(_player)

	var spawn_point := get_node_or_null("PlayerSpawn")
	_player.global_position = spawn_point.global_position if spawn_point else Vector2(0, 280)


func _spawn_pit_npcs() -> void:
	var npc_parent := get_node_or_null("SortLayer/NPCs")
	if not npc_parent:
		return

	var pit_marker := get_node_or_null("Zones/PitBossMarker")
	if pit_marker:
		var pit_boss := PitBossScene.instantiate()
		pit_boss.global_position = pit_marker.global_position
		npc_parent.add_child(pit_boss)

	if GameState.daisy_captured:
		var daisy_marker := get_node_or_null("Zones/DaisyMarker")
		if daisy_marker:
			var daisy := DaisyScene.instantiate()
			daisy.global_position = daisy_marker.global_position
			npc_parent.add_child(daisy)

	var course_marker := get_node_or_null("Zones/CourseMarker")
	if course_marker:
		var coach := CourseCoachScene.instantiate()
		coach.global_position = course_marker.global_position
		npc_parent.add_child(coach)

	var groomer_marker := get_node_or_null("Zones/GroomerMarker")
	if groomer_marker:
		var groomer := GroomerScene.instantiate()
		groomer.global_position = groomer_marker.global_position
		npc_parent.add_child(groomer)


func _setup_exit_zone() -> void:
	var exit := Area2D.new()
	exit.name = "ExitZone"
	exit.collision_layer = 4
	exit.collision_mask = 2

	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(130, 45)
	shape_node.shape = shape
	exit.add_child(shape_node)
	exit.global_position = Vector2(0, 380)
	add_child(exit)

	exit.body_entered.connect(_on_exit_entered)
	exit.body_exited.connect(_on_exit_exited)

	var hint := Label.new()
	hint.text = "[E] Leave Dog Pit"
	hint.position = Vector2(-64, -34)
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


func _exit_to_playground() -> void:
	if _player:
		GameState.player_position = Vector2.ZERO
	get_tree().change_scene_to_file(PLAYGROUND_PATH)


func _setup_checkpoint_zone() -> void:
	var spawn := get_node_or_null("PlayerSpawn")
	var pos: Vector2 = spawn.global_position if spawn else Vector2(0, 280)
	CheckpointManager.save_checkpoint(pos)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		if _player:
			GameState.player_position = _player.global_position
		SaveManager.save_game()
