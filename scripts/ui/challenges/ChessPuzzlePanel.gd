## ChessPuzzlePanel.gd
## =============================================================
## "Knight's Jump" mini-game.
##
## A 4x4 chessboard is drawn out of TextureButton-style ColorRects
## inside a GridContainer. A knight icon sits on one square and a
## treasure icon on another. The player must click one of the up
## to 8 legal knight moves that lands on the treasure.
##
## Win condition: 2 out of 3 rounds correct.
## =============================================================
extends Control

# ─────────────────────────────────────────────────────────────
# NODE REFERENCES (filled in _ready by name lookup)
# ─────────────────────────────────────────────────────────────
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var prompt_label: Label = $Panel/VBoxContainer/PromptLabel
@onready var grid: GridContainer = $Panel/VBoxContainer/BoardWrap/Grid
@onready var feedback_label: Label = $Panel/VBoxContainer/FeedbackLabel
@onready var round_label: Label = $Panel/VBoxContainer/RoundLabel
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton

# ─────────────────────────────────────────────────────────────
# STATE
# ─────────────────────────────────────────────────────────────
const KNIGHT_OFFSETS: Array[Vector2i] = [
	Vector2i(-2, -1), Vector2i(-2, 1), Vector2i(2, -1), Vector2i(2, 1),
	Vector2i(-1, -2), Vector2i(-1, 2), Vector2i(1, -2), Vector2i(1, 2),
]

var _mission_data: Dictionary = {}
var _caller: Node = null
var _grid_size: int = 4
var _rounds: int = 3
var _required_correct: int = 2
var _current_round: int = 0
var _correct_count: int = 0
var _answered_this_round: bool = false
var _knight_pos: Vector2i = Vector2i.ZERO
var _treasure_pos: Vector2i = Vector2i.ZERO
var _buttons: Array = []   # 1-D array of Button nodes


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	if close_button:
		close_button.pressed.connect(_on_close_pressed)


# ─────────────────────────────────────────────────────────────
# PUBLIC ENTRY POINT (called by HUD.show_challenge)
# ─────────────────────────────────────────────────────────────
func show_challenge(mission_data: Dictionary, caller: Node) -> void:
	_mission_data = mission_data
	_caller = caller

	var cfg: Dictionary = mission_data.get("challenge", {})
	_grid_size = int(cfg.get("grid_size", 4))
	_rounds = int(cfg.get("rounds", 3))
	_required_correct = int(cfg.get("required_correct", 2))
	_current_round = 0
	_correct_count = 0

	if title_label:
		title_label.text = "♞  %s" % mission_data.get("title", "Knight's Jump")
	if close_button:
		close_button.text = "Give Up"

	visible = true
	_build_board()
	_start_round()


# ─────────────────────────────────────────────────────────────
# BUILD THE BOARD GRID (run once)
# ─────────────────────────────────────────────────────────────
func _build_board() -> void:
	if not grid:
		return
	for child in grid.get_children():
		child.queue_free()
	_buttons.clear()

	grid.columns = _grid_size

	for r in range(_grid_size):
		for c in range(_grid_size):
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(56, 56)
			btn.focus_mode = Control.FOCUS_NONE
			btn.add_theme_font_size_override("font_size", 24)
			# Alternating board color
			var is_dark := ((r + c) % 2) == 1
			var style := StyleBoxFlat.new()
			style.bg_color = Color(0.32, 0.22, 0.16) if is_dark else Color(0.95, 0.92, 0.84)
			btn.add_theme_stylebox_override("normal", style)
			var hover_style := style.duplicate()
			hover_style.bg_color = (style.bg_color as Color).lightened(0.15)
			btn.add_theme_stylebox_override("hover", hover_style)
			btn.add_theme_color_override("font_color", Color(0.10, 0.08, 0.10) if not is_dark else Color(0.95, 0.92, 0.84))
			# Connect with the cell's index
			var idx := r * _grid_size + c
			btn.pressed.connect(_on_cell_pressed.bind(idx))
			grid.add_child(btn)
			_buttons.append(btn)


# ─────────────────────────────────────────────────────────────
# ROUND MANAGEMENT
# ─────────────────────────────────────────────────────────────
func _start_round() -> void:
	_answered_this_round = false
	_current_round += 1

	# Pick a knight cell, then pick a treasure cell that is at least
	# one legal knight move away (guarantees the puzzle is solvable).
	_knight_pos = Vector2i(randi() % _grid_size, randi() % _grid_size)
	var possibles: Array = _knight_reachable(_knight_pos)
	if possibles.is_empty():
		# Extreme corner case — re-roll
		_start_round()
		return
	_treasure_pos = possibles[randi() % possibles.size()]

	_render_board()

	if prompt_label:
		prompt_label.text = "Click the square the knight can jump to in ONE L-move."
		prompt_label.modulate = Color(1, 1, 1, 1)
	if feedback_label:
		feedback_label.text = ""
	if round_label:
		round_label.text = "Round %d / %d   ·   Correct so far: %d" % [_current_round, _rounds, _correct_count]


func _render_board() -> void:
	for i in _buttons.size():
		var r := i / _grid_size
		var c := i % _grid_size
		var btn: Button = _buttons[i]
		btn.disabled = false
		btn.modulate = Color(1, 1, 1, 1)
		if Vector2i(c, r) == _knight_pos:
			btn.text = "♞"
		elif Vector2i(c, r) == _treasure_pos:
			btn.text = "★"
		else:
			btn.text = ""


# ─────────────────────────────────────────────────────────────
# KNIGHT LOGIC
# ─────────────────────────────────────────────────────────────
func _knight_reachable(from: Vector2i) -> Array:
	var out: Array = []
	for off in KNIGHT_OFFSETS:
		var dest := from + off
		if dest.x >= 0 and dest.x < _grid_size and dest.y >= 0 and dest.y < _grid_size:
			out.append(dest)
	return out


func _is_legal_move(from: Vector2i, to: Vector2i) -> bool:
	var diff := to - from
	for off in KNIGHT_OFFSETS:
		if off == diff:
			return true
	return false


# ─────────────────────────────────────────────────────────────
# INPUT
# ─────────────────────────────────────────────────────────────
func _on_cell_pressed(cell_idx: int) -> void:
	if _answered_this_round:
		return
	_answered_this_round = true

	var r := cell_idx / _grid_size
	var c := cell_idx % _grid_size
	var clicked := Vector2i(c, r)

	# Clicking the knight or an obvious bad square is just wrong
	var correct := clicked == _treasure_pos and _is_legal_move(_knight_pos, _treasure_pos)

	AudioManager.play_sfx("chess_move")
	AudioManager.play_sfx("correct" if correct else "wrong")

	# Highlight the chosen + the correct
	for i in _buttons.size():
		_buttons[i].disabled = true
		var pr := i / _grid_size
		var pc := i % _grid_size
		var pos := Vector2i(pc, pr)
		if pos == _treasure_pos:
			_buttons[i].modulate = Color(0.40, 1.0, 0.45)
		elif pos == clicked and not correct:
			_buttons[i].modulate = Color(1.0, 0.40, 0.40)

	if correct:
		_correct_count += 1
		if feedback_label:
			feedback_label.text = "✅  Great move!"
			feedback_label.modulate = Color(0.35, 1.0, 0.45)
	else:
		if feedback_label:
			feedback_label.text = "❌  The knight moves in an L. Watch closely!"
			feedback_label.modulate = Color(1.0, 0.45, 0.45)

	if round_label:
		round_label.text = "Round %d / %d   ·   Correct so far: %d" % [_current_round, _rounds, _correct_count]

	await get_tree().create_timer(1.3).timeout

	if _current_round >= _rounds:
		_finish_challenge()
	else:
		_start_round()


# ─────────────────────────────────────────────────────────────
# FINISH
# ─────────────────────────────────────────────────────────────
func _finish_challenge() -> void:
	var success := _correct_count >= _required_correct
	visible = false
	if _caller and _caller.has_method("on_challenge_finished"):
		_caller.on_challenge_finished(success)
	var hud := get_parent()
	if hud and hud.has_method("close_all_panels"):
		hud.close_all_panels()


func _on_close_pressed() -> void:
	AudioManager.play_sfx("click")
	# Treat early close as a failure (player can try again)
	_finish_challenge()
