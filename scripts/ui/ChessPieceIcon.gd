## ChessPieceIcon.gd
## Draws a chess piece procedurally within its Control bounds.
## Add as a child of a Button; call setup(code) where code is e.g. "wK", "bP".
## Replaces Unicode chess glyphs (♔♕…) which fail in Godot web exports.
class_name ChessPieceIcon
extends Control


var _code: String = ""


func setup(code: String) -> void:
	_code = code
	visible = code.length() >= 2
	queue_redraw()


func _draw() -> void:
	if _code.length() < 2 or size.x < 4:
		return

	var kind: String = _code.substr(1, 1)
	var white: bool = _code.begins_with("w")
	var cx: float = size.x * 0.5
	var cy: float = size.y * 0.5
	var s: float = minf(size.x, size.y) * 0.38

	# Dark oval shadow under each piece — makes it pop off ANY square color
	var shadow_col := Color(0.08, 0.05, 0.03, 0.60) if white else Color(0.06, 0.04, 0.02, 0.45)
	_draw_ellipse(cx, cy + s * 0.85, s * 0.72, s * 0.20, shadow_col)

	# True white pieces / deep charcoal black pieces — clearly different from the board squares
	var fill  := Color(1.00, 1.00, 1.00) if white else Color(0.12, 0.08, 0.18)
	var stroke := Color(0.16, 0.10, 0.06, 1.0) if white else Color(0.90, 0.88, 0.96, 1.0)
	var sw    := 2.5

	match kind:
		"P": _draw_pawn(cx, cy, s, fill, stroke, sw)
		"R": _draw_rook(cx, cy, s, fill, stroke, sw)
		"N": _draw_knight(cx, cy, s, fill, stroke, sw)
		"B": _draw_bishop(cx, cy, s, fill, stroke, sw)
		"Q": _draw_queen(cx, cy, s, fill, stroke, sw)
		"K": _draw_king(cx, cy, s, fill, stroke, sw)


func _draw_ellipse(cx: float, cy: float, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	const SEG := 18
	for i in SEG:
		var a := TAU * float(i) / float(SEG)
		pts.append(Vector2(cx + cos(a) * rx, cy + sin(a) * ry))
	draw_colored_polygon(pts, color)


func _draw_pawn(cx: float, cy: float, s: float, fill: Color, stroke: Color, sw: float) -> void:
	var base := PackedVector2Array([
		Vector2(cx - s * 0.72, cy + s),
		Vector2(cx + s * 0.72, cy + s),
		Vector2(cx + s * 0.42, cy + s * 0.38),
		Vector2(cx - s * 0.42, cy + s * 0.38),
	])
	draw_colored_polygon(base, fill)
	draw_polyline(PackedVector2Array(base) + PackedVector2Array([base[0]]), stroke, sw, true)
	var stem := PackedVector2Array([
		Vector2(cx - s * 0.16, cy + s * 0.38),
		Vector2(cx + s * 0.16, cy + s * 0.38),
		Vector2(cx + s * 0.12, cy - s * 0.08),
		Vector2(cx - s * 0.12, cy - s * 0.08),
	])
	draw_colored_polygon(stem, fill)
	draw_circle(Vector2(cx, cy - s * 0.42), s * 0.38, fill)
	draw_arc(Vector2(cx, cy - s * 0.42), s * 0.38, 0, TAU, 16, stroke, sw)


func _draw_rook(cx: float, cy: float, s: float, fill: Color, stroke: Color, sw: float) -> void:
	var body := PackedVector2Array([
		Vector2(cx - s * 0.58, cy + s),
		Vector2(cx + s * 0.58, cy + s),
		Vector2(cx + s * 0.58, cy - s * 0.38),
		Vector2(cx - s * 0.58, cy - s * 0.38),
	])
	draw_colored_polygon(body, fill)
	draw_polyline(PackedVector2Array(body) + PackedVector2Array([body[0]]), stroke, sw, true)
	for i in 3:
		var bx := cx - s * 0.38 + float(i) * s * 0.38
		var merlon := PackedVector2Array([
			Vector2(bx - s * 0.14, cy - s * 0.38),
			Vector2(bx + s * 0.14, cy - s * 0.38),
			Vector2(bx + s * 0.14, cy - s * 0.85),
			Vector2(bx - s * 0.14, cy - s * 0.85),
		])
		draw_colored_polygon(merlon, fill)
		draw_polyline(PackedVector2Array(merlon) + PackedVector2Array([merlon[0]]), stroke, sw - 0.8, true)


func _draw_knight(cx: float, cy: float, s: float, fill: Color, stroke: Color, sw: float) -> void:
	var body := PackedVector2Array([
		Vector2(cx - s * 0.56, cy + s),
		Vector2(cx + s * 0.56, cy + s),
		Vector2(cx + s * 0.42, cy + s * 0.28),
		Vector2(cx + s * 0.52, cy - s * 0.22),
		Vector2(cx + s * 0.42, cy - s * 0.80),
		Vector2(cx + s * 0.05, cy - s),
		Vector2(cx - s * 0.22, cy - s * 0.68),
		Vector2(cx + s * 0.08, cy - s * 0.30),
		Vector2(cx - s * 0.38, cy - s * 0.08),
		Vector2(cx - s * 0.48, cy + s * 0.22),
	])
	draw_colored_polygon(body, fill)
	draw_polyline(PackedVector2Array(body) + PackedVector2Array([body[0]]), stroke, sw, true)
	draw_circle(Vector2(cx + s * 0.24, cy - s * 0.76), s * 0.11, stroke)


func _draw_bishop(cx: float, cy: float, s: float, fill: Color, stroke: Color, sw: float) -> void:
	var base := PackedVector2Array([
		Vector2(cx - s * 0.65, cy + s),
		Vector2(cx + s * 0.65, cy + s),
		Vector2(cx + s * 0.40, cy + s * 0.42),
		Vector2(cx - s * 0.40, cy + s * 0.42),
	])
	draw_colored_polygon(base, fill)
	draw_polyline(PackedVector2Array(base) + PackedVector2Array([base[0]]), stroke, sw, true)
	draw_circle(Vector2(cx, cy + s * 0.12), s * 0.34, fill)
	draw_arc(Vector2(cx, cy + s * 0.12), s * 0.34, 0, TAU, 16, stroke, sw)
	var neck := PackedVector2Array([
		Vector2(cx - s * 0.16, cy + s * 0.38),
		Vector2(cx + s * 0.16, cy + s * 0.38),
		Vector2(cx + s * 0.07, cy - s * 0.52),
		Vector2(cx - s * 0.07, cy - s * 0.52),
	])
	draw_colored_polygon(neck, fill)
	draw_circle(Vector2(cx, cy - s * 0.68), s * 0.19, fill)
	draw_arc(Vector2(cx, cy - s * 0.68), s * 0.19, 0, TAU, 12, stroke, sw - 0.5)
	draw_circle(Vector2(cx, cy - s * 0.90), s * 0.11, fill)
	draw_arc(Vector2(cx, cy - s * 0.90), s * 0.11, 0, TAU, 10, stroke, sw - 0.5)


func _draw_queen(cx: float, cy: float, s: float, fill: Color, stroke: Color, sw: float) -> void:
	var base := PackedVector2Array([
		Vector2(cx - s * 0.72, cy + s),
		Vector2(cx + s * 0.72, cy + s),
		Vector2(cx + s * 0.50, cy + s * 0.35),
		Vector2(cx - s * 0.50, cy + s * 0.35),
	])
	draw_colored_polygon(base, fill)
	draw_polyline(PackedVector2Array(base) + PackedVector2Array([base[0]]), stroke, sw, true)
	draw_circle(Vector2(cx, cy + s * 0.05), s * 0.43, fill)
	draw_arc(Vector2(cx, cy + s * 0.05), s * 0.43, 0, TAU, 20, stroke, sw)
	var band := PackedVector2Array([
		Vector2(cx - s * 0.48, cy - s * 0.36),
		Vector2(cx + s * 0.48, cy - s * 0.36),
		Vector2(cx + s * 0.48, cy - s * 0.54),
		Vector2(cx - s * 0.48, cy - s * 0.54),
	])
	draw_colored_polygon(band, fill)
	draw_polyline(PackedVector2Array(band) + PackedVector2Array([band[0]]), stroke, sw - 0.5, true)
	var ball_xs: Array[float] = [-s * 0.44, -s * 0.22, 0.0, s * 0.22, s * 0.44]
	for bx in ball_xs:
		draw_circle(Vector2(cx + bx, cy - s * 0.72), s * 0.13, fill)
		draw_arc(Vector2(cx + bx, cy - s * 0.72), s * 0.13, 0, TAU, 10, stroke, sw - 0.5)


func _draw_king(cx: float, cy: float, s: float, fill: Color, stroke: Color, sw: float) -> void:
	var base := PackedVector2Array([
		Vector2(cx - s * 0.65, cy + s),
		Vector2(cx + s * 0.65, cy + s),
		Vector2(cx + s * 0.44, cy + s * 0.38),
		Vector2(cx - s * 0.44, cy + s * 0.38),
	])
	draw_colored_polygon(base, fill)
	draw_polyline(PackedVector2Array(base) + PackedVector2Array([base[0]]), stroke, sw, true)
	draw_circle(Vector2(cx, cy + s * 0.05), s * 0.38, fill)
	draw_arc(Vector2(cx, cy + s * 0.05), s * 0.38, 0, TAU, 16, stroke, sw)
	var band := PackedVector2Array([
		Vector2(cx - s * 0.44, cy - s * 0.32),
		Vector2(cx + s * 0.44, cy - s * 0.32),
		Vector2(cx + s * 0.44, cy - s * 0.52),
		Vector2(cx - s * 0.44, cy - s * 0.52),
	])
	draw_colored_polygon(band, fill)
	draw_polyline(PackedVector2Array(band) + PackedVector2Array([band[0]]), stroke, sw - 0.5, true)
	for i in 3:
		var bx := cx - s * 0.36 + float(i) * s * 0.36
		var crown_pt := PackedVector2Array([
			Vector2(bx - s * 0.14, cy - s * 0.52),
			Vector2(bx + s * 0.14, cy - s * 0.52),
			Vector2(bx + s * 0.06, cy - s * 0.82),
			Vector2(bx - s * 0.06, cy - s * 0.82),
		])
		draw_colored_polygon(crown_pt, fill)
		draw_polyline(PackedVector2Array(crown_pt) + PackedVector2Array([crown_pt[0]]), stroke, sw - 0.5, true)
	draw_line(Vector2(cx, cy - s * 0.82), Vector2(cx, cy - s), stroke, 4.0)
	draw_line(Vector2(cx - s * 0.22, cy - s * 0.90), Vector2(cx + s * 0.22, cy - s * 0.90), stroke, 4.0)
