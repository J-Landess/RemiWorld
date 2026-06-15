## SoftViewParallaxLayer.gd — sky or distant hills for parallax backgrounds.
extends Node2D

@export_enum("sky", "hills", "sunset_sky", "sunset_hills") var layer_kind: String = "sky"


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var extent := Vector2(2200, 1200)
	var origin := Vector2(-extent.x * 0.5, -extent.y * 0.5)

	match layer_kind:
		"sky":
			_draw_sky(extent, origin)
		"hills":
			_draw_hills(extent, origin)
		"sunset_sky":
			_draw_sunset_sky(extent, origin)
		"sunset_hills":
			_draw_sunset_hills(extent, origin)


func _draw_sky(extent: Vector2, origin: Vector2) -> void:
	var steps := 24
	for i in steps:
		var t0 := float(i) / float(steps)
		var t1 := float(i + 1) / float(steps)
		var y0 := origin.y + extent.y * t0
		var y1 := origin.y + extent.y * t1
		var col := Color(0.45, 0.72, 0.98).lerp(Color(0.72, 0.88, 1.0), t0)
		draw_rect(Rect2(origin.x, y0, extent.x, y1 - y0), col)
	draw_circle(Vector2(320, origin.y + 180), 90.0, Color(1.0, 0.95, 0.75, 0.25))
	draw_circle(Vector2(320, origin.y + 180), 50.0, Color(1.0, 0.98, 0.85, 0.35))


func _draw_hills(extent: Vector2, origin: Vector2) -> void:
	var hill_a := PackedVector2Array([
		origin,
		Vector2(origin.x + extent.x, origin.y),
		Vector2(origin.x + extent.x, origin.y + extent.y * 0.55),
		Vector2(origin.x + extent.x * 0.72, origin.y + extent.y * 0.38),
		Vector2(origin.x + extent.x * 0.45, origin.y + extent.y * 0.48),
		Vector2(origin.x + extent.x * 0.18, origin.y + extent.y * 0.42),
		origin + Vector2(0, extent.y * 0.5),
	])
	draw_colored_polygon(hill_a, Color(0.28, 0.52, 0.32, 0.85))
	var hill_b := PackedVector2Array([
		Vector2(origin.x, origin.y + extent.y * 0.35),
		Vector2(origin.x + extent.x, origin.y + extent.y * 0.3),
		Vector2(origin.x + extent.x, origin.y + extent.y * 0.7),
		Vector2(origin.x, origin.y + extent.y * 0.72),
	])
	draw_colored_polygon(hill_b, Color(0.22, 0.46, 0.28, 0.9))


func _draw_sunset_sky(extent: Vector2, origin: Vector2) -> void:
	# Warm orange-to-purple gradient
	var steps := 24
	for i in steps:
		var t0 := float(i) / float(steps)
		var t1 := float(i + 1) / float(steps)
		var y0 := origin.y + extent.y * t0
		var y1 := origin.y + extent.y * t1
		var col := Color(0.95, 0.45, 0.20).lerp(Color(0.60, 0.35, 0.65), t0)
		draw_rect(Rect2(origin.x, y0, extent.x, y1 - y0), col)
	# Big glowing sun low on horizon
	var sun_y := origin.y + extent.y * 0.55
	draw_circle(Vector2(-280, sun_y), 160.0, Color(1.0, 0.80, 0.20, 0.20))
	draw_circle(Vector2(-280, sun_y), 100.0, Color(1.0, 0.88, 0.30, 0.35))
	draw_circle(Vector2(-280, sun_y), 58.0,  Color(1.0, 0.95, 0.55, 0.65))
	# Horizontal glow band
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(origin.x, sun_y - 30), Vector2(origin.x + extent.x, sun_y - 30),
			Vector2(origin.x + extent.x, sun_y + 60), Vector2(origin.x, sun_y + 60),
		]),
		Color(1.0, 0.72, 0.30, 0.18),
	)


func _draw_sunset_hills(extent: Vector2, origin: Vector2) -> void:
	# Dark silhouette hills against the warm sky
	var hill_a := PackedVector2Array([
		origin + Vector2(0, extent.y * 0.45),
		Vector2(origin.x + extent.x * 0.20, origin.y + extent.y * 0.28),
		Vector2(origin.x + extent.x * 0.40, origin.y + extent.y * 0.38),
		Vector2(origin.x + extent.x * 0.58, origin.y + extent.y * 0.22),
		Vector2(origin.x + extent.x * 0.78, origin.y + extent.y * 0.35),
		Vector2(origin.x + extent.x, origin.y + extent.y * 0.42),
		Vector2(origin.x + extent.x, origin.y + extent.y),
		origin + Vector2(0, extent.y),
	])
	draw_colored_polygon(hill_a, Color(0.18, 0.12, 0.22, 0.95))
	# Foreground darker band
	var hill_b := PackedVector2Array([
		origin + Vector2(0, extent.y * 0.55),
		Vector2(origin.x + extent.x * 0.30, origin.y + extent.y * 0.48),
		Vector2(origin.x + extent.x * 0.55, origin.y + extent.y * 0.55),
		Vector2(origin.x + extent.x * 0.80, origin.y + extent.y * 0.46),
		Vector2(origin.x + extent.x, origin.y + extent.y * 0.52),
		Vector2(origin.x + extent.x, origin.y + extent.y),
		origin + Vector2(0, extent.y),
	])
	draw_colored_polygon(hill_b, Color(0.12, 0.08, 0.16, 0.98))
