## SoftViewProp.gd — soft ¾-view placeholder props (replace with sprites later).
extends Node2D

@export_enum("tree", "school", "flowers", "bench", "bush", "sign_post", "fence") var prop_type: String = "tree"
@export var prop_scale: float = 1.0
@export var tint: Color = Color(1, 1, 1, 1)


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var s := prop_scale
	match prop_type:
		"tree":
			_draw_tree(s)
		"school":
			_draw_school(s)
		"flowers":
			_draw_flowers(s)
		"bench":
			_draw_bench(s)
		"bush":
			_draw_bush(s)
		"sign_post":
			_draw_sign_post(s)
		"fence":
			_draw_fence(s)


func _shadow_oval(rx: float, ry: float, alpha: float = 0.22) -> void:
	_draw_ellipse(Vector2(0, 6), rx, ry, Color(0.1, 0.15, 0.08, alpha))


func _draw_ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	const SEG := 18
	for i in SEG:
		var a := TAU * float(i) / float(SEG)
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, color)


func _draw_tree(s: float) -> void:
	_shadow_oval(28 * s, 10 * s)
	# Trunk — slight taper
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-7 * s, 8 * s), Vector2(7 * s, 8 * s),
			Vector2(5 * s, -38 * s), Vector2(-5 * s, -38 * s),
		]),
		Color(0.42, 0.28, 0.16) * tint,
	)
	# Canopy clusters (soft puff style)
	var greens := [
		Color(0.28, 0.58, 0.30),
		Color(0.34, 0.66, 0.36),
		Color(0.22, 0.50, 0.26),
	]
	var centers := [
		Vector2(0, -52 * s), Vector2(-22 * s, -42 * s), Vector2(20 * s, -44 * s),
		Vector2(-10 * s, -68 * s), Vector2(14 * s, -62 * s),
	]
	var radii := [32.0, 24.0, 22.0, 20.0, 18.0]
	for i in centers.size():
		draw_circle(centers[i], radii[i] * s, greens[i % greens.size()] * tint)
	# Highlight
	draw_circle(Vector2(-14 * s, -58 * s), 10 * s, Color(0.55, 0.82, 0.52, 0.35))


func _draw_school(s: float) -> void:
	_shadow_oval(70 * s, 14 * s)
	# Foundation / front step
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-78 * s, 10 * s), Vector2(78 * s, 10 * s),
			Vector2(86 * s, 18 * s), Vector2(-86 * s, 18 * s),
		]),
		Color(0.55, 0.52, 0.48) * tint,
	)
	# Main walls (trapezoid for ¾ depth)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-72 * s, 10 * s), Vector2(72 * s, 10 * s),
			Vector2(64 * s, -100 * s), Vector2(-64 * s, -100 * s),
		]),
		Color(0.88, 0.84, 0.72) * tint,
	)
	# Right wall shade
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(24 * s, 10 * s), Vector2(72 * s, 10 * s),
			Vector2(64 * s, -100 * s), Vector2(30 * s, -100 * s),
		]),
		Color(0.72, 0.68, 0.58, 0.55) * tint,
	)
	# Roof
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-80 * s, -100 * s), Vector2(80 * s, -100 * s),
			Vector2(0, -138 * s),
		]),
		Color(0.75, 0.32, 0.28) * tint,
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-80 * s, -100 * s), Vector2(0, -138 * s),
			Vector2(0, -100 * s),
		]),
		Color(0.85, 0.40, 0.34) * tint,
	)
	# Door
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-16 * s, 10 * s), Vector2(16 * s, 10 * s),
			Vector2(14 * s, -42 * s), Vector2(-14 * s, -42 * s),
		]),
		Color(0.45, 0.32, 0.22) * tint,
	)
	draw_circle(Vector2(10 * s, -18 * s), 2.5 * s, Color(0.95, 0.85, 0.35))
	# Windows
	for wx in [-42.0, 42.0]:
		var win := Rect2((wx - 14) * s, -78 * s, 28 * s, 24 * s)
		draw_rect(win, Color(0.55, 0.78, 0.95, 0.9))
		draw_rect(win, Color(0.35, 0.45, 0.55), false, 2.0)


func _draw_flowers(s: float) -> void:
	_shadow_oval(36 * s, 9 * s)
	var spots: Array = [
		[Vector2(-24, 4), Color(0.95, 0.45, 0.65)],
		[Vector2(0, 0), Color(0.98, 0.82, 0.35)],
		[Vector2(22, 6), Color(0.85, 0.40, 0.75)],
		[Vector2(-8, -10), Color(0.55, 0.75, 0.95)],
		[Vector2(14, -8), Color(0.95, 0.55, 0.40)],
		[Vector2(-18, -6), Color(0.90, 0.50, 0.70)],
	]
	for spot in spots:
		var p: Vector2 = spot[0] * s
		draw_line(p, p + Vector2(0, 14 * s), Color(0.25, 0.55, 0.22), 2.0)
		draw_circle(p + Vector2(0, -4 * s), 7 * s, spot[1])


func _draw_bench(s: float) -> void:
	_shadow_oval(34 * s, 8 * s)
	var wood := Color(0.55, 0.38, 0.24) * tint
	# Legs
	for lx in [-24.0, 24.0]:
		draw_colored_polygon(
			PackedVector2Array([
				Vector2((lx - 3) * s, 8 * s), Vector2((lx + 3) * s, 8 * s),
				Vector2((lx + 2) * s, -8 * s), Vector2((lx - 2) * s, -8 * s),
			]),
			wood.darkened(0.15),
		)
	# Seat + back
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-30 * s, -6 * s), Vector2(30 * s, -6 * s),
			Vector2(28 * s, -14 * s), Vector2(-28 * s, -14 * s),
		]),
		wood,
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-28 * s, -14 * s), Vector2(28 * s, -14 * s),
			Vector2(26 * s, -32 * s), Vector2(-26 * s, -32 * s),
		]),
		wood.lightened(0.08),
	)


func _draw_bush(s: float) -> void:
	_shadow_oval(22 * s, 7 * s)
	draw_circle(Vector2(0, -12 * s), 22 * s, Color(0.26, 0.54, 0.28) * tint)
	draw_circle(Vector2(-14 * s, -6 * s), 16 * s, Color(0.32, 0.60, 0.32) * tint)
	draw_circle(Vector2(12 * s, -8 * s), 14 * s, Color(0.30, 0.58, 0.30) * tint)
	draw_circle(Vector2(-6 * s, -18 * s), 10 * s, Color(0.50, 0.78, 0.45, 0.4))


func _draw_sign_post(s: float) -> void:
	_shadow_oval(14 * s, 5 * s)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-3 * s, 8 * s), Vector2(3 * s, 8 * s),
			Vector2(2 * s, -36 * s), Vector2(-2 * s, -36 * s),
		]),
		Color(0.42, 0.30, 0.18) * tint,
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-34 * s, -36 * s), Vector2(34 * s, -36 * s),
			Vector2(34 * s, -58 * s), Vector2(-34 * s, -58 * s),
		]),
		Color(0.92, 0.88, 0.55) * tint,
	)
	draw_rect(Rect2(-34 * s, -58 * s, 68 * s, 22 * s), Color(0.65, 0.45, 0.22), false, 2.0)


func _draw_fence(s: float) -> void:
	_shadow_oval(36 * s, 8 * s)
	var wood := Color(0.52, 0.36, 0.22) * tint
	var wood_light := wood.lightened(0.12)
	# Posts
	for px: float in [-28.0, 0.0, 28.0]:
		draw_colored_polygon(PackedVector2Array([
			Vector2((px - 3) * s, 8 * s),  Vector2((px + 3) * s, 8 * s),
			Vector2((px + 2) * s, -30 * s), Vector2((px - 2) * s, -30 * s),
		]), wood)
	# Rails
	draw_colored_polygon(PackedVector2Array([
		Vector2(-32 * s, -21 * s), Vector2(32 * s, -21 * s),
		Vector2(32 * s, -15 * s), Vector2(-32 * s, -15 * s),
	]), wood_light)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-32 * s, -8 * s), Vector2(32 * s, -8 * s),
		Vector2(32 * s, -2 * s), Vector2(-32 * s, -2 * s),
	]), wood_light)
