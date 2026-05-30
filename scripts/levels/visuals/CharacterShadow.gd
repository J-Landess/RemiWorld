## CharacterShadow.gd — soft ground shadow under characters (¾-view depth cue).
extends Node2D


func _ready() -> void:
	queue_redraw()
	z_index = -1


func _draw() -> void:
	var pts := PackedVector2Array()
	const SEG := 16
	for i in SEG:
		var a := TAU * float(i) / float(SEG)
		pts.append(Vector2(cos(a) * 18.0, sin(a) * 7.0))
	draw_colored_polygon(pts, Color(0.08, 0.12, 0.06, 0.28))
