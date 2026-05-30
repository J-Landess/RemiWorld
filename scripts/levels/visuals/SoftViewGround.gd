## SoftViewGround.gd — procedural grass + perspective path (¾-view placeholder art).
extends Node2D


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	# Soft grass field
	var grass_points := PackedVector2Array([
		Vector2(-860, -480), Vector2(860, -480),
		Vector2(860, 480), Vector2(-860, 480),
	])
	draw_colored_polygon(grass_points, Color(0.32, 0.62, 0.28))
	# Lighter patches for depth
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-520, -200), Vector2(-180, -200),
			Vector2(-120, 120), Vector2(-560, 80),
		]),
		Color(0.38, 0.70, 0.34, 0.45),
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(280, -80), Vector2(640, -40),
			Vector2(600, 260), Vector2(240, 200),
		]),
		Color(0.36, 0.68, 0.32, 0.35),
	)

	# Path — trapezoid (narrower toward “north”, wider toward camera / south)
	var path := PackedVector2Array([
		Vector2(-28, -480), Vector2(28, -480),
		Vector2(52, 480), Vector2(-52, 480),
	])
	draw_colored_polygon(path, Color(0.62, 0.52, 0.38))
	# Path edge shadows
	draw_line(Vector2(-28, -480), Vector2(-52, 480), Color(0.45, 0.36, 0.26, 0.5), 3.0)
	draw_line(Vector2(28, -480), Vector2(52, 480), Color(0.75, 0.65, 0.48, 0.4), 2.0)

	# Subtle vignette corners
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-860, -480), Vector2(-500, -480),
			Vector2(-860, -200),
		]),
		Color(0.12, 0.22, 0.10, 0.18),
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(860, -480), Vector2(500, -480),
			Vector2(860, -200),
		]),
		Color(0.12, 0.22, 0.10, 0.18),
	)
