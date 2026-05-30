## SoftViewParallaxLayer.gd — sky or distant hills for parallax backgrounds.
extends Node2D

@export_enum("sky", "hills") var layer_kind: String = "sky"


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var extent := Vector2(2200, 1200)
	var origin := Vector2(-extent.x * 0.5, -extent.y * 0.5)

	if layer_kind == "sky":
		# Vertical gradient sky
		var steps := 24
		for i in steps:
			var t0 := float(i) / float(steps)
			var t1 := float(i + 1) / float(steps)
			var y0 := origin.y + extent.y * t0
			var y1 := origin.y + extent.y * t1
			var col := Color(0.45, 0.72, 0.98).lerp(Color(0.72, 0.88, 1.0), t0)
			draw_rect(Rect2(origin.x, y0, extent.x, y1 - y0), col)
		# Soft sun glow
		draw_circle(Vector2(320, origin.y + 180), 90.0, Color(1.0, 0.95, 0.75, 0.25))
		draw_circle(Vector2(320, origin.y + 180), 50.0, Color(1.0, 0.98, 0.85, 0.35))
	else:
		# Distant rolling hills
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
