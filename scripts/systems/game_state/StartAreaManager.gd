## StartAreaManager.gd
## =============================================================
## Manages the Start Area level scene.
## Handles: spawning the player, loading NPCs, connecting the HUD,
## spawning Daisy Doodles near the flower patch, creating the
## school entrance trigger, adding checkpoint zones, and
## auto-saving position when the player exits.
##
## Attached to: scenes/levels/v1_start_area/StartArea.tscn (root node)
## =============================================================
extends Node2D

# ─────────────────────────────────────────────────────────────
# SCENE REFERENCES (preloaded for fast instantiation)
# ─────────────────────────────────────────────────────────────
const PlayerScene    := preload("res://scenes/player/Player.tscn")
const CodingBotScene := preload("res://scenes/npcs/CodingBot.tscn")
const RoseScene      := preload("res://scenes/npcs/ShopkeeperRose.tscn")
const HUDScene       := preload("res://scenes/ui/HUD.tscn")
const DaisyScene     := preload("res://scenes/npcs/DaisyDoodles.tscn")

# ─────────────────────────────────────────────────────────────
# INTERNAL REFERENCES
# ─────────────────────────────────────────────────────────────
var _player: Node = null
var _hud: Node = null

# School entrance interaction state
var _near_school: bool = false
var _school_hint_label: Label = null

# Daisy companion follow-slot (set after she's caught)
var _daisy_node: Node = null


# ─────────────────────────────────────────────────────────────
# CALLED WHEN THE LEVEL LOADS
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	print("[StartArea] Loading Remi's Start Area...")
	GameState.current_scene = "res://scenes/levels/v1_start_area/StartArea.tscn"

	_spawn_hud()
	_spawn_player()
	_spawn_npcs()
	_spawn_daisy()
	_setup_school_entrance()
	_setup_checkpoint_zones()

	print("[StartArea] Start Area ready! Welcome, %s!" % GameState.player_name)


# ─────────────────────────────────────────────────────────────
# PROCESS — E-key to enter school when near the entrance
# ─────────────────────────────────────────────────────────────
func _process(_delta: float) -> void:
	if _near_school and Input.is_action_just_pressed("interact"):
		_enter_school()


# ─────────────────────────────────────────────────────────────
# SPAWN THE HUD
# ─────────────────────────────────────────────────────────────
func _spawn_hud() -> void:
	_hud = HUDScene.instantiate()
	add_child(_hud)
	print("[StartArea] HUD spawned.")


# ─────────────────────────────────────────────────────────────
# SPAWN THE PLAYER
# ─────────────────────────────────────────────────────────────
func _spawn_player() -> void:
	_player = PlayerScene.instantiate()
	add_child(_player)

	var spawn_point := get_node_or_null("PlayerSpawn")
	if spawn_point:
		if GameState.player_position != Vector2.ZERO:
			_player.global_position = GameState.player_position
		else:
			_player.global_position = spawn_point.global_position
	else:
		_player.global_position = Vector2(0, 100)

	print("[StartArea] Player spawned at: ", _player.global_position)


# ─────────────────────────────────────────────────────────────
# SPAWN NPCs WITH THEIR SCRIPTS
# ─────────────────────────────────────────────────────────────
func _spawn_npcs() -> void:
	# Coding Bot — positioned left of centre
	var coding_bot_node := get_node_or_null("NPCs/CodingBot")
	if coding_bot_node:
		var bot_scene := CodingBotScene.instantiate()
		var bot_pos: Vector2 = coding_bot_node.global_position
		coding_bot_node.queue_free()
		bot_scene.global_position = bot_pos
		get_node("NPCs").add_child(bot_scene)
		print("[StartArea] Coding Bot spawned at: ", bot_pos)

	# Shopkeeper Rose — positioned right of centre
	var rose_node := get_node_or_null("NPCs/ShopkeeperRose")
	if rose_node:
		var rose_scene := RoseScene.instantiate()
		var rose_pos: Vector2 = rose_node.global_position
		rose_node.queue_free()
		rose_scene.global_position = rose_pos
		get_node("NPCs").add_child(rose_scene)
		print("[StartArea] Shopkeeper Rose spawned at: ", rose_pos)


# ─────────────────────────────────────────────────────────────
# SPAWN DAISY DOODLES near the flower patch
# ─────────────────────────────────────────────────────────────
func _spawn_daisy() -> void:
	# The flower patch label is at (200, 100) in the .tscn.
	# Spawn Daisy there; her HIDING state keeps her invisible until
	# the player walks close enough.
	_daisy_node = DaisyScene.instantiate()
	_daisy_node.global_position = Vector2(210, 110)
	add_child(_daisy_node)
	print("[StartArea] Daisy Doodles spawned near the flower patch.")


# ─────────────────────────────────────────────────────────────
# SCHOOL ENTRANCE — Area2D created in code near the school door
# School building is at (-300, -440), size 200×180, so the door
# is at roughly the bottom-centre: (-200, -265).
# ─────────────────────────────────────────────────────────────
func _setup_school_entrance() -> void:
	var entrance := Area2D.new()
	entrance.name = "SchoolEntranceZone"
	entrance.collision_layer = 4
	entrance.collision_mask = 2   # Detects player layer

	var shape_node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 52.0
	shape_node.shape = shape
	entrance.add_child(shape_node)
	entrance.global_position = Vector2(-200, -268)
	add_child(entrance)

	entrance.body_entered.connect(_on_school_entered)
	entrance.body_exited.connect(_on_school_exited)

	# "Enter School" label — hidden until player is nearby
	var hint := Label.new()
	hint.text = "[E] Enter School"
	hint.position = Vector2(-56, -40)
	hint.add_theme_font_size_override("font_size", 12)
	hint.modulate = Color(1.0, 1.0, 0.4, 1.0)
	hint.visible = false
	entrance.add_child(hint)
	_school_hint_label = hint


func _on_school_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_near_school = true
		if _school_hint_label:
			_school_hint_label.visible = true


func _on_school_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_near_school = false
		if _school_hint_label:
			_school_hint_label.visible = false


func _enter_school() -> void:
	# Save a checkpoint just before entering the school
	if _player:
		CheckpointManager.save_checkpoint(_player.global_position)
		GameState.player_position = Vector2.ZERO   # Reset so school uses its own spawn
	get_tree().change_scene_to_file("res://scenes/levels/v1_school_interior/SchoolInterior.tscn")


# ─────────────────────────────────────────────────────────────
# CHECKPOINT ZONES — invisible Area2D triggers at key spots
# ─────────────────────────────────────────────────────────────
func _setup_checkpoint_zones() -> void:
	# Zone 1: near the player spawn (always first checkpoint)
	_make_checkpoint_zone(Vector2(0, 100), "spawn")

	# Zone 2: near the school entrance
	_make_checkpoint_zone(Vector2(-200, -200), "school_entrance")

	# Zone 3: near the flower patch (Daisy's territory)
	_make_checkpoint_zone(Vector2(200, 50), "flower_patch")

	# Take the very first checkpoint right now at spawn
	var spawn := get_node_or_null("PlayerSpawn")
	var initial_pos: Vector2 = spawn.global_position if spawn else Vector2(0, 100)
	CheckpointManager.save_checkpoint(initial_pos)


func _make_checkpoint_zone(world_pos: Vector2, zone_name: String) -> void:
	var area := Area2D.new()
	area.name = "CheckpointZone_" + zone_name
	area.collision_layer = 0
	area.collision_mask = 2   # Detects player

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 55.0
	col.shape = shape
	area.add_child(col)
	area.global_position = world_pos
	add_child(area)

	# Use a lambda so each zone captures its own world_pos
	area.body_entered.connect(func(body: Node) -> void:
		if body.is_in_group("player"):
			CheckpointManager.save_checkpoint(world_pos)
			if _hud and _hud.has_method("show_notification"):
				_hud.show_notification("✅ Checkpoint!")
	)


# ─────────────────────────────────────────────────────────────
# AUTO-SAVE WHEN EXITING THE SCENE
# ─────────────────────────────────────────────────────────────
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		if _player:
			GameState.player_position = _player.global_position
		SaveManager.save_game()
