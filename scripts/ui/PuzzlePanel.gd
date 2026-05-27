## PuzzlePanel.gd
## =============================================================
## Displays a multiple-choice logic puzzle for the player to answer.
## Used by the Coding Bot NPC for the "Pattern Power" mission.
##
## Attached to: scenes/ui/HUD.tscn → PuzzlePanel node
## Node type: Control
## =============================================================
extends Control

# ─────────────────────────────────────────────────────────────
# SIGNALS
# ─────────────────────────────────────────────────────────────
signal answer_selected(index: int, correct: bool)

# ─────────────────────────────────────────────────────────────
# NODE REFERENCES
# ─────────────────────────────────────────────────────────────
@onready var question_label: Label      = $Panel/VBoxContainer/QuestionLabel
@onready var pattern_label: Label       = $Panel/VBoxContainer/PatternLabel
@onready var choices_container: VBoxContainer = $Panel/VBoxContainer/ChoicesContainer
@onready var feedback_label: Label      = $Panel/VBoxContainer/FeedbackLabel
@onready var close_button: Button       = $Panel/VBoxContainer/CloseButton

# ─────────────────────────────────────────────────────────────
# INTERNAL STATE
# ─────────────────────────────────────────────────────────────
var _puzzle_data: Dictionary = {}
var _caller: Node = null
var _answered: bool = false


# ─────────────────────────────────────────────────────────────
# READY
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	visible = false
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
		close_button.visible = false


# ─────────────────────────────────────────────────────────────
# SHOW THE PUZZLE
# ─────────────────────────────────────────────────────────────
func show_puzzle(puzzle_data: Dictionary, caller: Node) -> void:
	_puzzle_data = puzzle_data
	_caller = caller
	_answered = false

	# Display question
	if question_label:
		question_label.text = puzzle_data.get("question", "What comes next?")

	# Display the pattern (if any)
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
			btn.text = choices[i]
			btn.custom_minimum_size = Vector2(200, 50)
			btn.pressed.connect(_on_choice_pressed.bind(i))
			choices_container.add_child(btn)

	# Clear feedback
	if feedback_label:
		feedback_label.text = ""
		feedback_label.visible = false

	if close_button:
		close_button.visible = false

	visible = true


# ─────────────────────────────────────────────────────────────
# CHOICE SELECTED
# ─────────────────────────────────────────────────────────────
func _on_choice_pressed(index: int) -> void:
	if _answered:
		return
	_answered = true

	var correct_index: int = _puzzle_data.get("correct_index", 0)
	var correct: bool = (index == correct_index)

	# Disable all choice buttons
	if choices_container:
		for child in choices_container.get_children():
			child.disabled = true

	# Show feedback
	if feedback_label:
		feedback_label.visible = true
		if correct:
			feedback_label.text = "✅ Correct! " + _puzzle_data.get("explanation", "")
			feedback_label.modulate = Color(0.2, 0.9, 0.2)
		else:
			var correct_answer: String = _puzzle_data.get("choices", [])[correct_index]
			feedback_label.text = "❌ Not quite! The answer was: " + correct_answer + "\n" + _puzzle_data.get("hint", "")
			feedback_label.modulate = Color(0.9, 0.3, 0.3)

	# Notify the caller NPC
	if _caller and _caller.has_method("on_puzzle_answered"):
		await get_tree().create_timer(1.5).timeout
		_caller.on_puzzle_answered(index)
		visible = false

	emit_signal("answer_selected", index, correct)

	# Show close button after answering
	await get_tree().create_timer(1.5).timeout
	if close_button:
		close_button.visible = true


func _on_close_pressed() -> void:
	visible = false
	var hud := get_parent()
	if hud and hud.has_method("close_all_panels"):
		hud.close_all_panels()
