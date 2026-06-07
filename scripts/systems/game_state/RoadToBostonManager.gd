## RoadToBostonManager.gd — timed journey to meet Zia in Boston.
extends Node2D

const PlayerScene := preload("res://scenes/player/Player.tscn")
const HUDScene := preload("res://scenes/ui/HUD.tscn")
const DaisyScene := preload("res://scenes/npcs/DaisyDoodles.tscn")
const ZiaScene := preload("res://scenes/npcs/ZiaWitch.tscn")
const PLAYGROUND_PATH := "res://scenes/levels/v1_playground/Playground.tscn"

const JOURNEY_TIME: float = 480.0  # 8 minutes to reach Zia

# Milestone index must match GameState.road_milestone when player may interact.
const MILESTONES: Array = [
	{
		"name": "Fallen Oak",
		"pos": Vector2(-950, 70),
		"lines": [
			"[Road] A huge oak blocks the path!",
			"[Road] You and Daisy push together — CRACK — the way is clear.",
		],
	},
	{
		"name": "River Crossing",
		"pos": Vector2(-450, 70),
		"lines": [
			"[Ferry Kid] Need to cross? Answer quick: 5 + 7 = ?",
			"[Ferry Kid] Twelve! Hop on the stones — splash — you made it!",
		],
	},
	{
		"name": "Traveler",
		"pos": Vector2(50, 70),
		"lines": [
			"[Traveler] Boston-bound? Zia's cottage is past the hill.",
			"[Traveler] She's a witch, but she loves kids. Just don't sass her!",
		],
	},
	{
		"name": "Sassy Kid",
		"pos": Vector2(550, 70),
		"lines": [
			"[Kid] *mumbles* witches are so lame...",
			"[Kid] Hey! Why am I only saying sassy things?!",
			"[Road] (Zia's magic is real — you hurry along.)",
		],
	},
	{
		"name": "Storm",
		"pos": Vector2(1050, 70),
		"lines": [
			"[Road] Thunder rolls! You wait under a tarp with Daisy...",
			"[Road] The storm passes. Boston smells like chowder ahead!",
		],
	},
]

# Gate X positions — wall drops when milestone index reaches gate_index + 1
const GATE_X: Array = [Vector2(-700, 70), Vector2(-250, 70), Vector2(300, 70), Vector2(800, 70)]

var _player: Node = null
var _hud: Node = null
var _timer_label: Label = null
var _hint_label: Label = null
var _near_milestone: int = -1
var _near_exit: bool = false
var _exit_hint: Label = null
var _gates: Array[StaticBody2D] = []
var _milestone_hints: Array[Label] = []
var _talking: bool = false
var _failed: bool = false


func _ready() -> void:
	get_tree().paused = false
	GameState.current_scene = "res://scenes/levels/v1_road_to_boston/RoadToBoston.tscn"

	if not GameState.road_journey_active:
		GameState.start_road_journey(JOURNEY_TIME)

	_spawn_hud()
	_spawn_player()
	_spawn_daisy()
	_spawn_zia()
	_build_road_visuals()
	_setup_gates()
	_setup_milestone_zones()
	_setup_exit_zone()
	_setup_timer_ui()
	_update_timer_label()
	AudioManager.play_music("playground")
	_show_intro_toast()


func _show_intro_toast() -> void:
	if _hud and _hud.has_method("show_notification"):
		_hud.show_notification("🛣️ Reach Zia in Boston before time runs out! Be polite — she's a witch!")


func _process(delta: float) -> void:
	if _failed or not GameState.road_journey_active:
		return

	GameState.road_time_remaining = maxf(GameState.road_time_remaining - delta, 0.0)
	_update_timer_label()

	if GameState.road_time_remaining <= 0.0:
		_on_time_up()

	if _near_exit and Input.is_action_just_pressed("interact"):
		_abandon_journey()

	if _near_milestone >= 0 and Input.is_action_just_pressed("interact"):
		_try_milestone(_near_milestone)


func _on_time_up() -> void:
	if _failed:
		return
	_failed = true
	GameState.apply_zia_curse()
	if _player and _player.has_method("_refresh_avatar"):
		_player._refresh_avatar()
	for d in get_tree().get_nodes_in_group("daisy"):
		if d.has_method("queue_redraw"):
			d.queue_redraw()
	AudioManager.play_sfx("wrong")
	if _hud and _hud.has_method("show_notification"):
		_hud.show_notification("⏰ Too late! Zia's curse: Daisy is a frog and your hair fell out!")
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file(PLAYGROUND_PATH)


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
	var spawn := get_node_or_null("PlayerSpawn")
	_player.global_position = spawn.global_position if spawn else Vector2(-1200, 70)
	if GameState.remi_bald and _player.has_method("_refresh_avatar"):
		_player._refresh_avatar()


func _spawn_daisy() -> void:
	if not GameState.daisy_captured:
		return
	var marker := get_node_or_null("Zones/DaisyMarker")
	if not marker:
		return
	var parent := get_node_or_null("SortLayer/NPCs")
	if not parent:
		return
	var daisy := DaisyScene.instantiate()
	daisy.global_position = marker.global_position
	parent.add_child(daisy)


func _spawn_zia() -> void:
	var marker := get_node_or_null("Zones/ZiaMarker")
	if not marker:
		return
	var parent := get_node_or_null("SortLayer/NPCs")
	if not parent:
		return
	var zia := ZiaScene.instantiate()
	zia.global_position = marker.global_position
	parent.add_child(zia)


func _build_road_visuals() -> void:
	var road := ColorRect.new()
	road.color = Color(0.45, 0.42, 0.38)
	road.position = Vector2(-1300, 40)
	road.size = Vector2(2800, 55)
	road.z_index = -40
	add_child(road)
	var line := ColorRect.new()
	line.color = Color(0.92, 0.88, 0.5, 0.5)
	line.position = Vector2(-1300, 64)
	line.size = Vector2(2800, 4)
	line.z_index = -39
	add_child(line)
	var sign := Label.new()
	sign.text = "🛣️ Road to Boston  →"
	sign.position = Vector2(-1180, -30)
	sign.add_theme_font_size_override("font_size", 18)
	sign.modulate = Color(0.35, 0.22, 0.55)
	add_child(sign)
	var end_sign := Label.new()
	end_sign.text = "🏠 Zia's Cottage"
	end_sign.position = Vector2(1280, -30)
	end_sign.add_theme_font_size_override("font_size", 18)
	end_sign.modulate = Color(0.55, 0.25, 0.65)
	add_child(end_sign)


func _setup_gates() -> void:
	for gx: Vector2 in GATE_X:
		var wall := StaticBody2D.new()
		wall.collision_layer = 1
		wall.collision_mask = 0
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(24, 120)
		col.shape = shape
		wall.add_child(col)
		wall.global_position = gx
		add_child(wall)
		_gates.append(wall)
	_refresh_gates()


func _refresh_gates() -> void:
	for i in range(_gates.size()):
		_gates[i].set_deferred("collision_layer", 0 if i < GameState.road_milestone else 1)


func _setup_milestone_zones() -> void:
	for i in range(MILESTONES.size()):
		var data: Dictionary = MILESTONES[i]
		var area := Area2D.new()
		area.name = "Milestone_%d" % i
		area.collision_layer = 4
		area.collision_mask = 2
		var col := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 55.0
		col.shape = shape
		area.add_child(col)
		area.global_position = data.pos
		add_child(area)
		var idx: int = i
		area.body_entered.connect(func(body: Node) -> void:
			if body.is_in_group("player"):
				_on_milestone_entered(idx)
		)
		area.body_exited.connect(func(body: Node) -> void:
			if body.is_in_group("player"):
				_on_milestone_exited(idx)
		)
		var hint := Label.new()
		hint.text = "❗ %s" % data.name
		hint.position = Vector2(-40, -50)
		hint.add_theme_font_size_override("font_size", 11)
		hint.visible = false
		area.add_child(hint)
		_milestone_hints.append(hint)


func _on_milestone_entered(idx: int) -> void:
	if idx != GameState.road_milestone or _talking:
		return
	_near_milestone = idx
	if idx < _milestone_hints.size():
		_milestone_hints[idx].text = "[E] %s" % MILESTONES[idx].name
		_milestone_hints[idx].visible = true


func _on_milestone_exited(idx: int) -> void:
	if _near_milestone == idx:
		_near_milestone = -1
	if idx < _milestone_hints.size():
		_milestone_hints[idx].visible = false


func _try_milestone(idx: int) -> void:
	if idx != GameState.road_milestone or _talking:
		return
	_talking = true
	var lines: Array = MILESTONES[idx].lines
	var box := _get_dialogue_box()
	if box:
		box.show_dialogue(MILESTONES[idx].name, lines, self)
	else:
		on_dialogue_finished()


func _complete_milestone() -> void:
	GameState.road_milestone += 1
	_refresh_gates()
	_talking = false
	_near_milestone = -1
	SaveManager.save_game()
	if _hud and _hud.has_method("show_notification"):
		_hud.show_notification("✅ Milestone cleared! (%d/%d)" % [
			GameState.road_milestone, MILESTONES.size()
		])


func on_dialogue_finished() -> void:
	_complete_milestone()


func _setup_exit_zone() -> void:
	var exit := Area2D.new()
	exit.collision_layer = 4
	exit.collision_mask = 2
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 50.0
	col.shape = shape
	exit.add_child(col)
	exit.global_position = Vector2(-1250, 150)
	add_child(exit)
	exit.body_entered.connect(func(body: Node) -> void:
		if body.is_in_group("player"):
			_near_exit = true
			if _exit_hint:
				_exit_hint.visible = true
	)
	exit.body_exited.connect(func(body: Node) -> void:
		if body.is_in_group("player"):
			_near_exit = false
			if _exit_hint:
				_exit_hint.visible = false
	)
	_exit_hint = Label.new()
	_exit_hint.text = "[E] Turn back (abandon)"
	_exit_hint.position = Vector2(-1250, 110)
	_exit_hint.add_theme_font_size_override("font_size", 11)
	_exit_hint.visible = false
	add_child(_exit_hint)


func _abandon_journey() -> void:
	GameState.road_journey_active = false
	get_tree().change_scene_to_file(PLAYGROUND_PATH)


func _setup_timer_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_timer_label = Label.new()
	_timer_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_timer_label.offset_top = 52
	_timer_label.offset_left = -200
	_timer_label.offset_right = 200
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.add_theme_font_size_override("font_size", 22)
	_timer_label.modulate = Color(1, 0.92, 0.55)
	layer.add_child(_timer_label)
	_hint_label = Label.new()
	_hint_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_hint_label.offset_top = 78
	_hint_label.offset_left = -280
	_hint_label.offset_right = 280
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.text = "Milestones: %d / %d  ·  Find Zia!" % [GameState.road_milestone, MILESTONES.size()]
	_hint_label.add_theme_font_size_override("font_size", 13)
	layer.add_child(_hint_label)


func _update_timer_label() -> void:
	if not _timer_label:
		return
	var t: float = GameState.road_time_remaining
	var total_secs: int = int(t)
	var mins: int = total_secs / 60
	var secs: int = total_secs % 60
	_timer_label.text = "⏱️ Boston: %d:%02d" % [mins, secs]
	if t < 60.0:
		_timer_label.modulate = Color(1, 0.35, 0.35)
	else:
		_timer_label.modulate = Color(1, 0.92, 0.55)
	if _hint_label:
		_hint_label.text = "Milestones: %d / %d  ·  Be kind to Zia!" % [
			GameState.road_milestone, MILESTONES.size()
		]


func _get_dialogue_box() -> Node:
	if _hud:
		return _hud.get_node_or_null("DialogueBox")
	return null


func journey_succeeded() -> void:
	_failed = true
	GameState.clear_road_journey()
	GameState.zia_curse_active = false
	GameState.daisy_is_frog = false
	GameState.remi_bald = false
