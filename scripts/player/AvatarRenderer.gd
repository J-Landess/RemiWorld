## AvatarRenderer.gd
## =============================================================
## Draws a simple 2D character figure using Godot's _draw() API.
## Used in two places:
##   1. AvatarCreation screen — live preview as you customise
##   2. In-game Player node — so the avatar you built appears in the world
##
## The character is drawn from the node's local origin (0, 0),
## which sits at roughly the character's centre-waist.
## All measurements are in pixels.
## =============================================================
extends Node2D

# ─────────────────────────────────────────────────────────────
# SKIN TONE PALETTE (index matches AvatarManager.SKIN_TONES order)
# ─────────────────────────────────────────────────────────────
const SKIN_PALETTE: Array[Color] = [
	Color(1.00, 0.87, 0.73),   # light
	Color(0.94, 0.76, 0.55),   # medium_light
	Color(0.80, 0.60, 0.35),   # medium
	Color(0.60, 0.40, 0.20),   # medium_dark
	Color(0.35, 0.22, 0.10),   # dark
	Color(0.90, 0.70, 0.45),   # warm
	Color(0.85, 0.75, 0.65),   # cool
]

const SKIN_TONE_NAMES: Array[String] = [
	"light", "medium_light", "medium", "medium_dark", "dark", "warm", "cool"
]

# Preset outfit colours (used when no hex string is stored)
const OUTFIT_COLORS: Dictionary = {
	"blue":   Color(0.25, 0.45, 0.85),
	"red":    Color(0.85, 0.22, 0.28),
	"green":  Color(0.22, 0.70, 0.32),
	"yellow": Color(0.90, 0.75, 0.15),
	"purple": Color(0.60, 0.22, 0.75),
	"pink":   Color(0.95, 0.45, 0.70),
	"teal":   Color(0.15, 0.65, 0.65),
	"orange": Color(0.95, 0.50, 0.15),
	"white":  Color(0.92, 0.92, 0.92),
	"black":  Color(0.18, 0.18, 0.18),
}

# ─────────────────────────────────────────────────────────────
# CONFIG — set these to change the appearance
# ─────────────────────────────────────────────────────────────
var skin_color: Color   = SKIN_PALETTE[2]       # medium default
var hair_color: Color   = Color(0.29, 0.16, 0.06)
var outfit_color: Color = Color(0.25, 0.45, 0.85)
var shoe_color: Color   = Color(0.20, 0.20, 0.20)
var hair_style: int     = 0  # 0=short 1=long 2=curly 3=ponytail 4=bun
var eye_color: Color    = Color(0.12, 0.10, 0.08)
var facing: String      = "down"  # "up" "down" "left" "right"

# Scale the whole figure (1.0 = 48 px tall approx)
@export var figure_scale: float = 1.0


# ─────────────────────────────────────────────────────────────
# APPLY A FULL AVATAR CONFIG DICTIONARY
# ─────────────────────────────────────────────────────────────
func apply_config(config: Dictionary) -> void:
	# Skin tone
	var tone: String = config.get("skin_tone", "medium")
	var tone_idx: int = SKIN_TONE_NAMES.find(tone)
	skin_color = SKIN_PALETTE[tone_idx] if tone_idx >= 0 else SKIN_PALETTE[2]

	# Hair color (stored as hex string)
	var hair_hex: String = config.get("hair_color", "#4A2800")
	hair_color = Color(hair_hex) if hair_hex.is_valid_html_color() else Color(0.29, 0.16, 0.06)

	# Hair style
	var style_name: String = config.get("hairstyle", "short")
	var style_map := {"short": 0, "long": 1, "curly": 2, "ponytail": 3, "bun": 4}
	hair_style = style_map.get(style_name, 0)

	# Outfit color
	var outfit_name: String = config.get("outfit_color", "blue")
	if outfit_name in OUTFIT_COLORS:
		outfit_color = OUTFIT_COLORS[outfit_name]
	else:
		outfit_color = Color(outfit_name) if outfit_name.is_valid_html_color() else OUTFIT_COLORS["blue"]

	# Shoe color
	var shoe_name: String = config.get("shoe_color", "black")
	if shoe_name in OUTFIT_COLORS:
		shoe_color = OUTFIT_COLORS[shoe_name]
	else:
		shoe_color = Color(shoe_name) if shoe_name.is_valid_html_color() else Color(0.2, 0.2, 0.2)

	queue_redraw()


# ─────────────────────────────────────────────────────────────
# DRAW — called by Godot every frame when queue_redraw() is called
# ─────────────────────────────────────────────────────────────
func _draw() -> void:
	var s := figure_scale

	# ── LEGS ────────────────────────────────────────────────
	var pants_color := outfit_color.darkened(0.25)
	draw_rect(Rect2(-9*s,  8*s, 8*s, 16*s), pants_color)   # left leg
	draw_rect(Rect2( 1*s,  8*s, 8*s, 16*s), pants_color)   # right leg

	# ── SHOES ───────────────────────────────────────────────
	draw_rect(Rect2(-11*s, 24*s, 10*s, 5*s), shoe_color)   # left shoe
	draw_rect(Rect2(  1*s, 24*s, 10*s, 5*s), shoe_color)   # right shoe

	# ── BODY / OUTFIT ───────────────────────────────────────
	draw_rect(Rect2(-11*s, -8*s, 22*s, 17*s), outfit_color)

	# ── ARMS ────────────────────────────────────────────────
	draw_rect(Rect2(-18*s, -8*s,  7*s, 14*s), skin_color)  # left arm
	draw_rect(Rect2( 11*s, -8*s,  7*s, 14*s), skin_color)  # right arm

	# Sleeve cuffs
	draw_rect(Rect2(-18*s,  4*s,  7*s,  3*s), outfit_color.darkened(0.1))
	draw_rect(Rect2( 11*s,  4*s,  7*s,  3*s), outfit_color.darkened(0.1))

	# ── NECK ────────────────────────────────────────────────
	draw_rect(Rect2(-4*s, -14*s,  8*s,  6*s), skin_color)

	# ── HEAD ────────────────────────────────────────────────
	draw_rect(Rect2(-12*s, -36*s, 24*s, 22*s), skin_color)

	# ── EARS ────────────────────────────────────────────────
	draw_rect(Rect2(-15*s, -30*s,  3*s,  6*s), skin_color)
	draw_rect(Rect2( 12*s, -30*s,  3*s,  6*s), skin_color)

	# ── EYES (direction-aware) ───────────────────────────────
	if facing != "up":
		var eye_y := -26*s
		var left_eye_x  := -8*s
		var right_eye_x :=  3*s
		draw_rect(Rect2(left_eye_x,  eye_y, 5*s, 5*s), eye_color)
		draw_rect(Rect2(right_eye_x, eye_y, 5*s, 5*s), eye_color)
		# Shine dot
		draw_rect(Rect2(left_eye_x + 1*s,  eye_y + 1*s, 2*s, 2*s), Color.WHITE)
		draw_rect(Rect2(right_eye_x + 1*s, eye_y + 1*s, 2*s, 2*s), Color.WHITE)

		# Mouth (small smile)
		draw_rect(Rect2(-5*s, -19*s, 10*s, 2*s), skin_color.darkened(0.25))

	# ── HAIR ────────────────────────────────────────────────
	_draw_hair(s)


func _draw_hair(s: float) -> void:
	match hair_style:
		0: # Short — close crop
			draw_rect(Rect2(-12*s, -40*s, 24*s, 8*s), hair_color)
			draw_rect(Rect2(-13*s, -36*s,  3*s, 6*s), hair_color)  # left sideburn
			draw_rect(Rect2( 10*s, -36*s,  3*s, 6*s), hair_color)  # right sideburn

		1: # Long — flows down the sides
			draw_rect(Rect2(-12*s, -40*s, 24*s, 8*s), hair_color)
			draw_rect(Rect2(-14*s, -36*s,  4*s, 30*s), hair_color) # left flow
			draw_rect(Rect2( 10*s, -36*s,  4*s, 30*s), hair_color) # right flow

		2: # Curly — poofy top
			draw_rect(Rect2(-14*s, -46*s, 28*s, 14*s), hair_color) # wide poof
			draw_rect(Rect2(-16*s, -38*s,  6*s, 10*s), hair_color) # left poof
			draw_rect(Rect2( 10*s, -38*s,  6*s, 10*s), hair_color) # right poof
			draw_rect(Rect2(-12*s, -36*s, 24*s,  4*s), hair_color) # base band

		3: # Ponytail — bun at back, tail going up
			draw_rect(Rect2(-12*s, -40*s, 24*s, 8*s), hair_color)
			draw_rect(Rect2( -3*s, -52*s,  6*s, 16*s), hair_color) # tail going up
			draw_rect(Rect2( -5*s, -54*s, 10*s,  6*s), hair_color) # tip

		4: # Bun — round bun on top
			draw_rect(Rect2(-12*s, -40*s, 24*s, 6*s), hair_color)
			draw_rect(Rect2( -7*s, -50*s, 14*s, 12*s), hair_color) # bun body
			draw_rect(Rect2( -9*s, -46*s, 18*s,  8*s), hair_color) # bun wide


# ─────────────────────────────────────────────────────────────
# UPDATE FACING DIRECTION (called by Player.gd during movement)
# ─────────────────────────────────────────────────────────────
func set_facing(direction: String) -> void:
	if facing != direction:
		facing = direction
		queue_redraw()
