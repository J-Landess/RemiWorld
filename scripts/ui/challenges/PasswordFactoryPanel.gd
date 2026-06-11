## PasswordFactoryPanel.gd — crack codes and assemble passwords for VIBE pay.
extends Control

@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var payout_label: Label = $Panel/VBoxContainer/PayoutLabel
@onready var question_label: Label = $Panel/VBoxContainer/QuestionLabel
@onready var choices_container: VBoxContainer = $Panel/VBoxContainer/ChoicesContainer
@onready var assembly_row: HBoxContainer = $Panel/VBoxContainer/AssemblyRow
@onready var slots_container: HBoxContainer = $Panel/VBoxContainer/SlotsContainer
@onready var tiles_container: HBoxContainer = $Panel/VBoxContainer/TilesContainer
@onready var feedback_label: Label = $Panel/VBoxContainer/FeedbackLabel
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton

var _puzzle: Dictionary = {}
var _caller: Node = null
var _answered: bool = false
var _choice_buttons: Array[Button] = []
var _slot_labels: Array[Label] = []
var _slot_values: Array = []
var _tile_buttons: Array[Button] = []


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	if close_button:
		close_button.pressed.connect(_on_close_pressed)


func show_challenge(mission_data: Dictionary, caller: Node) -> void:
	_caller = caller
	_puzzle = mission_data.get("puzzle", {})
	_answered = false
	_slot_values.clear()

	var level: int = mission_data.get("level", 0)
	var payout: int = mission_data.get("payout", PasswordPuzzleBank.payout_for_level(level))

	if title_label:
		title_label.text = "🏭  The Password Factory"
	if payout_label:
		payout_label.text = "Shift %d  ·  Pay: +%d VIBE" % [level + 1, payout]
	if question_label:
		question_label.text = _puzzle.get("question", "Crack the code!")
	if feedback_label:
		feedback_label.text = ""
		feedback_label.visible = false

	var mode: String = _puzzle.get("mode", "choice")
	_setup_choice_mode(mode == "choice")
	_setup_assembly_mode(mode == "assembly")

	if close_button:
		close_button.text = "✕  Close"
		close_button.disabled = false

	visible = true


func _setup_choice_mode(active: bool) -> void:
	if choices_container:
		choices_container.visible = active
		for child in choices_container.get_children():
			child.queue_free()
	_choice_buttons.clear()

	if not active:
		return

	var choices: Array = _puzzle.get("choices", [])
	for i in range(choices.size()):
		var btn := Button.new()
		btn.text = "%d)  %s" % [i + 1, choices[i]]
		btn.custom_minimum_size = Vector2(240, 48)
		btn.add_theme_font_size_override("font_size", 17)
		btn.pressed.connect(_on_choice_pressed.bind(i))
		choices_container.add_child(btn)
		_choice_buttons.append(btn)

	await get_tree().process_frame
	if _choice_buttons.size() > 0:
		_choice_buttons[0].grab_focus()


func _setup_assembly_mode(active: bool) -> void:
	if assembly_row:
		assembly_row.visible = active
	if slots_container:
		slots_container.visible = active
	if tiles_container:
		tiles_container.visible = active

	for node in [slots_container, tiles_container]:
		if node:
			for child in node.get_children():
				child.queue_free()

	_slot_labels.clear()
	_tile_buttons.clear()

	if not active:
		return

	var slot_count: int = _puzzle.get("slots", 4)
	_slot_values.resize(slot_count)
	for i in range(slot_count):
		_slot_values[i] = ""
		var slot := Label.new()
		slot.text = "_"
		slot.custom_minimum_size = Vector2(44, 44)
		slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot.add_theme_font_size_override("font_size", 22)
		slot.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
		slots_container.add_child(slot)
		_slot_labels.append(slot)

	var tiles: Array = _puzzle.get("tiles", [])
	for tile in tiles:
		var btn := Button.new()
		btn.text = str(tile)
		btn.custom_minimum_size = Vector2(44, 44)
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(_on_tile_pressed.bind(str(tile), btn))
		tiles_container.add_child(btn)
		_tile_buttons.append(btn)

	var submit := Button.new()
	submit.text = "Stamp Password"
	submit.custom_minimum_size = Vector2(180, 44)
	submit.pressed.connect(_on_assembly_submit)
	tiles_container.add_child(submit)


func _on_tile_pressed(tile_char: String, btn: Button) -> void:
	if _answered:
		return
	for i in range(_slot_values.size()):
		if _slot_values[i] == "":
			_slot_values[i] = tile_char
			_slot_labels[i].text = tile_char
			btn.disabled = true
			return


func _on_assembly_submit() -> void:
	if _answered:
		return
	var built := "".join(_slot_values)
	var answer: String = _puzzle.get("answer", "")
	var correct := built == answer
	_finish_answer(correct, -1 if correct else 0)


func _on_choice_pressed(index: int) -> void:
	if _answered:
		return
	var correct_index: int = _puzzle.get("correct_index", 0)
	_finish_answer(index == correct_index, index)


func _finish_answer(correct: bool, choice_index: int) -> void:
	_answered = true
	AudioManager.play_sfx("correct" if correct else "wrong")

	for btn in _choice_buttons:
		btn.disabled = true
	for btn in _tile_buttons:
		btn.disabled = true

	if feedback_label:
		feedback_label.visible = true
		if correct:
			feedback_label.text = "✅ Password stamped!\n" + _puzzle.get("explanation", "")
			feedback_label.modulate = Color(0.3, 1.0, 0.4)
		else:
			feedback_label.text = "❌ Not quite!\n" + _puzzle.get("hint", "Try again!")
			feedback_label.modulate = Color(1.0, 0.4, 0.4)

	if close_button:
		close_button.text = "✅  Continue"
		close_button.grab_focus()

	await get_tree().create_timer(1.0).timeout
	visible = false
	var hud := get_parent()
	if hud and hud.has_method("close_all_panels"):
		hud.close_all_panels()
	if _caller and _caller.has_method("on_challenge_finished"):
		_caller.on_challenge_finished(correct)
	elif _caller and _caller.has_method("on_puzzle_answered"):
		_caller.on_puzzle_answered(choice_index)


func _on_close_pressed() -> void:
	visible = false
	var hud := get_parent()
	if hud and hud.has_method("close_all_panels"):
		hud.close_all_panels()
	if not _answered and _caller and _caller.has_method("on_challenge_finished"):
		_caller.on_challenge_finished(false)
