## ChessPuzzleData.gd — hand-authored "save the piece" chess puzzles.
class_name ChessPuzzleData
extends RefCounted

const BOARD_SIZE: int = 8

const PIECE_CHARS: Dictionary = {
	"wK": "♔", "wQ": "♕", "wR": "♖", "wB": "♗", "wN": "♘", "wP": "♙",
	"bK": "♚", "bQ": "♛", "bR": "♜", "bB": "♝", "bN": "♞", "bP": "♟",
}

static var _puzzles_cache: Array = []


static func _all_puzzles() -> Array:
	if not _puzzles_cache.is_empty():
		return _puzzles_cache
	_puzzles_cache = [
		{
			"title": "King in the Crosshairs",
			"prompt": "The black queen on e8 is attacking your king! Move the king to a safe square.",
			"board": _board_from_rows([
				". . . . bQ . . .",
				". . . . . . . .",
				". . . . . . . .",
				". . . . . . . .",
				". . . . . . . .",
				". . . . . . . .",
				". . . . . . . .",
				". . . . wK . . .",
			]),
			"hero": Vector2i(4, 7),
			"hero_type": "wK",
			"safe_squares": [Vector2i(3, 7), Vector2i(5, 7), Vector2i(3, 6), Vector2i(5, 6)],
			"hint": "Stay off the e-file — the queen controls the whole column!",
		},
		{
			"title": "Knight Under Fire",
			"prompt": "The bishop on f6 is attacking your knight! Jump to safety.",
			"board": _board_from_rows([
				". . . . . . . .",
				". . . . . . . .",
				". . . . . . bB .",
				". . . . . . . .",
				". . . . . . . .",
				". . wN . . . . .",
				". . . . . . . .",
				". . . . . . . .",
			]),
			"hero": Vector2i(2, 5),
			"hero_type": "wN",
			"safe_squares": [Vector2i(0, 4), Vector2i(4, 6), Vector2i(0, 6)],
			"hint": "Knights move in an L — find a square the bishop can't reach.",
		},
		{
			"title": "Rook Rescue",
			"prompt": "The queen on d8 is attacking your rook! Slide it to safety.",
			"board": _board_from_rows([
				". . . bQ . . . .",
				". . . . . . . .",
				". . . . . . . .",
				". . . . . . . .",
				". . . . . . . .",
				". . . . . . . .",
				". . . . . . . .",
				". . . wR . . . .",
			]),
			"hero": Vector2i(3, 7),
			"hero_type": "wR",
			"safe_squares": [Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7), Vector2i(4, 7), Vector2i(5, 7)],
			"hint": "Move off the d-file or hide behind a blocker on the rank.",
		},
	]
	return _puzzles_cache


static func _board_from_rows(rows: Array) -> Array:
	var board: Array = []
	for row in rows:
		var rank: Array = []
		for cell in str(row).split(" ", false):
			rank.append("" if cell == "." else cell)
		while rank.size() < BOARD_SIZE:
			rank.append("")
		board.append(rank)
	while board.size() < BOARD_SIZE:
		board.append(Array([], TYPE_STRING, "", null))
	return board


static func get_puzzle(index: int) -> Dictionary:
	var puzzles := _all_puzzles()
	return puzzles[index % puzzles.size()].duplicate(true)


static func piece_char(code: String) -> String:
	return PIECE_CHARS.get(code, "")
