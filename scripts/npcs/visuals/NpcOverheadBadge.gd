## NpcOverheadBadge.gd — floating quest / shop icon above an NPC.
extends Node2D

@export_enum("quest", "shop") var badge_kind: String = "quest"

var _pulse: float = 0.0


func _ready() -> void:
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_pulse += delta
	queue_redraw()


func _draw() -> void:
	var float_y := sin(_pulse * 3.5) * 3.0
	var bob := sin(_pulse * 3.5) * 0.08 + 1.0
	var r := 14.0 * bob
	var center := Vector2(0, float_y)
	# Bubble
	draw_circle(center, r + 2, Color(1, 1, 1, 0.95))
	draw_circle(center, r, Color(0.98, 0.92, 0.55) if badge_kind == "quest" else Color(1.0, 0.82, 0.9))
	draw_arc(center, r, 0, TAU, 24, Color(0.45, 0.35, 0.2, 0.35), 2.0)

	if badge_kind == "quest":
		draw_string(ThemeDB.fallback_font, center + Vector2(-4, 5), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.35, 0.25, 0.55))
	else:
		# Simple bag icon
		draw_colored_polygon(
			PackedVector2Array([
				center + Vector2(-6, -2), center + Vector2(6, -2),
				center + Vector2(7, 8), center + Vector2(-7, 8),
			]),
			Color(0.85, 0.35, 0.55),
		)
		draw_line(center + Vector2(-4, -2), center + Vector2(-4, -7), Color(0.55, 0.3, 0.4), 2.0)
		draw_line(center + Vector2(4, -2), center + Vector2(4, -7), Color(0.55, 0.3, 0.4), 2.0)
		draw_arc(center + Vector2(0, -7), 5, PI, 0, 8, Color(0.55, 0.3, 0.4), 2.0)
