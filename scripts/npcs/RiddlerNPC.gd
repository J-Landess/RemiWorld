## RiddlerNPC.gd
## =============================================================
## The Riddler — stands guard in front of an animal's cage at
## the aquarium. Blocks entry until the player passes the
## 10-question animal trivia challenge (8/10).
##
## Spawned by AquariumManager with a mission_id and animal_id.
## =============================================================
extends Node2D

const INTERACT_RADIUS: float = 60.0

var mission_id: String = ""
var animal_id: String = ""

var _hud: Node = null
var _mission_data: Dictionary = {}
var _near_player: bool = false
var _hint_label: Label = null
var _interact_area: Area2D = null


func setup(p_mission_id: String, p_animal_id: String, hud: Node) -> void:
	mission_id = p_mission_id
	animal_id = p_animal_id
	_hud = hud
	_mission_data = MissionDatabase.get_mission(mission_id)


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("npc")
	_build_visuals()
	_build_interact_area()


func _build_visuals() -> void:
	# Riddler figure — drawn as a Node2D with custom draw
	var figure := _RiddlerFigure.new()
	add_child(figure)

	# Name label
	var name_lbl := Label.new()
	name_lbl.text = "🎭 The Riddler"
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.position = Vector2(-40, -70)
	name_lbl.modulate = Color(1.0, 0.80, 0.20, 1)
	add_child(name_lbl)

	# Hint label (hidden until nearby)
	_hint_label = Label.new()
	_hint_label.text = "[E] Talk to Riddler"
	_hint_label.add_theme_font_size_override("font_size", 11)
	_hint_label.position = Vector2(-48, -88)
	_hint_label.modulate = Color(1.0, 1.0, 0.4, 1)
	_hint_label.visible = false
	add_child(_hint_label)


func _build_interact_area() -> void:
	_interact_area = Area2D.new()
	_interact_area.collision_layer = 4
	_interact_area.collision_mask = 2

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = INTERACT_RADIUS
	col.shape = shape
	_interact_area.add_child(col)
	add_child(_interact_area)

	_interact_area.body_entered.connect(_on_body_entered)
	_interact_area.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_near_player = true
		if _hint_label:
			_hint_label.visible = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_near_player = false
		if _hint_label:
			_hint_label.visible = false


func _process(_delta: float) -> void:
	if _near_player and Input.is_action_just_pressed("interact"):
		on_player_interact(null)


func on_player_interact(_player: Node) -> void:
	if _mission_data.is_empty():
		_mission_data = MissionDatabase.get_mission(mission_id)

	# Check if VIP is required
	if _mission_data.get("vip_required", false) and not GameState.is_vip:
		_show_vip_block()
		return

	# Check if already freed
	if GameState.aquarium_animals_freed.has(animal_id):
		_show_complete_dialogue()
		return

	var status: String = MissionManager.get_mission_status(mission_id)
	if status == MissionManager.STATUS_COMPLETE:
		_show_complete_dialogue()
		return

	MissionManager.start_mission(mission_id)
	_show_intro_dialogue()


func _show_intro_dialogue() -> void:
	var dialogue_box := _get_dialogue_box()
	if not dialogue_box:
		_present_puzzle()
		return
	var lines: Array = _mission_data.get("dialogue_intro", [])
	dialogue_box.show_dialogue("The Riddler", lines, self)


func _show_complete_dialogue() -> void:
	var dialogue_box := _get_dialogue_box()
	if not dialogue_box:
		return
	var lines: Array = _mission_data.get("dialogue_complete",
		["[The Riddler] You already freed that animal. Impressive… once."])
	dialogue_box.show_dialogue("The Riddler", lines, self)


func _show_vip_block() -> void:
	var dialogue_box := _get_dialogue_box()
	if not dialogue_box:
		return
	var animal_emoji: String = _mission_data.get("animal_emoji", "🐾")
	var lines: Array = [
		"[The Riddler] Ooh, eyeing the %s %s are we? 🎭" % [animal_emoji, _mission_data.get("title", "animal")],
		"[The Riddler] That's the VIP section! You'll need a VIP pass to even attempt THIS rescue.",
		"[The Riddler] Talk to the ticket booth — they offer VIP upgrades.",
	]
	dialogue_box.show_dialogue("The Riddler", lines, self)


func _present_puzzle() -> void:
	if not _hud:
		_hud = get_tree().get_first_node_in_group("hud")
	if _hud and _hud.has_method("show_challenge"):
		_hud.show_challenge("RiddlerPanel", _mission_data, self)


func on_challenge_finished(success: bool) -> void:
	var dialogue_box := _get_dialogue_box()
	if success:
		var lines: Array = _mission_data.get("dialogue_success", ["[The Riddler] You passed! The cage is open!"])
		if dialogue_box:
			dialogue_box.show_dialogue("The Riddler", lines, self)
		# Notify the AquariumManager the quiz was passed
		var manager := get_tree().get_first_node_in_group("aquarium_manager")
		if manager and manager.has_method("on_riddler_passed"):
			manager.on_riddler_passed(animal_id, mission_id)
	else:
		var lines: Array = _mission_data.get("dialogue_failure", ["[The Riddler] Not enough! Try again!"])
		if dialogue_box:
			dialogue_box.show_dialogue("The Riddler", lines, self)


func _get_dialogue_box() -> Node:
	if _hud:
		return _hud.get_node_or_null("DialogueBox")
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		return hud.get_node_or_null("DialogueBox")
	return null


# ── Inner class: procedural Riddler figure ───────────────────────────────────
class _RiddlerFigure extends Node2D:
	func _ready() -> void:
		queue_redraw()

	func _draw() -> void:
		# Shadow
		draw_colored_polygon(
			_ellipse_pts(Vector2(0, 6), 16, 5),
			Color(0.05, 0.05, 0.10, 0.30),
		)
		# Body — purple coat
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(-12, 0), Vector2(12, 0),
				Vector2(10, -36), Vector2(-10, -36),
			]),
			Color(0.45, 0.15, 0.65),
		)
		# Head
		draw_circle(Vector2(0, -46), 12.0, Color(0.88, 0.72, 0.55))
		# Question mark on hat
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(-10, -58), Vector2(10, -58),
				Vector2(8, -74), Vector2(-8, -74),
			]),
			Color(0.25, 0.10, 0.45),
		)
		# Eyes
		draw_circle(Vector2(-4, -48), 2.0, Color(0.15, 0.05, 0.25))
		draw_circle(Vector2(4, -48), 2.0, Color(0.15, 0.05, 0.25))
		# Mischievous smile
		draw_arc(Vector2(0, -43), 5.0, 0.2, PI - 0.2, 8, Color(0.55, 0.25, 0.15), 1.5)
		# Cane
		draw_line(Vector2(13, 0), Vector2(20, -34), Color(0.62, 0.50, 0.20), 2.5)
		draw_circle(Vector2(20, -36), 3.5, Color(0.80, 0.70, 0.25))
		# "?" badge
		draw_circle(Vector2(-2, -18), 6.0, Color(0.95, 0.85, 0.10, 0.85))

	func _ellipse_pts(center: Vector2, rx: float, ry: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		const SEG := 16
		for i in SEG:
			var a := TAU * float(i) / float(SEG)
			pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
		return pts
