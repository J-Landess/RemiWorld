## ChessPuzzlePanel.gd — 8×8 "save the piece" chess puzzles.
extends Control

const KNIGHT_OFFSETS: Array[Vector2i] = [
	Vector2i(-2, -1), Vector2i(-2, 1), Vector2i(2, -1), Vector2i(2, 1),
	Vector2i(-1, -2), Vector2i(-1, 2), Vector2i(1, -2), Vector2i(1, 2),
]

const KING_OFFSETS: Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(-1, 0), Vector2i(1, 0),
	Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
]

@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var prompt_label: Label = $Panel/VBoxContainer/PromptLabel
@onready var grid: GridContainer = $Panel/VBoxContainer/BoardWrap/Grid
@onready var feedback_label: Label = $Panel/VBoxContainer/FeedbackLabel
@onready var round_label: Label = $Panel/VBoxContainer/RoundLabel
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton

var _mission_data: Dictionary = {}
var _caller: Node = null
var _rounds: int = 3
var _required_correct: int = 2
var _current_round: int = 0
var _correct_count: int = 0
var _answered_this_round: bool = false
var _puzzle: Dictionary = {}
var _board: Array = []
var _hero: Vector2i = Vector2i.ZERO
var _hero_type: String = "wK"
var _safe_squares: Array = []
var _buttons: Array = []


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	if close_button:
		close_button.pressed.connect(_on_close_pressed)


func show_challenge(mission_data: Dictionary, caller: Node) -> void:
	_mission_data = mission_data
	_caller = caller

	var cfg: Dictionary = mission_data.get("challenge", {})
	_rounds = int(cfg.get("rounds", 3))
	_required_correct = int(cfg.get("required_correct", 2))
	_current_round = 0
	_correct_count = 0

	if title_label:
		title_label.text = "♞  %s" % mission_data.get("title", "Save the Piece")
	if close_button:
		close_button.text = "Give Up"

	visible = true
	_build_board()
	_start_round()


func _build_board() -> void:
	if not grid:
		return
	for child in grid.get_children():
		child.queue_free()
	_buttons.clear()
	grid.columns = ChessPuzzleData.BOARD_SIZE

	for row in ChessPuzzleData.BOARD_SIZE:
		for col in ChessPuzzleData.BOARD_SIZE:
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(44, 44)
			btn.focus_mode = Control.FOCUS_NONE
			btn.add_theme_font_size_override("font_size", 22)
			var is_dark := ((row + col) % 2) == 1
			var style := StyleBoxFlat.new()
			style.bg_color = Color(0.28, 0.18, 0.12) if is_dark else Color(0.93, 0.88, 0.78)
			btn.add_theme_stylebox_override("normal", style)
			var hover := style.duplicate()
			hover.bg_color = (style.bg_color as Color).lightened(0.12)
			btn.add_theme_stylebox_override("hover", hover)
			btn.pressed.connect(_on_cell_pressed.bind(Vector2i(col, row)))
			grid.add_child(btn)
			_buttons.append(btn)


func _start_round() -> void:
	_answered_this_round = false
	_current_round += 1
	_puzzle = ChessPuzzleData.get_puzzle(_current_round - 1)
	_board = _puzzle.get("board", [])
	_hero = _puzzle.get("hero", Vector2i.ZERO)
	_hero_type = _puzzle.get("hero_type", "wK")
	_safe_squares = _puzzle.get("safe_squares", [])

	if prompt_label:
		prompt_label.text = _puzzle.get("prompt", "Move the threatened piece to safety!")
		prompt_label.modulate = Color(1, 1, 1, 1)
	if feedback_label:
		feedback_label.text = ""
	if round_label:
		round_label.text = "Puzzle %d / %d   ·   Saved: %d" % [_current_round, _rounds, _correct_count]

	_render_board()


func _render_board() -> void:
	for row in ChessPuzzleData.BOARD_SIZE:
		for col in ChessPuzzleData.BOARD_SIZE:
			var pos := Vector2i(col, row)
			var idx := row * ChessPuzzleData.BOARD_SIZE + col
			var btn: Button = _buttons[idx]
			btn.disabled = false
			btn.modulate = Color(1, 1, 1, 1)

			var piece_code: String = ""
			if row < _board.size() and col < _board[row].size():
				piece_code = str(_board[row][col])

			if pos == _hero:
				btn.text = ChessPuzzleData.piece_char(_hero_type)
				btn.modulate = Color(1.0, 0.45, 0.45)
			elif piece_code != "":
				btn.text = ChessPuzzleData.piece_char(piece_code)
				if piece_code.begins_with("b"):
					btn.modulate = Color(0.75, 0.75, 0.82)
			else:
				btn.text = ""
				if pos in _legal_moves(_hero, _hero_type):
					btn.modulate = Color(0.55, 0.95, 0.65, 0.85)


func _legal_moves(from: Vector2i, piece_type: String) -> Array:
	var moves: Array = []
	match piece_type:
		"wK":
			for off in KING_OFFSETS:
				_add_if_empty(from + off, moves)
		"wN":
			for off in KNIGHT_OFFSETS:
				_add_if_empty(from + off, moves)
		"wR":
			_add_ray_moves(from, moves, [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)] as Array[Vector2i])
		"wB":
			_add_ray_moves(from, moves, [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)] as Array[Vector2i])
		"wQ":
			_add_ray_moves(from, moves, [
				Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
				Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
			] as Array[Vector2i])
	return moves


func _add_if_empty(pos: Vector2i, moves: Array) -> void:
	if not _in_bounds(pos):
		return
	if str(_board[pos.y][pos.x]) == "":
		moves.append(pos)


func _add_ray_moves(from: Vector2i, moves: Array, directions: Array[Vector2i]) -> void:
	for dir in directions:
		var pos: Vector2i = from + dir
		while _in_bounds(pos):
			if str(_board[pos.y][pos.x]) != "":
				break
			moves.append(pos)
			pos += dir


func _in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < ChessPuzzleData.BOARD_SIZE and pos.y >= 0 and pos.y < ChessPuzzleData.BOARD_SIZE


func _on_cell_pressed(clicked: Vector2i) -> void:
	if _answered_this_round:
		return
	_answered_this_round = true

	var legal: Array = _legal_moves(_hero, _hero_type)
	var is_legal := clicked in legal
	var is_safe := clicked in _safe_squares
	var correct := is_legal and is_safe

	AudioManager.play_sfx("chess_move")
	AudioManager.play_sfx("correct" if correct else "wrong")

	for btn in _buttons:
		btn.disabled = true

	var clicked_idx := clicked.y * ChessPuzzleData.BOARD_SIZE + clicked.x
	if correct:
		_buttons[clicked_idx].text = ChessPuzzleData.piece_char(_hero_type)
		_buttons[clicked_idx].modulate = Color(0.35, 1.0, 0.45)
		_correct_count += 1
		if feedback_label:
			feedback_label.text = "✅  Piece saved!"
			feedback_label.modulate = Color(0.35, 1.0, 0.45)
	elif not is_legal:
		if feedback_label:
			feedback_label.text = "❌  That piece can't move there!"
			feedback_label.modulate = Color(1.0, 0.45, 0.45)
	else:
		if feedback_label:
			feedback_label.text = "❌  Still in danger! " + _puzzle.get("hint", "")
			feedback_label.modulate = Color(1.0, 0.45, 0.45)
		_buttons[clicked_idx].modulate = Color(1.0, 0.4, 0.4)

	if round_label:
		round_label.text = "Puzzle %d / %d   ·   Saved: %d" % [_current_round, _rounds, _correct_count]

	await get_tree().create_timer(1.4).timeout

	if _current_round >= _rounds:
		_finish_challenge()
	else:
		_start_round()


func _finish_challenge() -> void:
	var success := _correct_count >= _required_correct
	visible = false
	var hud := get_parent()
	if hud and hud.has_method("close_all_panels"):
		hud.close_all_panels()
	if _caller and _caller.has_method("on_challenge_finished"):
		_caller.on_challenge_finished(success)


func _on_close_pressed() -> void:
	AudioManager.play_sfx("click")
	_correct_count = 0
	_finish_challenge()
