## SoftViewGround.gd — procedural grass + perspective path (¾-view placeholder art).
## Each area_style produces a distinct ground look so areas feel unique.
extends Node2D

@export_enum("start_area", "playground", "dog_pit") var area_style: String = "start_area"


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	match area_style:
		"playground":
			_draw_playground()
		"dog_pit":
			_draw_dog_pit()
		_:
			_draw_start_area()


# ── START AREA — lush green with a straight centre path ──────────────────────
func _draw_start_area() -> void:
	draw_colored_polygon(
		PackedVector2Array([Vector2(-860, -480), Vector2(860, -480), Vector2(860, 480), Vector2(-860, 480)]),
		Color(0.32, 0.62, 0.28),
	)
	# Lighter depth patches
	draw_colored_polygon(
		PackedVector2Array([Vector2(-520, -200), Vector2(-180, -200), Vector2(-120, 120), Vector2(-560, 80)]),
		Color(0.38, 0.70, 0.34, 0.45),
	)
	draw_colored_polygon(
		PackedVector2Array([Vector2(280, -80), Vector2(640, -40), Vector2(600, 260), Vector2(240, 200)]),
		Color(0.36, 0.68, 0.32, 0.35),
	)
	# Vertical centre path
	var path := PackedVector2Array([Vector2(-28, -480), Vector2(28, -480), Vector2(52, 480), Vector2(-52, 480)])
	draw_colored_polygon(path, Color(0.62, 0.52, 0.38))
	draw_line(Vector2(-28, -480), Vector2(-52, 480), Color(0.45, 0.36, 0.26, 0.5), 3.0)
	draw_line(Vector2(28, -480), Vector2(52, 480), Color(0.75, 0.65, 0.48, 0.4), 2.0)
	_draw_vignette()


# ── PLAYGROUND — brighter greens, diagonal winding path, varied patches ──────
func _draw_playground() -> void:
	# Brighter base grass
	draw_colored_polygon(
		PackedVector2Array([Vector2(-860, -480), Vector2(860, -480), Vector2(860, 480), Vector2(-860, 480)]),
		Color(0.38, 0.72, 0.30),
	)
	# Vibrant scattered patches — irregular feel
	var patches: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(-640, -360), Vector2(-280, -300), Vector2(-320, 80), Vector2(-680, 20)]),
		PackedVector2Array([Vector2(160, -260), Vector2(580, -220), Vector2(600, 140), Vector2(140, 160)]),
		PackedVector2Array([Vector2(-200, 120), Vector2(200, 160), Vector2(160, 380), Vector2(-240, 360)]),
		PackedVector2Array([Vector2(320, -60), Vector2(700, 0), Vector2(660, 280), Vector2(280, 240)]),
	]
	var patch_colors: Array[Color] = [
		Color(0.44, 0.78, 0.36, 0.50),
		Color(0.30, 0.65, 0.28, 0.40),
		Color(0.48, 0.82, 0.38, 0.45),
		Color(0.34, 0.70, 0.30, 0.38),
	]
	for i in patches.size():
		draw_colored_polygon(patches[i], patch_colors[i])

	# Diagonal path — winds from bottom-left toward top-right
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-320, 480), Vector2(-220, 480),
			Vector2(80, -480),  Vector2(-20, -480),
		]),
		Color(0.60, 0.50, 0.36),
	)
	# Path edges
	draw_line(Vector2(-320, 480), Vector2(-20, -480), Color(0.44, 0.34, 0.22, 0.5), 3.0)
	draw_line(Vector2(-220, 480), Vector2(80, -480),  Color(0.75, 0.65, 0.48, 0.4), 2.0)

	# Short crossing side-path (gives that park feel)
	draw_colored_polygon(
		PackedVector2Array([Vector2(-860, -20), Vector2(860, 40), Vector2(860, 68), Vector2(-860, 8)]),
		Color(0.60, 0.50, 0.36, 0.65),
	)
	_draw_vignette_tinted(Color(0.08, 0.20, 0.08, 0.18))


# ── DOG FIGHTING PIT — sandy dirt with rough worn patches ────────────────────
func _draw_dog_pit() -> void:
	# Sandy base
	draw_colored_polygon(
		PackedVector2Array([Vector2(-860, -480), Vector2(860, -480), Vector2(860, 480), Vector2(-860, 480)]),
		Color(0.68, 0.55, 0.38),
	)
	# Worn dark dirt patches
	var dirt: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(-400, -280), Vector2(0, -260), Vector2(20, 40), Vector2(-420, 60)]),
		PackedVector2Array([Vector2(80, -160), Vector2(500, -120), Vector2(480, 200), Vector2(60, 220)]),
		PackedVector2Array([Vector2(-600, 100), Vector2(-200, 80), Vector2(-180, 320), Vector2(-620, 340)]),
		PackedVector2Array([Vector2(200, 200), Vector2(680, 180), Vector2(700, 420), Vector2(180, 440)]),
	]
	for d in dirt:
		draw_colored_polygon(d, Color(0.52, 0.40, 0.26, 0.55))

	# Dry cracked lines across ground (drawn as thin rects)
	draw_line(Vector2(-860, -80), Vector2(200, -60), Color(0.40, 0.30, 0.18, 0.35), 2.0)
	draw_line(Vector2(-100, 160), Vector2(860, 180), Color(0.40, 0.30, 0.18, 0.30), 2.0)
	draw_line(Vector2(-300, -360), Vector2(-280, 200), Color(0.38, 0.28, 0.16, 0.25), 1.5)
	draw_line(Vector2(400, -200), Vector2(420, 400), Color(0.38, 0.28, 0.16, 0.25), 1.5)

	# Lighter sandy highlights
	draw_colored_polygon(
		PackedVector2Array([Vector2(-100, -100), Vector2(160, -120), Vector2(180, 80), Vector2(-80, 100)]),
		Color(0.80, 0.68, 0.50, 0.30),
	)
	_draw_vignette_tinted(Color(0.22, 0.14, 0.06, 0.20))


func _draw_vignette() -> void:
	_draw_vignette_tinted(Color(0.12, 0.22, 0.10, 0.18))


func _draw_vignette_tinted(col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-860, -480), Vector2(-500, -480), Vector2(-860, -200)]), col)
	draw_colored_polygon(PackedVector2Array([Vector2(860, -480), Vector2(500, -480), Vector2(860, -200)]), col)
	draw_colored_polygon(PackedVector2Array([Vector2(-860, 480), Vector2(-500, 480), Vector2(-860, 220)]), col)
	draw_colored_polygon(PackedVector2Array([Vector2(860, 480), Vector2(500, 480), Vector2(860, 220)]), col)
