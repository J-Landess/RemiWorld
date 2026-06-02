## SoftNpcFigure.gd — soft ¾-view NPC figures (replace Sprite2D placeholders).
extends Node2D

@export_enum("coding_bot", "shopkeeper_rose", "chess_tutor", "coach_kick", "artist_pip") var figure_id: String = "coding_bot"
@export var figure_scale: float = 1.0

var _bob: float = 0.0


func _ready() -> void:
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_bob += delta
	queue_redraw()


func _draw() -> void:
	var s := figure_scale
	var bounce := sin(_bob * 2.2) * 1.2 * s
	match figure_id:
		"coding_bot":
			_draw_coding_bot(s, bounce)
		"shopkeeper_rose":
			_draw_shopkeeper_rose(s, bounce)
		"chess_tutor":
			_draw_chess_tutor(s, bounce)
		"coach_kick":
			_draw_coach_kick(s, bounce)
		"artist_pip":
			_draw_artist_pip(s, bounce)


func _draw_ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	const SEG := 16
	for i in SEG:
		var a := TAU * float(i) / float(SEG)
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, color)


func _draw_coding_bot(s: float, bounce: float) -> void:
	var y := bounce
	var body := Color(0.42, 0.72, 0.95)
	var body_dark := Color(0.28, 0.52, 0.78)
	var accent := Color(0.25, 0.88, 0.72)

	# Base / wheels
	_draw_ellipse(Vector2(0, 22 * s + y), 20 * s, 5 * s, Color(0.15, 0.18, 0.22, 0.35))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-18 * s, 14 * s + y), Vector2(18 * s, 14 * s + y),
			Vector2(16 * s, 22 * s + y), Vector2(-16 * s, 22 * s + y),
		]),
		body_dark,
	)
	draw_circle(Vector2(-12 * s, 20 * s + y), 4 * s, Color(0.2, 0.22, 0.28))
	draw_circle(Vector2(12 * s, 20 * s + y), 4 * s, Color(0.2, 0.22, 0.28))

	# Main chassis (¾ depth)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-22 * s, 14 * s + y), Vector2(22 * s, 14 * s + y),
			Vector2(18 * s, -18 * s + y), Vector2(-18 * s, -18 * s + y),
		]),
		body,
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(6 * s, 14 * s + y), Vector2(22 * s, 14 * s + y),
			Vector2(18 * s, -18 * s + y), Vector2(8 * s, -18 * s + y),
		]),
		body_dark,
	)

	# Screen face
	var screen := Rect2(-14 * s, -10 * s + y, 28 * s, 18 * s)
	draw_rect(screen, Color(0.08, 0.12, 0.18))
	draw_rect(screen, Color(0.35, 0.55, 0.65), false, 2.0)
	# Pixel eyes + smile
	draw_rect(Rect2(-9 * s, -4 * s + y, 5 * s, 5 * s), accent)
	draw_rect(Rect2(4 * s, -4 * s + y, 5 * s, 5 * s), accent)
	draw_rect(Rect2(-6 * s, 4 * s + y, 12 * s, 2 * s), Color(0.55, 0.95, 0.85))

	# Head module
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-14 * s, -18 * s + y), Vector2(14 * s, -18 * s + y),
			Vector2(12 * s, -34 * s + y), Vector2(-12 * s, -34 * s + y),
		]),
		body.lightened(0.08),
	)
	# Antenna
	draw_line(Vector2(0, -34 * s + y), Vector2(0, -46 * s + y), body_dark, 3.0)
	draw_circle(Vector2(0, -48 * s + y), 4 * s, Color(1.0, 0.45, 0.35))
	if int(_bob * 3.0) % 2 == 0:
		draw_circle(Vector2(0, -48 * s + y), 2 * s, Color(1.0, 0.85, 0.4))

	# Arms
	for side: int in [-1, 1]:
		var ax: float = float(side) * 24.0 * s
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(ax, -6 * s + y), Vector2(ax + side * 8 * s, -6 * s + y),
				Vector2(ax + side * 6 * s, 8 * s + y), Vector2(ax, 6 * s + y),
			]),
			body_dark,
		)
		draw_circle(Vector2(ax + side * 9 * s, 9 * s + y), 3 * s, Color(0.55, 0.58, 0.62))


func _draw_shopkeeper_rose(s: float, bounce: float) -> void:
	var y := bounce
	var skin := Color(0.94, 0.76, 0.58)
	var skin_shade := skin.darkened(0.12)
	var hair := Color(0.45, 0.22, 0.18)
	var apron := Color(0.95, 0.55, 0.72)
	var dress := Color(0.72, 0.38, 0.58)

	# Legs / shoes
	draw_rect(Rect2(-9 * s, 10 * s + y, 7 * s, 14 * s), dress.darkened(0.15))
	draw_rect(Rect2(2 * s, 10 * s + y, 7 * s, 14 * s), dress.darkened(0.15))
	draw_rect(Rect2(-10 * s, 22 * s + y, 9 * s, 4 * s), Color(0.35, 0.22, 0.18))
	draw_rect(Rect2(1 * s, 22 * s + y, 9 * s, 4 * s), Color(0.35, 0.22, 0.18))

	# Dress skirt (¾ puff)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-16 * s, 10 * s + y), Vector2(16 * s, 10 * s + y),
			Vector2(20 * s, 24 * s + y), Vector2(-20 * s, 24 * s + y),
		]),
		dress,
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(4 * s, 10 * s + y), Vector2(16 * s, 10 * s + y),
			Vector2(20 * s, 24 * s + y), Vector2(8 * s, 24 * s + y),
		]),
		dress.darkened(0.12),
	)

	# Apron
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-10 * s, -2 * s + y), Vector2(10 * s, -2 * s + y),
			Vector2(12 * s, 22 * s + y), Vector2(-12 * s, 22 * s + y),
		]),
		apron,
	)
	draw_line(Vector2(-10 * s, -2 * s + y), Vector2(0, -14 * s + y), apron.darkened(0.1), 2.0)
	draw_line(Vector2(10 * s, -2 * s + y), Vector2(0, -14 * s + y), apron.darkened(0.1), 2.0)
	# Pocket
	draw_rect(Rect2(-5 * s, 8 * s + y, 10 * s, 8 * s), apron.darkened(0.08))
	draw_circle(Vector2(0, 12 * s + y), 2 * s, Color(0.98, 0.82, 0.35))

	# Torso / arms
	draw_rect(Rect2(-12 * s, -16 * s + y, 24 * s, 14 * s), apron.lightened(0.05))
	draw_circle(Vector2(-16 * s, -6 * s + y), 5 * s, skin)
	draw_circle(Vector2(16 * s, -6 * s + y), 5 * s, skin_shade)
	# Shopping bag
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(18 * s, 0 + y), Vector2(28 * s, 0 + y),
			Vector2(26 * s, 14 * s + y), Vector2(20 * s, 14 * s + y),
		]),
		Color(0.85, 0.65, 0.35),
	)
	draw_line(Vector2(20 * s, 0 + y), Vector2(23 * s, -6 * s + y), Color(0.55, 0.4, 0.22), 2.0)

	# Head
	draw_circle(Vector2(0, -28 * s + y), 13 * s, skin)
	draw_circle(Vector2(-4 * s, -30 * s + y), 2.5 * s, Color(0.12, 0.1, 0.08))
	draw_circle(Vector2(5 * s, -30 * s + y), 2.5 * s, Color(0.12, 0.1, 0.08))
	draw_circle(Vector2(-3 * s, -31 * s + y), 0.8 * s, Color(1, 1, 1, 0.9))
	draw_circle(Vector2(6 * s, -31 * s + y), 0.8 * s, Color(1, 1, 1, 0.9))
	# Smile
	draw_arc(Vector2(0, -24 * s + y), 4 * s, 0.1, PI - 0.1, 10, Color(0.55, 0.32, 0.28), 1.5)

	# Hair + bun + rose
	draw_circle(Vector2(0, -36 * s + y), 11 * s, hair)
	draw_circle(Vector2(0, -42 * s + y), 7 * s, hair.darkened(0.05))
	draw_circle(Vector2(8 * s, -40 * s + y), 4 * s, Color(0.95, 0.35, 0.55))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(6 * s, -44 * s + y), Vector2(10 * s, -44 * s + y),
			Vector2(9 * s, -38 * s + y),
		]),
		Color(0.45, 0.75, 0.35),
	)


# ─────────────────────────────────────────────────────────────
# CHESS TUTOR — a wise owl in a tiny scholar's robe
# ─────────────────────────────────────────────────────────────
func _draw_chess_tutor(s: float, bounce: float) -> void:
	var y := bounce
	var robe := Color(0.32, 0.22, 0.50)
	var robe_dark := Color(0.22, 0.14, 0.36)
	var feather := Color(0.78, 0.65, 0.50)
	var feather_dark := Color(0.62, 0.50, 0.38)
	var beak := Color(0.95, 0.75, 0.30)

	_draw_ellipse(Vector2(0, 22 * s + y), 22 * s, 6 * s, Color(0.10, 0.10, 0.18, 0.35))

	# Robe (¾ trapezoid)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-22 * s, -4 * s + y), Vector2(22 * s, -4 * s + y),
			Vector2(28 * s, 22 * s + y), Vector2(-28 * s, 22 * s + y),
		]),
		robe,
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(6 * s, -4 * s + y), Vector2(22 * s, -4 * s + y),
			Vector2(28 * s, 22 * s + y), Vector2(10 * s, 22 * s + y),
		]),
		robe_dark,
	)
	# Robe trim
	draw_rect(Rect2(-28 * s, 18 * s + y, 56 * s, 4 * s), Color(0.92, 0.78, 0.30))

	# Owl body / head
	draw_circle(Vector2(0, -16 * s + y), 18 * s, feather)
	draw_circle(Vector2(8 * s, -16 * s + y), 16 * s, feather_dark)
	# Tufts
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-14 * s, -28 * s + y), Vector2(-6 * s, -34 * s + y),
			Vector2(-8 * s, -22 * s + y),
		]),
		feather_dark,
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(14 * s, -28 * s + y), Vector2(6 * s, -34 * s + y),
			Vector2(8 * s, -22 * s + y),
		]),
		feather_dark,
	)
	# Eyes (big glasses)
	draw_circle(Vector2(-6 * s, -18 * s + y), 5 * s, Color(1, 1, 1, 0.95))
	draw_circle(Vector2(6 * s, -18 * s + y), 5 * s, Color(1, 1, 1, 0.95))
	draw_arc(Vector2(-6 * s, -18 * s + y), 5 * s, 0, TAU, 18, Color(0.15, 0.12, 0.18), 1.5)
	draw_arc(Vector2(6 * s, -18 * s + y), 5 * s, 0, TAU, 18, Color(0.15, 0.12, 0.18), 1.5)
	draw_line(Vector2(-1 * s, -18 * s + y), Vector2(1 * s, -18 * s + y), Color(0.15, 0.12, 0.18), 1.5)
	# Pupils
	draw_circle(Vector2(-6 * s, -18 * s + y), 2 * s, Color(0.12, 0.10, 0.18))
	draw_circle(Vector2(6 * s, -18 * s + y), 2 * s, Color(0.12, 0.10, 0.18))
	# Beak
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-3 * s, -12 * s + y), Vector2(3 * s, -12 * s + y),
			Vector2(0, -6 * s + y),
		]),
		beak,
	)

	# Wing holding a tiny chess pawn
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-26 * s, -2 * s + y), Vector2(-18 * s, 8 * s + y),
			Vector2(-22 * s, 16 * s + y),
		]),
		feather_dark,
	)
	# Pawn icon
	var pawn_base := Vector2(20 * s, 4 * s + y)
	draw_circle(pawn_base + Vector2(0, -8 * s), 4 * s, Color(0.95, 0.95, 0.95))
	draw_rect(Rect2(pawn_base.x - 4 * s, pawn_base.y - 4 * s, 8 * s, 8 * s), Color(0.95, 0.95, 0.95))


# ─────────────────────────────────────────────────────────────
# COACH KICK — a friendly soccer coach with whistle + ball
# ─────────────────────────────────────────────────────────────
func _draw_coach_kick(s: float, bounce: float) -> void:
	var y := bounce
	var skin := Color(0.85, 0.65, 0.48)
	var jersey := Color(0.18, 0.55, 0.30)
	var jersey_dark := Color(0.10, 0.40, 0.20)
	var shorts := Color(0.92, 0.92, 0.92)
	var sock := Color(0.95, 0.92, 0.25)

	_draw_ellipse(Vector2(0, 24 * s + y), 22 * s, 6 * s, Color(0.10, 0.16, 0.10, 0.32))

	# Legs / shoes
	draw_rect(Rect2(-9 * s, 14 * s + y, 7 * s, 12 * s), sock)
	draw_rect(Rect2(2 * s, 14 * s + y, 7 * s, 12 * s), sock)
	draw_rect(Rect2(-11 * s, 24 * s + y, 10 * s, 4 * s), Color(0.15, 0.15, 0.18))
	draw_rect(Rect2(1 * s, 24 * s + y, 10 * s, 4 * s), Color(0.15, 0.15, 0.18))

	# Shorts
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-14 * s, 0 + y), Vector2(14 * s, 0 + y),
			Vector2(16 * s, 14 * s + y), Vector2(-16 * s, 14 * s + y),
		]),
		shorts,
	)
	draw_rect(Rect2(-1 * s, 0 + y, 2 * s, 14 * s), shorts.darkened(0.1))

	# Jersey
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-16 * s, -14 * s + y), Vector2(16 * s, -14 * s + y),
			Vector2(14 * s, 4 * s + y), Vector2(-14 * s, 4 * s + y),
		]),
		jersey,
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(4 * s, -14 * s + y), Vector2(16 * s, -14 * s + y),
			Vector2(14 * s, 4 * s + y), Vector2(6 * s, 4 * s + y),
		]),
		jersey_dark,
	)
	# Jersey number
	draw_string(ThemeDB.fallback_font, Vector2(-3 * s, -2 * s + y), "9", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1))

	# Arms
	for side: int in [-1, 1]:
		var ax: float = float(side) * 18.0 * s
		draw_circle(Vector2(ax, -6 * s + y), 4 * s, skin)
		draw_circle(Vector2(ax, 4 * s + y), 4 * s, skin)

	# Head
	draw_circle(Vector2(0, -22 * s + y), 11 * s, skin)
	# Cap
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-12 * s, -28 * s + y), Vector2(12 * s, -28 * s + y),
			Vector2(10 * s, -36 * s + y), Vector2(-10 * s, -36 * s + y),
		]),
		jersey,
	)
	# Cap brim
	draw_rect(Rect2(-13 * s, -28 * s + y, 18 * s, 4 * s), jersey_dark)

	# Eyes + smile
	draw_circle(Vector2(-3 * s, -22 * s + y), 1.5 * s, Color(0.10, 0.08, 0.08))
	draw_circle(Vector2(4 * s, -22 * s + y), 1.5 * s, Color(0.10, 0.08, 0.08))
	draw_arc(Vector2(0, -18 * s + y), 3.5 * s, 0.2, PI - 0.2, 10, Color(0.45, 0.25, 0.18), 1.6)

	# Whistle on a string
	draw_line(Vector2(0, -14 * s + y), Vector2(8 * s, -2 * s + y), Color(0.8, 0.8, 0.85), 1.0)
	draw_circle(Vector2(8 * s, -2 * s + y), 3 * s, Color(0.95, 0.85, 0.30))

	# Soccer ball at foot
	var ball_c := Vector2(-22 * s, 22 * s + y)
	draw_circle(ball_c, 7 * s, Color(0.98, 0.98, 0.98))
	draw_arc(ball_c, 7 * s, 0, TAU, 16, Color(0.15, 0.15, 0.18), 1.2)
	draw_circle(ball_c + Vector2(-2 * s, -1 * s), 1.5 * s, Color(0.15, 0.15, 0.18))
	draw_circle(ball_c + Vector2(3 * s, 1 * s), 1.5 * s, Color(0.15, 0.15, 0.18))


# ─────────────────────────────────────────────────────────────
# ARTIST PIP — beret + palette
# ─────────────────────────────────────────────────────────────
func _draw_artist_pip(s: float, bounce: float) -> void:
	var y := bounce
	var skin := Color(0.96, 0.82, 0.68)
	var smock := Color(0.95, 0.95, 0.93)
	var smock_dark := Color(0.80, 0.80, 0.78)
	var pants := Color(0.32, 0.40, 0.55)
	var beret := Color(0.78, 0.22, 0.32)
	var hair := Color(0.30, 0.20, 0.18)

	_draw_ellipse(Vector2(0, 24 * s + y), 22 * s, 6 * s, Color(0.12, 0.12, 0.18, 0.30))

	# Pants / shoes
	draw_rect(Rect2(-10 * s, 8 * s + y, 8 * s, 18 * s), pants)
	draw_rect(Rect2(2 * s, 8 * s + y, 8 * s, 18 * s), pants)
	draw_rect(Rect2(-11 * s, 24 * s + y, 10 * s, 4 * s), Color(0.25, 0.18, 0.15))
	draw_rect(Rect2(1 * s, 24 * s + y, 10 * s, 4 * s), Color(0.25, 0.18, 0.15))

	# Smock
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-15 * s, -14 * s + y), Vector2(15 * s, -14 * s + y),
			Vector2(18 * s, 10 * s + y), Vector2(-18 * s, 10 * s + y),
		]),
		smock,
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(4 * s, -14 * s + y), Vector2(15 * s, -14 * s + y),
			Vector2(18 * s, 10 * s + y), Vector2(6 * s, 10 * s + y),
		]),
		smock_dark,
	)
	# Paint splotches
	draw_circle(Vector2(-8 * s, -2 * s + y), 2.5 * s, Color(0.95, 0.40, 0.55))
	draw_circle(Vector2(2 * s, 4 * s + y), 2.0 * s, Color(0.40, 0.75, 0.30))
	draw_circle(Vector2(-2 * s, -8 * s + y), 1.8 * s, Color(0.30, 0.55, 0.92))

	# Arms
	for side: int in [-1, 1]:
		var ax: float = float(side) * 18.0 * s
		draw_circle(Vector2(ax, -4 * s + y), 4 * s, skin)
		draw_circle(Vector2(ax, 6 * s + y), 4 * s, skin)

	# Head
	draw_circle(Vector2(0, -22 * s + y), 11 * s, skin)
	# Eyes + smile
	draw_circle(Vector2(-3 * s, -22 * s + y), 1.5 * s, Color(0.10, 0.08, 0.08))
	draw_circle(Vector2(4 * s, -22 * s + y), 1.5 * s, Color(0.10, 0.08, 0.08))
	draw_arc(Vector2(0, -18 * s + y), 3.5 * s, 0.2, PI - 0.2, 10, Color(0.55, 0.30, 0.25), 1.4)

	# Hair tuft
	draw_circle(Vector2(0, -32 * s + y), 11 * s, hair)
	# Beret (tilted disc + stem)
	draw_circle(Vector2(2 * s, -34 * s + y), 12 * s, beret)
	draw_circle(Vector2(2 * s, -34 * s + y), 12 * s, Color(0.55, 0.12, 0.20).lightened(0.05))
	draw_circle(Vector2(2 * s, -34 * s + y), 11 * s, beret)
	draw_circle(Vector2(7 * s, -40 * s + y), 2 * s, beret.darkened(0.18))

	# Palette in hand
	var pal := Vector2(-24 * s, 6 * s + y)
	draw_colored_polygon(
		PackedVector2Array([
			pal + Vector2(-10 * s, -3 * s), pal + Vector2(8 * s, -6 * s),
			pal + Vector2(10 * s, 4 * s), pal + Vector2(-6 * s, 8 * s),
		]),
		Color(0.90, 0.78, 0.55),
	)
	draw_circle(pal + Vector2(-3 * s, -1 * s), 1.5 * s, Color(0.95, 0.30, 0.40))
	draw_circle(pal + Vector2(2 * s, -2 * s), 1.5 * s, Color(0.95, 0.80, 0.25))
	draw_circle(pal + Vector2(5 * s, 2 * s), 1.5 * s, Color(0.30, 0.65, 0.95))
	# Brush
	draw_line(pal + Vector2(8 * s, -8 * s), pal + Vector2(16 * s, -16 * s), Color(0.55, 0.38, 0.22), 1.6)
	draw_circle(pal + Vector2(16 * s, -16 * s), 1.8 * s, Color(0.95, 0.30, 0.40))
