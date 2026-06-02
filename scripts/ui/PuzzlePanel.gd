## PuzzlePanel.gd
## =============================================================
## Displays a multiple-choice logic puzzle for the player to answer.
##
## Controls:
##   Mouse click     — select an answer
##   Space / Enter   — confirm the currently focused answer button
##   1 / 2 / 3 keys  — quick-select answer by number
##   Escape / C      — close the panel (before answering)
## =============================================================
extends Control

# ─────────────────────────────────────────────────────────────
# SIGNALS
# ─────────────────────────────────────────────────────────────
signal answer_selected(index: int, correct: bool)

# ─────────────────────────────────────────────────────────────
# NODE REFERENCES
# ─────────────────────────────────────────────────────────────
@onready var question_label: Label            = $Panel/VBoxContainer/QuestionLabel
@onready var pattern_label: Label             = $Panel/VBoxContainer/PatternLabel
@onready var choices_container: VBoxContainer = $Panel/VBoxContainer/ChoicesContainer
@onready var feedback_label: Label            = $Panel/VBoxContainer/FeedbackLabel
@onready var close_button: Button             = $Panel/VBoxContainer/CloseButton

# ─────────────────────────────────────────────────────────────
# INTERNAL STATE
# ─────────────────────────────────────────────────────────────
var _puzzle_data: Dictionary = {}
var _caller: Node = null
var _answered: bool = false
var _choice_buttons: Array[Button] = []


# ─────────────────────────────────────────────────────────────
# READY
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	visible = false
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
		close_button.visible = true  # Always show so the player can exit


# ─────────────────────────────────────────────────────────────
# SHOW THE PUZZLE
# ─────────────────────────────────────────────────────────────
func show_puzzle(puzzle_data: Dictionary, caller: Node) -> void:
	_puzzle_data = puzzle_data
	_caller = caller
	_answered = false
	_choice_buttons.clear()

	if question_label:
		question_label.text = puzzle_data.get("question", "What comes next?")

	if pattern_label:
		var pattern: Array = puzzle_data.get("display_pattern", [])
		pattern_label.text = " → ".join(pattern) if not pattern.is_empty() else ""
		pattern_label.visible = not pattern.is_empty()

	# Clear and rebuild choice buttons
	if choices_container:
		for child in choices_container.get_children():
			child.queue_free()

		var choices: Array = puzzle_data.get("choices", [])
		for i in range(choices.size()):
			var btn := Button.new()
			btn.text = "%d)  %s" % [i + 1, choices[i]]
			btn.custom_minimum_size = Vector2(220, 52)
			btn.add_theme_font_size_override("font_size", 18)
			btn.pressed.connect(_on_choice_pressed.bind(i))
			choices_container.add_child(btn)
			_choice_buttons.append(btn)

	if feedback_label:
		feedback_label.text = ""
		feedback_label.visible = false

	# Always show the close/exit button
	if close_button:
		close_button.text = "✕  Close"
		close_button.visible = true

	visible = true

	# Auto-focus the first answer so Space/Enter immediately works
	await get_tree().process_frame
	if _choice_buttons.size() > 0:
		_choice_buttons[0].grab_focus()


# ─────────────────────────────────────────────────────────────
# KEYBOARD INPUT — 1/2/3 keys as shortcuts, Esc to close
# ─────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if not visible or _answered:
		return

	if not (event is InputEventKey) or not event.pressed or event.is_echo():
		return

	# Number keys 1–3 instantly pick an answer
	if event.keycode == KEY_1 and _choice_buttons.size() >= 1:
		get_viewport().set_input_as_handled()
		_on_choice_pressed(0)
	elif event.keycode == KEY_2 and _choice_buttons.size() >= 2:
		get_viewport().set_input_as_handled()
		_on_choice_pressed(1)
	elif event.keycode == KEY_3 and _choice_buttons.size() >= 3:
		get_viewport().set_input_as_handled()
		_on_choice_pressed(2)
	elif event.keycode == KEY_ESCAPE or event.keycode == KEY_C:
		get_viewport().set_input_as_handled()
		_on_close_pressed()


# ─────────────────────────────────────────────────────────────
# CHOICE SELECTED (mouse click OR Space/Enter on focused button)
# ─────────────────────────────────────────────────────────────
func _on_choice_pressed(index: int) -> void:
	if _answered:
		return
	_answered = true
	AudioManager.play_sfx("click")

	var correct_index: int = _puzzle_data.get("correct_index", 0)
	var correct: bool = (index == correct_index)

	# Disable all choice buttons and colour them
	for i in range(_choice_buttons.size()):
		var btn: Button = _choice_buttons[i]
		btn.disabled = true
		if i == correct_index:
			btn.modulate = Color(0.3, 1.0, 0.4)   # green = correct
		elif i == index and not correct:
			btn.modulate = Color(1.0, 0.35, 0.35)  # red = wrong selection

	AudioManager.play_sfx("correct" if correct else "wrong")

	# Show feedback text
	if feedback_label:
		feedback_label.visible = true
		if correct:
			feedback_label.text = "✅ Correct!\n" + _puzzle_data.get("explanation", "")
			feedback_label.modulate = Color(0.3, 1.0, 0.4)
		else:
			var correct_answer: String = _puzzle_data.get("choices", [])[correct_index]
			feedback_label.text = "❌ Not quite! The answer was: %s\n%s" % [
				correct_answer,
				_puzzle_data.get("hint", "")
			]
			feedback_label.modulate = Color(1.0, 0.4, 0.4)

	# Update close button to say "Continue" after answering
	if close_button:
		close_button.text = "✅  Continue"
		close_button.grab_focus()

	# Notify the NPC caller after a short pause
	await get_tree().create_timer(1.0).timeout
	if _caller and _caller.has_method("on_puzzle_answered"):
		_caller.on_puzzle_answered(index)

	emit_signal("answer_selected", index, correct)


# ─────────────────────────────────────────────────────────────
# CLOSE
# ─────────────────────────────────────────────────────────────
func _on_close_pressed() -> void:
	visible = false
	var hud := get_parent()
	if hud and hud.has_method("close_all_panels"):
		hud.close_all_panels()
