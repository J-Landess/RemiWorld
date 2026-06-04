## DialogueBox.gd
## =============================================================
## Shows NPC dialogue text one line at a time.
## The player presses Space or clicks to advance through lines.
##
## Features:
##   - Typewriter effect (text appears letter by letter)
##   - "Press Space to continue" indicator
##   - Can trigger a puzzle or store after dialogue ends
##
## Attached to: scenes/ui/HUD.tscn → DialogueBox node
## Node type: Control
## =============================================================
extends Control

# ─────────────────────────────────────────────────────────────
# SIGNALS
# ─────────────────────────────────────────────────────────────
signal dialogue_finished(caller: Node)
signal all_lines_shown()

# ─────────────────────────────────────────────────────────────
# NODE REFERENCES
# ─────────────────────────────────────────────────────────────
@onready var speaker_label: Label   = $Panel/VBoxContainer/SpeakerLabel
@onready var text_label: RichTextLabel = $Panel/VBoxContainer/TextLabel
@onready var continue_label: Label  = $Panel/VBoxContainer/ContinueLabel

# ─────────────────────────────────────────────────────────────
# INTERNAL STATE
# ─────────────────────────────────────────────────────────────
var _lines: Array = []        # All lines of dialogue to show
var _current_line: int = 0    # Which line we're on
var _caller: Node = null      # The NPC who started this dialogue
var _show_puzzle_after: bool = false   # Open puzzle when done?
var _open_store_after: bool = false    # Open store when done?
var _is_typing: bool = false  # Is the typewriter effect running?
var _full_text: String = ""   # The complete text of the current line
var _type_timer: float = 0.0  # Timer for typewriter effect
var _dialogue_font: Font = null


func _ready() -> void:
	_apply_dialogue_theme()


func _apply_dialogue_theme() -> void:
	var sys := SystemFont.new()
	sys.font_names = PackedStringArray([
		"Chalkboard SE", "Comic Sans MS", "Arial Rounded MT Bold",
		"Marker Felt", "Helvetica Neue", "Arial"
	])
	sys.font_weight = 600
	_dialogue_font = sys
	if speaker_label:
		speaker_label.add_theme_font_override("font", sys)
		speaker_label.add_theme_font_size_override("font_size", 28)
	if text_label:
		text_label.add_theme_font_override("normal_font", sys)
		text_label.add_theme_font_size_override("normal_font_size", 24)
	if continue_label:
		continue_label.add_theme_font_override("font", sys)
		continue_label.add_theme_font_size_override("font_size", 16)


# ─────────────────────────────────────────────────────────────
# SHOW DIALOGUE
# Called by NPCs to start a conversation.
# ─────────────────────────────────────────────────────────────
func show_dialogue(speaker: String, lines: Array, caller: Node = null,
		show_puzzle_after: bool = false, open_store_after: bool = false) -> void:

	if lines.is_empty():
		return

	_lines = lines
	_current_line = 0
	_caller = caller
	_show_puzzle_after = show_puzzle_after
	_open_store_after = open_store_after

	if speaker_label:
		speaker_label.text = speaker

	visible = true
	_show_current_line()


# ─────────────────────────────────────────────────────────────
# DISPLAY THE CURRENT LINE
# ─────────────────────────────────────────────────────────────
func _show_current_line() -> void:
	if _current_line >= _lines.size():
		_finish_dialogue()
		return

	var line: String = _lines[_current_line]

	# Strip the "[Speaker Name] " prefix if it exists in the dialogue text
	# (Some dialogue lines are formatted as "[Coding Bot] Hello!" for readability)
	if "]" in line:
		var parts := line.split("] ", true, 1)
		if parts.size() > 1:
			line = parts[1]

	_full_text = line
	_is_typing = true
	_type_timer = 0.0

	if text_label:
		text_label.text = ""  # Start with empty text for typewriter effect

	if continue_label:
		continue_label.visible = false


# ─────────────────────────────────────────────────────────────
# TYPEWRITER EFFECT — called every frame
# ─────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if not visible or not _is_typing:
		return

	_type_timer += delta
	var char_speed: float = GameState.text_speed  # Seconds per character

	# Calculate how many characters should be visible now
	var chars_to_show: int = int(_type_timer / char_speed)
	chars_to_show = min(chars_to_show, _full_text.length())

	if text_label:
		text_label.text = _full_text.left(chars_to_show)

	# When all characters are shown, show the "continue" prompt
	if chars_to_show >= _full_text.length():
		_is_typing = false
		if continue_label:
			var is_last_line := (_current_line >= _lines.size() - 1)
			continue_label.text = "[ Press Space or Click to continue ]" if not is_last_line else "[ Press Space or Click to close ]"
			continue_label.visible = true


# ─────────────────────────────────────────────────────────────
# INPUT — advance dialogue when Space or mouse click
# ─────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if not visible:
		return

	var advance := false
	if event is InputEventKey and event.pressed:
		advance = (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)
	elif event is InputEventMouseButton and event.pressed:
		advance = (event.button_index == MOUSE_BUTTON_LEFT)

	if not advance:
		return

	# If still typing, skip to the end of the current line
	if _is_typing:
		_is_typing = false
		if text_label:
			text_label.text = _full_text
		if continue_label:
			continue_label.visible = true
		return

	# Move to the next line
	AudioManager.play_sfx("dialogue_blip", 0.1)
	_current_line += 1
	_show_current_line()

	# Consume the input so it doesn't propagate
	get_viewport().set_input_as_handled()


# ─────────────────────────────────────────────────────────────
# DIALOGUE COMPLETE
# ─────────────────────────────────────────────────────────────
func _finish_dialogue() -> void:
	visible = false
	emit_signal("all_lines_shown")

	# Notify the caller NPC that dialogue is done
	if _caller and _caller.has_method("on_dialogue_finished"):
		_caller.on_dialogue_finished()

	emit_signal("dialogue_finished", _caller)

	# Trigger post-dialogue actions
	var hud := get_parent()
	if _show_puzzle_after and _caller:
		if _caller.has_method("_present_puzzle"):
			_caller._present_puzzle()
	elif _open_store_after:
		if hud and hud.has_method("open_store"):
			hud.open_store()
