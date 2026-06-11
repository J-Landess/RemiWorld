## DialogueBox.gd — NPC dialogue with typewriter, colors, and optional questions.
extends Control

signal dialogue_finished(caller: Node)
signal all_lines_shown()

@onready var panel: PanelContainer = $Panel
@onready var accent_strip: ColorRect = $Panel/VBoxContainer/AccentStrip
@onready var speaker_label: Label = $Panel/VBoxContainer/SpeakerLabel
@onready var text_label: RichTextLabel = $Panel/VBoxContainer/TextLabel
@onready var choices_container: HBoxContainer = $Panel/VBoxContainer/ChoicesContainer
@onready var continue_label: Label = $Panel/VBoxContainer/ContinueLabel

var _lines: Array = []
var _current_line: int = 0
var _caller: Node = null
var _show_puzzle_after: bool = false
var _open_store_after: bool = false
var _is_typing: bool = false
var _full_text: String = ""
var _type_timer: float = 0.0
var _speaker_color: Color = Color(1.0, 0.9, 0.3)
var _waiting_for_choice: bool = false


func _ready() -> void:
	_apply_dialogue_theme()
	if choices_container:
		choices_container.visible = false


func _apply_dialogue_theme() -> void:
	var sys := SystemFont.new()
	sys.font_names = PackedStringArray([
		"Chalkboard SE", "Comic Sans MS", "Arial Rounded MT Bold",
		"Marker Felt", "Helvetica Neue", "Arial",
	])
	sys.font_weight = 600

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.1, 0.16, 0.92)
	panel_style.border_color = Color(0.35, 0.45, 0.65, 0.85)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(14)
	panel_style.content_margin_left = 18
	panel_style.content_margin_right = 18
	panel_style.content_margin_top = 12
	panel_style.content_margin_bottom = 14
	if panel:
		panel.add_theme_stylebox_override("panel", panel_style)

	if speaker_label:
		speaker_label.add_theme_font_override("font", sys)
		speaker_label.add_theme_font_size_override("font_size", 32)
	if text_label:
		text_label.add_theme_font_override("normal_font", sys)
		text_label.add_theme_font_size_override("normal_font_size", 26)
	if continue_label:
		continue_label.add_theme_font_override("font", sys)
		continue_label.add_theme_font_size_override("font_size", 16)


func show_dialogue(
	speaker: String,
	lines: Array,
	caller: Node = null,
	show_puzzle_after: bool = false,
	open_store_after: bool = false,
	npc_id: String = "",
) -> void:
	if lines.is_empty():
		return

	var resolved_id := npc_id
	if resolved_id.is_empty() and caller and caller.get("npc_id"):
		resolved_id = str(caller.npc_id)

	_lines = lines
	_current_line = 0
	_caller = caller
	_show_puzzle_after = show_puzzle_after
	_open_store_after = open_store_after
	_speaker_color = NpcDialogueColors.get_color(resolved_id, speaker)
	_waiting_for_choice = false

	if speaker_label:
		speaker_label.text = speaker
		speaker_label.modulate = _speaker_color
	if accent_strip:
		accent_strip.color = _speaker_color

	_set_caller_talking(true)
	_set_player_movement_enabled(false)

	visible = true
	_show_current_line()


func _colorize_text(text: String) -> String:
	var hex := NpcDialogueColors.to_bbcode(_speaker_color)
	return "[color=%s]%s[/color]" % [hex, text]


func _show_current_line() -> void:
	_clear_choices()
	_waiting_for_choice = false

	if _current_line >= _lines.size():
		_finish_dialogue()
		return

	var line_data = _lines[_current_line]

	if line_data is Dictionary:
		var line_type: String = line_data.get("type", "")
		if line_type == "question":
			_show_question(line_data)
			return
		if line_type == "action":
			if line_data.get("action") == "present_puzzle" and _caller and _caller.has_method("_present_puzzle"):
				var caller := _caller
				_finish_dialogue()
				caller.call_deferred("_present_puzzle")
			else:
				_finish_dialogue()
			return

	var line := str(line_data)
	if "]" in line:
		var parts := line.split("] ", true, 1)
		if parts.size() > 1:
			line = parts[1]

	_full_text = line
	_is_typing = true
	_type_timer = 0.0

	if text_label:
		text_label.text = ""
	if continue_label:
		continue_label.visible = false


func _show_question(q: Dictionary) -> void:
	_is_typing = false
	_waiting_for_choice = true
	_full_text = str(q.get("text", ""))

	if text_label:
		text_label.text = _colorize_text(_full_text)
	if continue_label:
		continue_label.visible = false

	var choices: Array = q.get("choices", [])
	if choices.is_empty() or not choices_container:
		return

	for child in choices_container.get_children():
		child.queue_free()

	for i in range(choices.size()):
		var btn := Button.new()
		btn.text = str(choices[i])
		btn.custom_minimum_size = Vector2(180, 44)
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(_on_question_choice.bind(i, q))
		choices_container.add_child(btn)

	choices_container.visible = true


func _on_question_choice(index: int, q: Dictionary) -> void:
	if not _waiting_for_choice:
		return

	AudioManager.play_sfx("dialogue_blip", 0.1)
	_waiting_for_choice = false
	_clear_choices()

	var responses: Array = q.get("responses", [])
	if index < responses.size():
		var branch: Array = responses[index]
		for i in range(branch.size() - 1, -1, -1):
			_lines.insert(_current_line + 1, branch[i])

	_current_line += 1
	_show_current_line()


func _clear_choices() -> void:
	if not choices_container:
		return
	for child in choices_container.get_children():
		child.queue_free()
	choices_container.visible = false


func _process(delta: float) -> void:
	if not visible or not _is_typing or _waiting_for_choice:
		return

	_type_timer += delta
	var char_speed: float = GameState.text_speed
	var chars_to_show: int = int(_type_timer / char_speed)
	chars_to_show = mini(chars_to_show, _full_text.length())

	if text_label:
		text_label.text = _colorize_text(_full_text.left(chars_to_show))

	if chars_to_show >= _full_text.length():
		_is_typing = false
		if continue_label:
			var is_last_line := (_current_line >= _lines.size() - 1)
			continue_label.text = (
				"[ Press Space or Click to continue ]"
				if not is_last_line
				else "[ Press Space or Click to close ]"
			)
			continue_label.visible = true


func _input(event: InputEvent) -> void:
	if not visible or _waiting_for_choice:
		return

	var advance := false
	if event is InputEventKey and event.pressed:
		advance = event.keycode == KEY_SPACE or event.keycode == KEY_ENTER
	elif event is InputEventMouseButton and event.pressed:
		advance = event.button_index == MOUSE_BUTTON_LEFT

	if not advance:
		return

	var viewport := get_viewport()
	if viewport:
		viewport.set_input_as_handled()

	if _is_typing:
		_is_typing = false
		if text_label:
			text_label.text = _colorize_text(_full_text)
		if continue_label:
			var is_last_line := (_current_line >= _lines.size() - 1)
			continue_label.text = (
				"[ Press Space or Click to continue ]"
				if not is_last_line
				else "[ Press Space or Click to close ]"
			)
			continue_label.visible = true
		return

	AudioManager.play_sfx("dialogue_blip", 0.1)
	_current_line += 1
	_show_current_line()


func _set_caller_talking(active: bool) -> void:
	if not _caller:
		return
	var figure := _caller.get_node_or_null("Figure")
	if figure and figure.has_method("set_talking"):
		figure.set_talking(active)


func _set_player_movement_enabled(enabled: bool) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_movement_enabled"):
		player.set_movement_enabled(enabled)


func _ensure_world_unpaused() -> void:
	var hud := get_parent()
	if hud and hud.has_method("_set_game_paused"):
		hud._set_game_paused(false)


func _finish_dialogue() -> void:
	_set_caller_talking(false)
	_set_player_movement_enabled(true)
	_clear_choices()
	visible = false
	emit_signal("all_lines_shown")

	var caller := _caller
	var show_puzzle := _show_puzzle_after
	var open_store := _open_store_after
	_show_puzzle_after = false
	_open_store_after = false
	_caller = null

	if caller and caller.has_method("on_dialogue_finished"):
		caller.on_dialogue_finished()

	emit_signal("dialogue_finished", caller)

	var hud := get_parent()
	if show_puzzle and caller and caller.has_method("_present_puzzle"):
		caller.call_deferred("_present_puzzle")
	elif open_store and hud and hud.has_method("open_store"):
		hud.call_deferred("open_store")
	else:
		_ensure_world_unpaused()
