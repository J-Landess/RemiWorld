## ChessParkPanel.gd — NYC/DC-style chess park (vs random AI or local 2P).
extends Control

const BOARD_SIZE := 8

enum Mode { VS_HUSTLER_AI, TWO_PLAYERS_LOCAL }

const PIECE_CHARS: Dictionary = {
	"wK": "♔", "wQ": "♕", "wR": "♖", "wB": "♗", "wN": "♘", "wP": "♙",
	"bK": "♚", "bQ": "♛", "bR": "♜", "bB": "♝", "bN": "♞", "bP": "♟",
}

@onready var title_label: Label = $Panel/VBox/Title
@onready var subtitle_label: Label = $Panel/VBox/Subtitle
@onready var mode_label: Label = $Panel/VBox/ModeLabel
@onready var grid: GridContainer = $Panel/VBox/BoardWrap/Grid
@onready var status_label: Label = $Panel/VBox/Status
@onready var close_button: Button = $Panel/VBox/Buttons/CloseButton
@onready var new_game_button: Button = $Panel/VBox/Buttons/NewGameButton
@onready var mode_button: Button = $Panel/VBox/Buttons/ModeButton

var _caller: Node = null
var _mode: int = Mode.VS_HUSTLER_AI

var _board: Array = []
var _turn_is_white: bool = true
var _selected: Vector2i = Vector2i(-1, -1)
var _legal_dests: Array[Vector2i] = []
var _buttons: Array[Button] = []


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	if new_game_button:
		new_game_button.pressed.connect(_on_new_game_pressed)
	if mode_button:
		mode_button.pressed.connect(_on_mode_pressed)


func show_challenge(_mission_data: Dictionary, caller: Node) -> void:
	_caller = caller
	visible = true
	randomize()

	if title_label:
		title_label.text = "♟️  Chess Park"
	if subtitle_label:
		subtitle_label.text = "NYC/DC vibes — trash talk optional."

	_build_board_ui()
	_start_new_game()


func _build_board_ui() -> void:
	if not grid:
		return
	for child in grid.get_children():
		child.queue_free()
	_buttons.clear()
	grid.columns = BOARD_SIZE

	for row in BOARD_SIZE:
		for col in BOARD_SIZE:
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(46, 46)
			btn.focus_mode = Control.FOCUS_NONE
			btn.add_theme_font_size_override("font_size", 22)

			var is_dark := ((row + col) % 2) == 1
			var style := StyleBoxFlat.new()
			style.bg_color = Color(0.18, 0.12, 0.10) if is_dark else Color(0.92, 0.88, 0.78)
			style.corner_radius_top_left = 6
			style.corner_radius_top_right = 6
			style.corner_radius_bottom_left = 6
			style.corner_radius_bottom_right = 6
			btn.add_theme_stylebox_override("normal", style)
			var hover := style.duplicate()
			hover.bg_color = (style.bg_color as Color).lightened(0.10)
			btn.add_theme_stylebox_override("hover", hover)

			btn.pressed.connect(_on_cell_pressed.bind(Vector2i(col, row)))
			grid.add_child(btn)
			_buttons.append(btn)


func _start_new_game() -> void:
	_board = _initial_board()
	_turn_is_white = true
	_selected = Vector2i(-1, -1)
	_legal_dests.clear()
	_update_mode_text()
	_render()
	_set_status("White to move. Pick a piece.")


func _update_mode_text() -> void:
	if not mode_label:
		return
	match _mode:
		Mode.VS_HUSTLER_AI:
			mode_label.text = "Mode: Vs Hustler (AI makes random moves)"
		Mode.TWO_PLAYERS_LOCAL:
			mode_label.text = "Mode: Two players (same device)"

	if mode_button:
		mode_button.text = "Switch mode"


func _initial_board() -> Array:
	# y=0 is top (black side), y=7 is bottom (white side)
	var b := []
	for _y in BOARD_SIZE:
		var row: Array = []
		for _x in BOARD_SIZE:
			row.append("")
		b.append(row)

	# Black
	b[0] = ["bR", "bN", "bB", "bQ", "bK", "bB", "bN", "bR"]
	for x in BOARD_SIZE:
		b[1][x] = "bP"

	# White
	b[7] = ["wR", "wN", "wB", "wQ", "wK", "wB", "wN", "wR"]
	for x in BOARD_SIZE:
		b[6][x] = "wP"

	return b


func _render() -> void:
	for y in BOARD_SIZE:
		for x in BOARD_SIZE:
			var idx := y * BOARD_SIZE + x
			var btn: Button = _buttons[idx]
			var code: String = str(_board[y][x])
			btn.text = PIECE_CHARS.get(code, "")

			# base tint for piece color
			btn.modulate = Color(1, 1, 1, 1)
			if code.begins_with("b"):
				btn.modulate = Color(0.85, 0.85, 0.92)

			var pos := Vector2i(x, y)
			if pos == _selected:
				btn.modulate = Color(0.65, 1.0, 0.75) # selected
			elif pos in _legal_dests:
				btn.modulate = Color(0.60, 0.95, 0.65, 0.9) # legal move highlight


func _on_cell_pressed(pos: Vector2i) -> void:
	if not _in_bounds(pos):
		return

	# If vs AI and it's black's turn, ignore clicks while AI is thinking.
	if _mode == Mode.VS_HUSTLER_AI and not _turn_is_white:
		return

	var code: String = str(_board[pos.y][pos.x])
	var side := "w" if _turn_is_white else "b"

	# Move if clicked a highlighted destination
	if pos in _legal_dests and _selected.x >= 0:
		_make_move(_selected, pos)
		return

	# Select a piece belonging to the side to move
	if code.begins_with(side):
		_selected = pos
		_legal_dests = _legal_moves(pos, code)
		_render()
		return

	# Otherwise clear selection
	_selected = Vector2i(-1, -1)
	_legal_dests.clear()
	_render()


func _make_move(from: Vector2i, to: Vector2i) -> void:
	var piece: String = str(_board[from.y][from.x])
	var target: String = str(_board[to.y][to.x])

	# capture end condition: king taken
	var captured_king := target.ends_with("K")

	_board[to.y][to.x] = piece
	_board[from.y][from.x] = ""

	# promotion (simple): auto-queen
	if piece.ends_with("P"):
		if piece.begins_with("w") and to.y == 0:
			_board[to.y][to.x] = "wQ"
		elif piece.begins_with("b") and to.y == 7:
			_board[to.y][to.x] = "bQ"

	_selected = Vector2i(-1, -1)
	_legal_dests.clear()
	_turn_is_white = not _turn_is_white
	_render()

	AudioManager.play_sfx("chess_move")

	if captured_king:
		var winner := "White" if not _turn_is_white else "Black"
		_set_status(winner + " wins! King captured.")
		if _caller and _caller.has_method("on_challenge_finished"):
			await get_tree().create_timer(1.0).timeout
			_caller.on_challenge_finished(true)
		return

	# If no legal moves, call it a wrap (simple stalemate/checkmate blend)
	if _all_legal_moves_for_side("w" if _turn_is_white else "b").is_empty():
		_set_status("No legal moves left. Game over.")
		return

	if _mode == Mode.VS_HUSTLER_AI and not _turn_is_white:
		_set_status("Hustler thinking… (random move)")
		await get_tree().create_timer(0.25).timeout
		_ai_make_random_move()
	else:
		_set_status(("White" if _turn_is_white else "Black") + " to move.")


func _ai_make_random_move() -> void:
	var moves := _all_legal_moves_for_side("b")
	if moves.is_empty():
		_set_status("Hustler has no legal moves. Game over.")
		return
	var pick: Dictionary = moves[randi() % moves.size()]
	_make_move(pick["from"] as Vector2i, pick["to"] as Vector2i)


func _all_legal_moves_for_side(side: String) -> Array:
	var out: Array = []
	for y in BOARD_SIZE:
		for x in BOARD_SIZE:
			var code: String = str(_board[y][x])
			if not code.begins_with(side):
				continue
			var from := Vector2i(x, y)
			var dests := _legal_moves(from, code)
			for d in dests:
				out.append({"from": from, "to": d})
	return out


func _legal_moves(from: Vector2i, piece: String) -> Array[Vector2i]:
	var side := piece.substr(0, 1)
	var kind := piece.substr(1, 1)
	var moves: Array[Vector2i] = []

	match kind:
		"P":
			_add_pawn_moves(from, side, moves)
		"N":
			_add_knight_moves(from, side, moves)
		"B":
			_add_ray_moves(from, side, moves, [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)] as Array[Vector2i])
		"R":
			_add_ray_moves(from, side, moves, [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)] as Array[Vector2i])
		"Q":
			_add_ray_moves(from, side, moves, [
				Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
				Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
			] as Array[Vector2i])
		"K":
			_add_king_moves(from, side, moves)

	return moves


func _add_pawn_moves(from: Vector2i, side: String, moves: Array[Vector2i]) -> void:
	var dir := -1 if side == "w" else 1
	var start_rank := 6 if side == "w" else 1

	var one := from + Vector2i(0, dir)
	if _in_bounds(one) and _is_empty(one):
		moves.append(one)
		var two := from + Vector2i(0, dir * 2)
		if from.y == start_rank and _in_bounds(two) and _is_empty(two):
			moves.append(two)

	# captures
	for dx in [-1, 1]:
		var cap := from + Vector2i(dx, dir)
		if not _in_bounds(cap):
			continue
		if _is_enemy(cap, side):
			moves.append(cap)


func _add_knight_moves(from: Vector2i, side: String, moves: Array[Vector2i]) -> void:
	var offsets := [
		Vector2i(-2, -1), Vector2i(-2, 1), Vector2i(2, -1), Vector2i(2, 1),
		Vector2i(-1, -2), Vector2i(-1, 2), Vector2i(1, -2), Vector2i(1, 2),
	]
	for off in offsets:
		var p := from + off
		if not _in_bounds(p):
			continue
		if _is_empty(p) or _is_enemy(p, side):
			moves.append(p)


func _add_king_moves(from: Vector2i, side: String, moves: Array[Vector2i]) -> void:
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			var p := from + Vector2i(dx, dy)
			if not _in_bounds(p):
				continue
			if _is_empty(p) or _is_enemy(p, side):
				moves.append(p)


func _add_ray_moves(from: Vector2i, side: String, moves: Array[Vector2i], dirs: Array[Vector2i]) -> void:
	for d in dirs:
		var p: Vector2i = from + d
		while _in_bounds(p):
			if _is_empty(p):
				moves.append(p)
				p += d
				continue
			if _is_enemy(p, side):
				moves.append(p)
			break


func _is_empty(pos: Vector2i) -> bool:
	return str(_board[pos.y][pos.x]) == ""


func _is_enemy(pos: Vector2i, side: String) -> bool:
	var code: String = str(_board[pos.y][pos.x])
	return code != "" and not code.begins_with(side)


func _in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < BOARD_SIZE and pos.y >= 0 and pos.y < BOARD_SIZE


func _set_status(text: String) -> void:
	if status_label:
		status_label.text = text

	if subtitle_label:
		# Give it that park feel.
		if _mode == Mode.VS_HUSTLER_AI and not _turn_is_white:
			subtitle_label.text = "\"Yo, you sure about that move?\""
		elif _mode == Mode.VS_HUSTLER_AI and _turn_is_white:
			subtitle_label.text = "\"Ten bucks says you blunder.\""
		else:
			subtitle_label.text = "Two players — park rules. No take-backs."


func _on_new_game_pressed() -> void:
	AudioManager.play_sfx("click")
	_start_new_game()


func _on_mode_pressed() -> void:
	AudioManager.play_sfx("click")
	_mode = Mode.TWO_PLAYERS_LOCAL if _mode == Mode.VS_HUSTLER_AI else Mode.VS_HUSTLER_AI
	_start_new_game()


func _on_close_pressed() -> void:
	AudioManager.play_sfx("click")
	visible = false
	var hud := get_parent()
	if hud and hud.has_method("close_all_panels"):
		hud.close_all_panels()
	if _caller and _caller.has_method("on_challenge_finished"):
		# Backing out is not a "win" — don't grant mission rewards.
		_caller.on_challenge_finished(false)
