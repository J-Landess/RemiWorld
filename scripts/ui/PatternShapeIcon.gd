## PatternShapeIcon.gd
## Draws a pattern puzzle shape procedurally within its Control bounds.
## Replaces emoji (🔴🔵⭐🌙❓) which fail in Godot web exports.
## Keys: "red_circle", "blue_circle", "star", "moon", "question"
class_name PatternShapeIcon
extends Control


var _key: String = ""


func setup(key: String, size_px: float) -> void:
	_key = key
	custom_minimum_size = Vector2(size_px, size_px)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	queue_redraw()


func _draw() -> void:
	if _key == "" or size.x < 4:
		return

	var cx := size.x * 0.5
	var cy := size.y * 0.5
	var r := min(size.x, size.y) * 0.42

	match _key:
		"red_circle":
			draw_circle(Vector2(cx, cy), r, Color(0.92, 0.22, 0.22))
			draw_arc(Vector2(cx, cy), r, 0, TAU, 24, Color(0.65, 0.08, 0.08), 2.5)
		"blue_circle":
			draw_circle(Vector2(cx, cy), r, Color(0.22, 0.48, 0.95))
			draw_arc(Vector2(cx, cy), r, 0, TAU, 24, Color(0.10, 0.28, 0.70), 2.5)
		"star":
			_draw_star(cx, cy, r)
		"moon":
			_draw_moon(cx, cy, r)
		"question":
			_draw_question(cx, cy, r)


func _draw_star(cx: float, cy: float, r: float) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var angle := TAU * float(i) / 10.0 - PI * 0.5
		var rad := r if i % 2 == 0 else r * 0.42
		pts.append(Vector2(cx + cos(angle) * rad, cy + sin(angle) * rad))
	draw_colored_polygon(pts, Color(1.0, 0.85, 0.12))
	draw_polyline(PackedVector2Array(pts) + PackedVector2Array([pts[0]]), Color(0.75, 0.58, 0.02), 1.5, true)


func _draw_moon(cx: float, cy: float, r: float) -> void:
	# Crescent opening to the right: outer left arc + inner offset arc
	var col := Color(0.88, 0.90, 0.98)
	var border := Color(0.60, 0.68, 0.88)
	var pts := PackedVector2Array()
	var N := 14
	# Outer: top → left → bottom (angles 3π/2 → π/2 decreasing through π)
	for i in N + 1:
		var a: float = 1.5 * PI - PI * float(i) / float(N)
		pts.append(Vector2(cx + cos(a) * r, cy + sin(a) * r))
	# Inner: offset circle bottom → right → top (angles π/2 → -π/2 decreasing through 0)
	var ox := r * 0.34
	var ir := r * 0.80
	for i in N + 1:
		var a: float = 0.5 * PI - PI * float(i) / float(N)
		pts.append(Vector2(cx + ox + cos(a) * ir, cy + sin(a) * ir))
	draw_colored_polygon(pts, col)
	draw_polyline(PackedVector2Array(pts) + PackedVector2Array([pts[0]]), border, 1.5, true)


func _draw_question(cx: float, cy: float, r: float) -> void:
	var col := Color(0.82, 0.52, 1.0)
	# Arc of question mark
	draw_arc(Vector2(cx + r * 0.04, cy - r * 0.26), r * 0.40, PI * 1.1, PI * 2.1, 14, col, 4.0)
	# Stem going down from arc
	draw_line(Vector2(cx + r * 0.04, cy - r * 0.08), Vector2(cx + r * 0.04, cy + r * 0.30), col, 4.0)
	# Dot
	draw_circle(Vector2(cx + r * 0.04, cy + r * 0.56), r * 0.13, col)
