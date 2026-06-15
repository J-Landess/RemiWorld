## StoreItemPreview.gd
## Draws a small procedural preview icon for each store item.
## Attach this Node2D as a SubViewport child or use in a Control wrapper.
extends Node2D

var item_id: String = ""


func setup(id: String) -> void:
	item_id = id
	queue_redraw()


func _draw() -> void:
	match item_id:
		"pink_sneakers":
			_draw_sneakers()
		"star_hair_clip":
			_draw_star_clip()
		"sparkle_shirt":
			_draw_sparkle_shirt()
		"rainbow_backpack":
			_draw_rainbow_backpack()
		_:
			draw_rect(Rect2(-30, -20, 60, 40), Color(0.7, 0.7, 0.8))


# ── Pink Sneakers ─────────────────────────────────────────────────────────────
func _draw_sneakers() -> void:
	# Left shoe
	var lx := -22.0
	var ly := 6.0
	_draw_one_shoe(lx, ly, Color(0.95, 0.45, 0.70), false)
	# Right shoe (slightly offset)
	var rx := 2.0
	var ry := 10.0
	_draw_one_shoe(rx, ry, Color(0.90, 0.35, 0.62), true)


func _draw_one_shoe(x: float, y: float, col: Color, flip: bool) -> void:
	var dir := -1.0 if flip else 1.0
	# Sole
	draw_colored_polygon(PackedVector2Array([
		Vector2(x, y + 10), Vector2(x + dir * 28, y + 10),
		Vector2(x + dir * 28, y + 14), Vector2(x, y + 14),
	]), Color(0.88, 0.88, 0.92))
	# Body
	draw_colored_polygon(PackedVector2Array([
		Vector2(x, y), Vector2(x + dir * 24, y),
		Vector2(x + dir * 28, y + 8), Vector2(x, y + 10),
	]), col)
	# Toe cap highlight
	draw_colored_polygon(PackedVector2Array([
		Vector2(x + dir * 18, y), Vector2(x + dir * 24, y),
		Vector2(x + dir * 28, y + 8), Vector2(x + dir * 22, y + 4),
	]), col.lightened(0.2))
	# Lace (white cross)
	draw_line(Vector2(x + dir * 6, y + 1), Vector2(x + dir * 16, y + 7), Color(1, 1, 1, 0.85), 1.2)
	draw_line(Vector2(x + dir * 6, y + 7), Vector2(x + dir * 16, y + 1), Color(1, 1, 1, 0.85), 1.2)


# ── Star Hair Clip ────────────────────────────────────────────────────────────
func _draw_star_clip() -> void:
	var gold := Color(1.0, 0.85, 0.15)
	var gold_dark := Color(0.85, 0.65, 0.05)
	# Clip base bar
	draw_rect(Rect2(-22, 8, 44, 6), gold_dark)
	draw_rect(Rect2(-22, 8, 44, 3), gold.lightened(0.15))
	# Star (5-pointed)
	var pts := PackedVector2Array()
	for i in 10:
		var angle := TAU * float(i) / 10.0 - PI / 2.0
		var r := 22.0 if i % 2 == 0 else 10.0
		pts.append(Vector2(cos(angle) * r, sin(angle) * r - 2))
	draw_colored_polygon(pts, gold)
	# Star inner shine
	var shine := PackedVector2Array()
	for i in 10:
		var angle := TAU * float(i) / 10.0 - PI / 2.0
		var r := 10.0 if i % 2 == 0 else 5.0
		shine.append(Vector2(cos(angle) * r, sin(angle) * r - 2))
	draw_colored_polygon(shine, gold.lightened(0.35))


# ── Sparkle Shirt ─────────────────────────────────────────────────────────────
func _draw_sparkle_shirt() -> void:
	var shirt := Color(0.50, 0.30, 0.85)
	var shirt_dark := shirt.darkened(0.18)

	# Body
	draw_colored_polygon(PackedVector2Array([
		Vector2(-18, -6), Vector2(18, -6),
		Vector2(22, 22), Vector2(-22, 22),
	]), shirt)
	# Right panel shade
	draw_colored_polygon(PackedVector2Array([
		Vector2(4, -6), Vector2(18, -6),
		Vector2(22, 22), Vector2(8, 22),
	]), shirt_dark)
	# Left sleeve
	draw_colored_polygon(PackedVector2Array([
		Vector2(-18, -6), Vector2(-30, -2),
		Vector2(-28, 10), Vector2(-18, 8),
	]), shirt)
	# Right sleeve
	draw_colored_polygon(PackedVector2Array([
		Vector2(18, -6), Vector2(30, -2),
		Vector2(28, 10), Vector2(18, 8),
	]), shirt_dark)
	# Collar V-neck
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8, -6), Vector2(8, -6), Vector2(0, 6),
	]), shirt.lightened(0.12))
	# Sparkle dots
	for sp: Array in [[-10, 4], [6, 2], [-4, 14], [12, 12], [-14, 16], [2, 18]]:
		draw_circle(Vector2(sp[0], sp[1]), 1.8, Color(1.0, 1.0, 1.0, 0.85))
		draw_circle(Vector2(sp[0], sp[1] - 3), 0.8, Color(1.0, 1.0, 0.7, 0.6))


# ── Rainbow Backpack ──────────────────────────────────────────────────────────
func _draw_rainbow_backpack() -> void:
	var bag := Color(0.92, 0.92, 0.92)
	# Main bag body
	draw_colored_polygon(PackedVector2Array([
		Vector2(-20, -22), Vector2(20, -22),
		Vector2(22, 20), Vector2(-22, 20),
	]), bag)
	# Right-side shade
	draw_colored_polygon(PackedVector2Array([
		Vector2(6, -22), Vector2(20, -22),
		Vector2(22, 20), Vector2(8, 20),
	]), bag.darkened(0.1))
	# Rounded top
	draw_arc(Vector2(0, -22), 20, PI, TAU, 12, bag, 20.0)
	# Rainbow stripes (7 colors)
	var colors: Array[Color] = [
		Color(0.95, 0.20, 0.20),  # red
		Color(0.98, 0.58, 0.10),  # orange
		Color(0.98, 0.92, 0.10),  # yellow
		Color(0.25, 0.78, 0.30),  # green
		Color(0.18, 0.55, 0.95),  # blue
		Color(0.45, 0.22, 0.85),  # indigo
		Color(0.75, 0.35, 0.92),  # violet
	]
	var stripe_h := 4.0
	var y_start := -18.0
	for i in colors.size():
		var sy := y_start + float(i) * stripe_h
		draw_rect(Rect2(-18, sy, 36, stripe_h - 0.5), colors[i])
	# Pocket flap
	draw_rect(Rect2(-16, 4, 32, 14), bag.darkened(0.05))
	draw_rect(Rect2(-16, 4, 32, 3), bag.lightened(0.1))
	# Zipper pull
	draw_circle(Vector2(0, 18), 3, Color(0.75, 0.75, 0.80))
	# Shoulder straps (behind bag, two vertical bands at top)
	draw_rect(Rect2(-22, -18, 6, 38), Color(0.82, 0.82, 0.85, 0.7))
	draw_rect(Rect2(16, -18, 6, 38), Color(0.78, 0.78, 0.82, 0.7))
