## DaisyDrawHelper.gd — shared groomer haircut/outfit drawing for Daisy.
class_name DaisyDrawHelper
extends RefCounted

const C_FUR    := Color(1.00, 1.00, 1.00)
const C_EAR    := Color(0.90, 0.80, 0.70)
const C_NOSE   := Color(0.90, 0.55, 0.65)
const C_EYE    := Color(0.12, 0.08, 0.08)
const C_COLLAR := Color(1.00, 0.45, 0.10)


static func draw_idle_dog(
	canvas: CanvasItem,
	x: float,
	y: float,
	s: float,
	facing_right: bool,
	haircut: String = "",
	outfit: String = ""
) -> void:
	if haircut.is_empty():
		haircut = GameState.daisy_haircut
	if outfit.is_empty():
		outfit = GameState.daisy_outfit

	var head_x: float = x + (12.0 * s if facing_right else -11.0 * s)
	var head_y: float = y - (9.0 * s)
	var head_r: float = _head_radius(haircut, s)

	if facing_right:
		canvas.draw_circle(Vector2(x - 14 * s, y - 8 * s), 5.0 * s, C_FUR)
		canvas.draw_rect(Rect2(x - 12 * s, y - 11 * s, 26 * s, 13 * s), C_FUR)
	else:
		canvas.draw_circle(Vector2(x + 14 * s, y - 8 * s), 5.0 * s, C_FUR)
		canvas.draw_rect(Rect2(x - 12 * s, y - 11 * s, 26 * s, 13 * s), C_FUR)

	canvas.draw_circle(Vector2(head_x, head_y), head_r, C_FUR)
	_draw_haircut(canvas, head_x, head_y, s, facing_right, haircut)
	canvas.draw_circle(Vector2(head_x + (5.0 * s if facing_right else -4.0 * s), head_y - 2.0 * s), 2.2 * s, C_EYE)
	canvas.draw_circle(Vector2(head_x + (9.0 * s if facing_right else -8.0 * s), head_y + 3.0 * s), 2.8 * s, C_NOSE)

	for i in 4:
		var lx: float = x + (float(i) * 7.0 - 10.0) * s
		canvas.draw_rect(Rect2(lx, y + 2 * s, 5 * s, 9 * s), C_FUR)

	var collar_x: float = head_x + (-14.0 * s if facing_right else 6.0 * s)
	canvas.draw_rect(Rect2(collar_x, head_y - 6.0 * s, 14 * s, 4 * s), C_COLLAR)
	_draw_outfit(canvas, x, y, s, facing_right, outfit)


static func draw_haircut_only(
	canvas: CanvasItem,
	head_x: float,
	head_y: float,
	s: float,
	facing_right: bool,
	haircut: String = ""
) -> void:
	if haircut.is_empty():
		haircut = GameState.daisy_haircut
	_draw_haircut(canvas, head_x, head_y, s, facing_right, haircut)


static func draw_outfit_only(
	canvas: CanvasItem,
	x: float,
	y: float,
	s: float,
	facing_right: bool,
	outfit: String = ""
) -> void:
	if outfit.is_empty():
		outfit = GameState.daisy_outfit
	_draw_outfit(canvas, x, y, s, facing_right, outfit)


static func head_radius_for(haircut: String, s: float) -> float:
	return _head_radius(haircut, s)


static func _head_radius(haircut: String, s: float) -> float:
	match haircut:
		"puppy_cut":
			return 13.0 * s
		"short":
			return 8.5 * s
		_:
			return 10.0 * s


static func _draw_haircut(
	canvas: CanvasItem,
	head_x: float,
	head_y: float,
	s: float,
	facing_right: bool,
	haircut: String
) -> void:
	var ear_dx: float = (9.0 if facing_right else -17.0) * s
	match haircut:
		"fluffy":
			canvas.draw_rect(Rect2(head_x + ear_dx * 0.5, head_y - 7 * s, 9 * s, 12 * s), C_EAR)
			canvas.draw_circle(Vector2(head_x + ear_dx * 0.5, head_y - 7 * s), 5.5 * s, C_EAR)
		"short":
			canvas.draw_rect(Rect2(head_x + (2.0 if facing_right else -9.0) * s, head_y - 7 * s, 7 * s, 9 * s), C_EAR)
		"mohawk":
			canvas.draw_rect(Rect2(head_x + ear_dx * 0.4, head_y - 7 * s, 9 * s, 12 * s), C_EAR)
			for i in 3:
				var sx: float = head_x + (float(i) * 4.5 - 4.0) * s
				canvas.draw_colored_polygon(PackedVector2Array([
					Vector2(sx, head_y - 11 * s),
					Vector2(sx + 3 * s, head_y - (20 + i * 3) * s),
					Vector2(sx + 6 * s, head_y - 11 * s),
				]), Color(0.85, 0.18, 0.18))
		"puppy_cut":
			canvas.draw_circle(Vector2(head_x + (-2.0 if facing_right else 2.0) * s, head_y - 10 * s), 7.0 * s, C_EAR)
			canvas.draw_circle(Vector2(head_x + (6.0 if facing_right else -6.0) * s, head_y - 8 * s), 5.5 * s, C_EAR)


static func _draw_outfit(
	canvas: CanvasItem,
	x: float,
	y: float,
	s: float,
	facing_right: bool,
	outfit: String
) -> void:
	var hx: float = x + (12.0 if facing_right else -11.0)
	match outfit:
		"bow":
			canvas.draw_circle(Vector2(hx + 10 * s, y - 18 * s), 4.0 * s, Color(1.0, 0.55, 0.75))
			canvas.draw_circle(Vector2(hx + 16 * s, y - 18 * s), 4.0 * s, Color(1.0, 0.55, 0.75))
			canvas.draw_circle(Vector2(hx + 13 * s, y - 18 * s), 2.5 * s, Color(1.0, 0.80, 0.90))
		"bandana":
			canvas.draw_rect(Rect2(hx + 2 * s, y - 14 * s, 14 * s, 5 * s), Color(0.85, 0.28, 0.22))
		"sweater":
			canvas.draw_rect(Rect2(x - 11 * s, y - 10 * s, 24 * s, 12 * s), Color(0.35, 0.55, 0.88, 0.88))
		"vest":
			canvas.draw_rect(Rect2(x - 10 * s, y - 10 * s, 10 * s, 12 * s), Color(0.22, 0.22, 0.22, 0.85))
			canvas.draw_rect(Rect2(x + 2 * s, y - 10 * s, 10 * s, 12 * s), Color(0.22, 0.22, 0.22, 0.85))
