## GroomerPanel.gd
## =============================================================
## Daisy's groomer — change her haircut, outfit, and buy treats.
## Selections are saved to GameState (persist across scenes).
##
## Layout:
##   Left  — live Daisy preview (drawn with current options)
##   Right — tab buttons + item grid
## =============================================================
extends Control

# ─────────────────────────────────────────────────────────────
# CATALOGUE DEFINITIONS
# ─────────────────────────────────────────────────────────────
const HAIRCUTS: Array = [
	{"id": "fluffy",     "label": "Fluffy",     "cost": 0,  "desc": "Daisy's natural look"},
	{"id": "short",      "label": "Short Cut",  "cost": 5,  "desc": "Neat and tidy"},
	{"id": "mohawk",     "label": "Mohawk",     "cost": 10, "desc": "Punk rock style"},
	{"id": "puppy_cut",  "label": "Puppy Cut",  "cost": 8,  "desc": "Extra round and fluffy"},
]

const OUTFITS: Array = [
	{"id": "none",     "label": "None",     "cost": 0,  "desc": "Just her collar"},
	{"id": "bow",      "label": "Pink Bow",  "cost": 6,  "desc": "Cute bow on her head"},
	{"id": "bandana",  "label": "Bandana",   "cost": 8,  "desc": "Cool neck bandana"},
	{"id": "sweater",  "label": "Sweater",   "cost": 12, "desc": "Cosy knit sweater"},
	{"id": "vest",     "label": "Vest",      "cost": 10, "desc": "Sleek adventure vest"},
]

const TREATS: Array = [
	{"id": "energy_treat", "label": "Energy Treat", "cost": 3,
		"desc": "Daisy starts the next fight with +20 HP"},
	{"id": "focus_treat",  "label": "Focus Treat",  "cost": 5,
		"desc": "Daisy's bite cooldown is halved next fight"},
]

# ─────────────────────────────────────────────────────────────
# DOG DRAW COLOURS
# ─────────────────────────────────────────────────────────────
const C_FUR    := Color(1.00, 1.00, 1.00)
const C_EAR    := Color(0.90, 0.80, 0.70)
const C_NOSE   := Color(0.90, 0.55, 0.65)
const C_EYE    := Color(0.12, 0.08, 0.08)
const C_COLLAR := Color(1.00, 0.45, 0.10)

# Preview draw coordinates
const PREV_X: float = 90.0
const PREV_Y: float = 140.0

# ─────────────────────────────────────────────────────────────
# STATE
# ─────────────────────────────────────────────────────────────
var _active_tab:      String = "haircut"   # "haircut" | "outfit" | "treats"
var _selected_haircut: String = "fluffy"
var _selected_outfit:  String = "none"
var _caller: Node = null

# ─────────────────────────────────────────────────────────────
# NODE REFS
# ─────────────────────────────────────────────────────────────
@onready var preview:        Control     = $Panel/HBox/PreviewBox/Preview
@onready var tokens_label:   Label       = $Panel/HBox/ShopBox/TokensLabel
@onready var tab_haircut:    Button      = $Panel/HBox/ShopBox/Tabs/HaircutBtn
@onready var tab_outfit:     Button      = $Panel/HBox/ShopBox/Tabs/OutfitBtn
@onready var tab_treats:     Button      = $Panel/HBox/ShopBox/Tabs/TreatsBtn
@onready var item_container: VBoxContainer = $Panel/HBox/ShopBox/ItemScroll/ItemList
@onready var status_label:   Label       = $Panel/HBox/ShopBox/StatusLabel
@onready var close_button:   Button      = $Panel/HBox/ShopBox/CloseButton


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	if preview:
		preview.draw.connect(_on_preview_draw)
	tab_haircut.pressed.connect(func(): _switch_tab("haircut"))
	tab_outfit.pressed.connect(func():  _switch_tab("outfit"))
	tab_treats.pressed.connect(func():  _switch_tab("treats"))
	close_button.pressed.connect(_on_close_pressed)


func show_groomer(caller: Node) -> void:
	_caller          = caller
	_selected_haircut = GameState.daisy_haircut
	_selected_outfit  = GameState.daisy_outfit
	visible = true
	_switch_tab("haircut")
	_refresh_tokens()
	preview.queue_redraw()


func _switch_tab(tab: String) -> void:
	_active_tab = tab
	tab_haircut.button_pressed = (tab == "haircut")
	tab_outfit.button_pressed  = (tab == "outfit")
	tab_treats.button_pressed  = (tab == "treats")
	_rebuild_items()


func _rebuild_items() -> void:
	for child in item_container.get_children():
		child.queue_free()

	var catalogue: Array = []
	match _active_tab:
		"haircut": catalogue = HAIRCUTS
		"outfit":  catalogue = OUTFITS
		"treats":  catalogue = TREATS

	for item: Dictionary in catalogue:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)

		var lbl := Label.new()
		lbl.text = "%s  (%d VIBE)" % [item.label, item.cost]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", 13)
		row.add_child(lbl)

		var desc := Label.new()
		desc.text = item.desc
		desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc.add_theme_font_size_override("font_size", 11)
		desc.modulate = Color(0.75, 0.75, 0.75, 1)
		row.add_child(desc)

		var btn := Button.new()
		var is_active := false
		if _active_tab == "haircut":
			is_active = (_selected_haircut == item.id)
		elif _active_tab == "outfit":
			is_active = (_selected_outfit == item.id)

		btn.text = "Equipped" if is_active else ("Free" if item.cost == 0 else "Buy")
		btn.disabled = is_active
		btn.add_theme_font_size_override("font_size", 12)

		var id_copy: String = item.id
		var cost_copy: int = item.cost
		btn.pressed.connect(func(): _purchase(id_copy, cost_copy))
		row.add_child(btn)
		item_container.add_child(row)


func _purchase(item_id: String, cost: int) -> void:
	if cost > 0 and not GameState.spend_tokens(cost):
		if status_label:
			status_label.text = "❌ Not enough VIBE!"
		return

	match _active_tab:
		"haircut":
			_selected_haircut    = item_id
			GameState.daisy_haircut = item_id
			if status_label:
				status_label.text = "✅ Haircut changed!"
		"outfit":
			_selected_outfit    = item_id
			GameState.daisy_outfit = item_id
			if status_label:
				status_label.text = "✅ Outfit updated!"
		"treats":
			GameState.add_tokens(0)   # Just triggers token signal for UI refresh
			if status_label:
				status_label.text = "🦴 Treat bought for Daisy!"

	AudioManager.play_sfx("reward", 0.05)
	_refresh_tokens()
	_rebuild_items()
	if preview:
		preview.queue_redraw()


func _refresh_tokens() -> void:
	if tokens_label:
		tokens_label.text = "💰 %d VIBE" % GameState.vibe_tokens


# ─────────────────────────────────────────────────────────────
# PREVIEW DRAW — Daisy with selected haircut + outfit
# ─────────────────────────────────────────────────────────────
func _on_preview_draw() -> void:
	if not preview:
		return

	# Background
	preview.draw_rect(Rect2(0, 0, 180, 190), Color(0.90, 0.95, 0.88))
	preview.draw_rect(Rect2(0, PREV_Y, 180, 190 - PREV_Y), Color(0.72, 0.88, 0.62))

	var x := PREV_X
	var y := PREV_Y
	var s := 1.4   # Scale for the preview

	_preview_draw_daisy(x, y, s)
	_preview_draw_outfit(x, y, s)


func _preview_draw_daisy(x: float, y: float, s: float) -> void:
	# Shadow
	preview.draw_circle(Vector2(x, y + 6), 18.0 * s, Color(0, 0, 0, 0.18))
	# Tail
	preview.draw_circle(Vector2(x - 14 * s, y - 8 * s), 5.5 * s, C_FUR)
	# Body
	preview.draw_rect(Rect2(x - 12 * s, y - 11 * s, 26 * s, 13 * s), C_FUR)

	# Head — shape depends on haircut
	var head_r := 10.0 * s
	if GameState.daisy_haircut == "puppy_cut":
		head_r = 13.0 * s
	elif GameState.daisy_haircut == "short":
		head_r = 8.5 * s

	preview.draw_circle(Vector2(x + 12 * s, y - 9 * s), head_r, C_FUR)

	# Ear — style depends on haircut
	if GameState.daisy_haircut == "fluffy":
		preview.draw_rect(Rect2(x + 9 * s, y - 18 * s, 9 * s, 14 * s), C_EAR)
		preview.draw_circle(Vector2(x + 9 * s, y - 18 * s), 5.5 * s, C_EAR)
	elif GameState.daisy_haircut == "short":
		preview.draw_rect(Rect2(x + 11 * s, y - 16 * s, 7 * s, 9 * s), C_EAR)
	elif GameState.daisy_haircut == "mohawk":
		preview.draw_rect(Rect2(x + 9 * s, y - 16 * s, 9 * s, 12 * s), C_EAR)
		# Mohawk spikes
		for i in 3:
			var sx: float = x + (8.0 + i * 4.5) * s
			preview.draw_colored_polygon(PackedVector2Array([
				Vector2(sx, y - 20 * s),
				Vector2(sx + 3 * s, y - 30 * s - i * 3 * s),
				Vector2(sx + 6 * s, y - 20 * s),
			]), Color(0.85, 0.18, 0.18))
	elif GameState.daisy_haircut == "puppy_cut":
		preview.draw_circle(Vector2(x + 10 * s, y - 19 * s), 7.0 * s, C_EAR)
		preview.draw_circle(Vector2(x + 18 * s, y - 17 * s), 5.5 * s, C_EAR)

	preview.draw_circle(Vector2(x + 17 * s, y - 11 * s), 2.5 * s, C_EYE)
	preview.draw_circle(Vector2(x + 22 * s, y - 7 * s),  3.0 * s, C_NOSE)
	# Legs
	for i in 4:
		var lx: float = x + (float(i) * 7.0 - 10.0) * s
		preview.draw_rect(Rect2(lx, y + 2 * s, 5 * s, 9 * s), C_FUR)
	# Collar
	preview.draw_rect(Rect2(x + 3 * s, y - 15 * s, 14 * s, 4 * s), C_COLLAR)


func _preview_draw_outfit(x: float, y: float, s: float) -> void:
	match GameState.daisy_outfit:
		"bow":
			preview.draw_circle(Vector2(x + 9 * s, y - 18 * s), 5.0 * s, Color(1.0, 0.55, 0.75))
			preview.draw_circle(Vector2(x + 17 * s, y - 18 * s), 5.0 * s, Color(1.0, 0.55, 0.75))
			preview.draw_circle(Vector2(x + 13 * s, y - 18 * s), 3.0 * s, Color(1.0, 0.85, 0.92))
		"bandana":
			preview.draw_rect(Rect2(x + 2 * s, y - 14 * s, 16 * s, 5 * s), Color(0.85, 0.28, 0.22))
			preview.draw_colored_polygon(PackedVector2Array([
				Vector2(x + 8 * s,  y - 9 * s),
				Vector2(x + 12 * s, y - 9 * s),
				Vector2(x + 10 * s, y - 2 * s),
			]), Color(0.85, 0.28, 0.22))
		"sweater":
			preview.draw_rect(Rect2(x - 11 * s, y - 10 * s, 24 * s, 12 * s),
				Color(0.35, 0.55, 0.88, 0.88))
			# Ribbing lines
			for i in 3:
				var ry: float = y + (-8 + i * 4) * s
				preview.draw_line(
					Vector2(x - 10 * s, ry), Vector2(x + 12 * s, ry),
					Color(0.25, 0.42, 0.70, 0.55), 1.5)
		"vest":
			preview.draw_rect(Rect2(x - 10 * s, y - 10 * s, 10 * s, 12 * s),
				Color(0.22, 0.22, 0.22, 0.85))
			preview.draw_rect(Rect2(x + 2 * s,  y - 10 * s, 10 * s, 12 * s),
				Color(0.22, 0.22, 0.22, 0.85))
			# Pocket
			preview.draw_rect(Rect2(x - 8 * s, y - 4 * s, 5 * s, 5 * s),
				Color(0.35, 0.35, 0.35, 0.88))


func _on_close_pressed() -> void:
	AudioManager.play_sfx("click")
	visible = false
	if _caller and _caller.has_method("on_groomer_closed"):
		_caller.on_groomer_closed()
	var hud := get_parent()
	if hud and hud.has_method("close_all_panels"):
		hud.close_all_panels()
