## AvatarRenderer.gd — draws the player avatar with customization layers.
class_name AvatarRenderer
extends Node2D

const SKIN_PALETTE: Array[Color] = [
	Color(1.00, 0.87, 0.73), Color(0.94, 0.76, 0.55), Color(0.80, 0.60, 0.35),
	Color(0.60, 0.40, 0.20), Color(0.35, 0.22, 0.10), Color(0.90, 0.70, 0.45),
	Color(0.85, 0.75, 0.65),
]
const SKIN_TONE_NAMES: Array[String] = [
	"light", "medium_light", "medium", "medium_dark", "dark", "warm", "cool"
]

const OUTFIT_COLORS: Dictionary = {
	"blue": Color(0.25, 0.45, 0.85), "red": Color(0.85, 0.22, 0.28),
	"green": Color(0.22, 0.70, 0.32), "yellow": Color(0.90, 0.75, 0.15),
	"purple": Color(0.60, 0.22, 0.75), "pink": Color(0.95, 0.45, 0.70),
	"teal": Color(0.15, 0.65, 0.65), "orange": Color(0.95, 0.50, 0.15),
	"white": Color(0.92, 0.92, 0.92), "black": Color(0.18, 0.18, 0.18),
	"gold": Color(0.82, 0.62, 0.18),
}

const HAIR_STYLE_IDS: Dictionary = {
	"short": 0, "long": 1, "curly": 2, "ponytail": 3, "bun": 4,
	"afro": 5, "spiky": 6, "buzz": 7, "mohawk": 8, "braids": 9,
}

var skin_color: Color   = SKIN_PALETTE[2]
var hair_color: Color   = Color(0.29, 0.16, 0.06)
var outfit_color: Color = Color(0.25, 0.45, 0.85)
var shoe_color: Color   = Color(0.20, 0.20, 0.20)
var hair_style: int     = 0
var eye_color: Color    = Color(0.12, 0.10, 0.08)
var facing: String      = "down"
var outfit_style: String = "casual"
var eyewear: String = ""
var headwear: String = ""
var facial_hair: String = ""
var makeup: String = ""
var vehicle: String = ""
var remi_bald: bool = false

@export var figure_scale: float = 1.0


func apply_config(config: Dictionary) -> void:
	var tone: String = config.get("skin_tone", "medium")
	var tone_idx: int = SKIN_TONE_NAMES.find(tone)
	skin_color = SKIN_PALETTE[tone_idx] if tone_idx >= 0 else SKIN_PALETTE[2]

	var hair_hex: String = config.get("hair_color", "#4A2800")
	hair_color = Color(hair_hex) if hair_hex.is_valid_html_color() else Color(0.29, 0.16, 0.06)

	var style_name: String = str(config.get("hairstyle", "short"))
	hair_style = int(HAIR_STYLE_IDS.get(style_name, 0))

	var outfit_name: String = config.get("outfit_color", "blue")
	outfit_color = OUTFIT_COLORS.get(outfit_name, Color(0.25, 0.45, 0.85))
	if not OUTFIT_COLORS.has(outfit_name) and outfit_name.is_valid_html_color():
		outfit_color = Color(outfit_name)

	var shoe_name: String = config.get("shoe_color", "black")
	shoe_color = OUTFIT_COLORS.get(shoe_name, Color(0.2, 0.2, 0.2))

	outfit_style = config.get("outfit_style", "casual")
	eyewear = config.get("eyewear", "")
	headwear = config.get("headwear", "")
	facial_hair = config.get("facial_hair", "")
	makeup = config.get("makeup", "")
	vehicle = config.get("vehicle", "")
	remi_bald = config.get("remi_bald", GameState.remi_bald)
	queue_redraw()


func _draw() -> void:
	var s := figure_scale
	if vehicle == "scooter":
		_draw_scooter(s)

	var pants_color := outfit_color.darkened(0.25)
	draw_rect(Rect2(-9 * s, 8 * s, 8 * s, 16 * s), pants_color)
	draw_rect(Rect2(1 * s, 8 * s, 8 * s, 16 * s), pants_color)
	draw_rect(Rect2(-11 * s, 24 * s, 10 * s, 5 * s), shoe_color)
	draw_rect(Rect2(1 * s, 24 * s, 10 * s, 5 * s), shoe_color)

	if outfit_style == "fancy_coat":
		draw_rect(Rect2(-14 * s, -10 * s, 28 * s, 22 * s), outfit_color.darkened(0.08))
		draw_rect(Rect2(-12 * s, -8 * s, 6 * s, 18 * s), outfit_color.lightened(0.12))
		draw_rect(Rect2(6 * s, -8 * s, 6 * s, 18 * s), outfit_color.lightened(0.12))
	else:
		draw_rect(Rect2(-11 * s, -8 * s, 22 * s, 17 * s), outfit_color)

	draw_rect(Rect2(-18 * s, -8 * s, 7 * s, 14 * s), skin_color)
	draw_rect(Rect2(11 * s, -8 * s, 7 * s, 14 * s), skin_color)
	draw_rect(Rect2(-18 * s, 4 * s, 7 * s, 3 * s), outfit_color.darkened(0.1))
	draw_rect(Rect2(11 * s, 4 * s, 7 * s, 3 * s), outfit_color.darkened(0.1))
	draw_rect(Rect2(-4 * s, -14 * s, 8 * s, 6 * s), skin_color)
	draw_rect(Rect2(-12 * s, -36 * s, 24 * s, 22 * s), skin_color)
	draw_rect(Rect2(-15 * s, -30 * s, 3 * s, 6 * s), skin_color)
	draw_rect(Rect2(12 * s, -30 * s, 3 * s, 6 * s), skin_color)

	if facing != "up":
		draw_rect(Rect2(-8 * s, -26 * s, 5 * s, 5 * s), eye_color)
		draw_rect(Rect2(3 * s, -26 * s, 5 * s, 5 * s), eye_color)
		draw_rect(Rect2(-7 * s, -25 * s, 2 * s, 2 * s), Color.WHITE)
		draw_rect(Rect2(4 * s, -25 * s, 2 * s, 2 * s), Color.WHITE)
		draw_rect(Rect2(-5 * s, -19 * s, 10 * s, 2 * s), skin_color.darkened(0.25))
		_draw_makeup(s)
		_draw_facial_hair(s)
		if eyewear == "sunglasses":
			draw_rect(Rect2(-10 * s, -27 * s, 20 * s, 6 * s), Color(0.08, 0.08, 0.12, 0.92))
			draw_line(Vector2(0, -24 * s), Vector2(0, -21 * s), Color(0.2, 0.2, 0.25), 2.0)

	if not remi_bald:
		_draw_hair(s)
	if headwear == "headphones":
		draw_rect(Rect2(-14 * s, -42 * s, 28 * s, 4 * s), Color(0.22, 0.22, 0.28))
		draw_rect(Rect2(-16 * s, -38 * s, 6 * s, 10 * s), Color(0.35, 0.35, 0.42))
		draw_rect(Rect2(10 * s, -38 * s, 6 * s, 10 * s), Color(0.35, 0.35, 0.42))


func _draw_hair(s: float) -> void:
	match hair_style:
		0:
			draw_rect(Rect2(-12 * s, -40 * s, 24 * s, 8 * s), hair_color)
			draw_rect(Rect2(-13 * s, -36 * s, 3 * s, 6 * s), hair_color)
			draw_rect(Rect2(10 * s, -36 * s, 3 * s, 6 * s), hair_color)
		1:
			draw_rect(Rect2(-12 * s, -40 * s, 24 * s, 8 * s), hair_color)
			draw_rect(Rect2(-14 * s, -36 * s, 4 * s, 30 * s), hair_color)
			draw_rect(Rect2(10 * s, -36 * s, 4 * s, 30 * s), hair_color)
		2:
			draw_rect(Rect2(-14 * s, -46 * s, 28 * s, 14 * s), hair_color)
			draw_rect(Rect2(-16 * s, -38 * s, 6 * s, 10 * s), hair_color)
			draw_rect(Rect2(10 * s, -38 * s, 6 * s, 10 * s), hair_color)
		3:
			draw_rect(Rect2(-12 * s, -40 * s, 24 * s, 8 * s), hair_color)
			draw_rect(Rect2(-3 * s, -52 * s, 6 * s, 16 * s), hair_color)
		4:
			draw_rect(Rect2(-12 * s, -40 * s, 24 * s, 6 * s), hair_color)
			draw_rect(Rect2(-7 * s, -50 * s, 14 * s, 12 * s), hair_color)
		5: # Afro
			draw_circle(Vector2(0, -32 * s), 16 * s, hair_color)
		6: # Spiky
			for i in 5:
				var sx: float = -10.0 * s + float(i) * 5.0 * s
				draw_colored_polygon(PackedVector2Array([
					Vector2(sx, -38 * s), Vector2(sx + 2.5 * s, -48 * s), Vector2(sx + 5 * s, -38 * s),
				]), hair_color)
		7: # Buzz
			draw_rect(Rect2(-12 * s, -39 * s, 24 * s, 5 * s), hair_color.darkened(0.15))
		8: # Mohawk
			draw_colored_polygon(PackedVector2Array([
				Vector2(-3 * s, -38 * s), Vector2(0, -52 * s), Vector2(3 * s, -38 * s),
			]), hair_color)
		9: # Braids
			draw_rect(Rect2(-12 * s, -40 * s, 24 * s, 7 * s), hair_color)
			draw_rect(Rect2(-15 * s, -36 * s, 3 * s, 22 * s), hair_color.darkened(0.12))
			draw_rect(Rect2(12 * s, -36 * s, 3 * s, 22 * s), hair_color.darkened(0.12))


func _draw_facial_hair(s: float) -> void:
	if facial_hair.is_empty():
		return
	var fc := hair_color.darkened(0.2)
	match facial_hair:
		"stubble":
			draw_rect(Rect2(-7 * s, -21 * s, 14 * s, 4 * s), fc.lightened(0.35))
		"mustache":
			draw_rect(Rect2(-6 * s, -20 * s, 12 * s, 3 * s), fc)
		"goatee":
			draw_rect(Rect2(-4 * s, -17 * s, 8 * s, 6 * s), fc)
		"beard_short":
			draw_rect(Rect2(-8 * s, -22 * s, 16 * s, 10 * s), fc)
		"beard_long":
			draw_rect(Rect2(-9 * s, -22 * s, 18 * s, 16 * s), fc)


func _draw_makeup(s: float) -> void:
	match makeup:
		"blush":
			draw_circle(Vector2(-9 * s, -22 * s), 3 * s, Color(1, 0.55, 0.6, 0.45))
			draw_circle(Vector2(9 * s, -22 * s), 3 * s, Color(1, 0.55, 0.6, 0.45))
		"lips":
			draw_rect(Rect2(-5 * s, -19 * s, 10 * s, 3 * s), Color(0.9, 0.35, 0.45))
		"glam":
			draw_circle(Vector2(-9 * s, -22 * s), 3.5 * s, Color(1, 0.5, 0.65, 0.5))
			draw_circle(Vector2(9 * s, -22 * s), 3.5 * s, Color(1, 0.5, 0.65, 0.5))
			draw_rect(Rect2(-5 * s, -19 * s, 10 * s, 3 * s), Color(0.85, 0.2, 0.4))
			draw_rect(Rect2(-10 * s, -27 * s, 4 * s, 2 * s), Color(0.55, 0.75, 1, 0.7))
			draw_rect(Rect2(6 * s, -27 * s, 4 * s, 2 * s), Color(0.55, 0.75, 1, 0.7))


func _draw_scooter(s: float) -> void:
	var body_c := Color(0.92, 0.28, 0.22)
	draw_rect(Rect2(-22 * s, 28 * s, 44 * s, 6 * s), body_c)
	draw_circle(Vector2(-14 * s, 36 * s), 5 * s, Color(0.15, 0.15, 0.18))
	draw_circle(Vector2(14 * s, 36 * s), 5 * s, Color(0.15, 0.15, 0.18))
	draw_rect(Rect2(8 * s, 18 * s, 14 * s, 4 * s), Color(0.35, 0.35, 0.4))


func set_facing(direction: String) -> void:
	if facing != direction:
		facing = direction
		queue_redraw()
