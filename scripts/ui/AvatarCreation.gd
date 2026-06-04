## AvatarCreation.gd
## =============================================================
## The Avatar Creation screen — build your character before
## entering Remi's World for the first time.
##
## Options:
##   Skin tone (5 colours)   Hair colour (8 colours)
##   Hair style (5 styles)   Outfit colour (10 colours)
##   Shoe colour (6 colours)
##
## A live preview updates as you click.
## "Enter the World!" saves the config and loads StartArea.
## =============================================================
extends Control

# ─────────────────────────────────────────────────────────────
# SCENE PATH
# ─────────────────────────────────────────────────────────────
const SCENE_START_AREA := "res://scenes/levels/v1_start_area/StartArea.tscn"
const SCENE_WELCOME    := "res://scenes/welcome/WelcomeScreen.tscn"

# ─────────────────────────────────────────────────────────────
# PALETTE DATA
# ─────────────────────────────────────────────────────────────
const SKIN_OPTIONS: Array = [
	{"name": "Light",        "color": Color(1.00, 0.87, 0.73), "tone_id": "light"},
	{"name": "Medium Light", "color": Color(0.94, 0.76, 0.55), "tone_id": "medium_light"},
	{"name": "Medium",       "color": Color(0.80, 0.60, 0.35), "tone_id": "medium"},
	{"name": "Medium Dark",  "color": Color(0.60, 0.40, 0.20), "tone_id": "medium_dark"},
	{"name": "Dark",         "color": Color(0.35, 0.22, 0.10), "tone_id": "dark"},
	{"name": "Warm",         "color": Color(0.90, 0.70, 0.45), "tone_id": "warm"},
	{"name": "Cool",         "color": Color(0.85, 0.75, 0.65), "tone_id": "cool"},
]

const HAIR_COLOR_OPTIONS: Array = [
	{"name": "Black",  "hex": "#2E1700"},
	{"name": "Dark",   "hex": "#4A2800"},
	{"name": "Brown",  "hex": "#8B5230"},
	{"name": "Blonde", "hex": "#D4A827"},
	{"name": "Red",    "hex": "#CC3010"},
	{"name": "Silver", "hex": "#CCCCCC"},
	{"name": "Purple", "hex": "#8833CC"},
	{"name": "Blue",   "hex": "#2288EE"},
]

const HAIR_STYLES: Array = [
	{"name": "Short",    "style_id": "short"},
	{"name": "Long",     "style_id": "long"},
	{"name": "Curly",    "style_id": "curly"},
	{"name": "Ponytail", "style_id": "ponytail"},
	{"name": "Bun",      "style_id": "bun"},
	{"name": "Afro",     "style_id": "afro"},
	{"name": "Spiky",    "style_id": "spiky"},
	{"name": "Buzz",     "style_id": "buzz"},
	{"name": "Mohawk",   "style_id": "mohawk"},
	{"name": "Braids",   "style_id": "braids"},
]

const OUTFIT_STYLE_OPTIONS: Array = [
	{"name": "T-Shirt",    "style_id": "casual"},
	{"name": "Fancy Coat", "style_id": "fancy_coat"},
]

const EYEWEAR_OPTIONS: Array = [
	{"name": "None",        "style_id": ""},
	{"name": "Sunglasses",  "style_id": "sunglasses"},
]

const HEADWEAR_OPTIONS: Array = [
	{"name": "None",       "style_id": ""},
	{"name": "Headphones", "style_id": "headphones"},
]

const FACIAL_HAIR_OPTIONS: Array = [
	{"name": "None",        "style_id": ""},
	{"name": "Stubble",     "style_id": "stubble"},
	{"name": "Mustache",    "style_id": "mustache"},
	{"name": "Goatee",      "style_id": "goatee"},
	{"name": "Short Beard", "style_id": "beard_short"},
	{"name": "Long Beard",  "style_id": "beard_long"},
]

const MAKEUP_OPTIONS: Array = [
	{"name": "None",  "style_id": ""},
	{"name": "Blush", "style_id": "blush"},
	{"name": "Lips",  "style_id": "lips"},
	{"name": "Glam",  "style_id": "glam"},
]

const VEHICLE_OPTIONS: Array = [
	{"name": "None",    "style_id": ""},
	{"name": "Scooter", "style_id": "scooter"},
]

const OUTFIT_OPTIONS: Array = [
	{"name": "Blue",   "color_id": "blue",   "color": Color(0.25, 0.45, 0.85)},
	{"name": "Red",    "color_id": "red",    "color": Color(0.85, 0.22, 0.28)},
	{"name": "Green",  "color_id": "green",  "color": Color(0.22, 0.70, 0.32)},
	{"name": "Yellow", "color_id": "yellow", "color": Color(0.90, 0.75, 0.15)},
	{"name": "Purple", "color_id": "purple", "color": Color(0.60, 0.22, 0.75)},
	{"name": "Pink",   "color_id": "pink",   "color": Color(0.95, 0.45, 0.70)},
	{"name": "Teal",   "color_id": "teal",   "color": Color(0.15, 0.65, 0.65)},
	{"name": "Orange", "color_id": "orange", "color": Color(0.95, 0.50, 0.15)},
	{"name": "White",  "color_id": "white",  "color": Color(0.92, 0.92, 0.92)},
	{"name": "Black",  "color_id": "black",  "color": Color(0.18, 0.18, 0.18)},
]

const SHOE_OPTIONS: Array = [
	{"name": "Black",  "color_id": "black",  "color": Color(0.18, 0.18, 0.18)},
	{"name": "White",  "color_id": "white",  "color": Color(0.92, 0.92, 0.92)},
	{"name": "Red",    "color_id": "red",    "color": Color(0.85, 0.22, 0.28)},
	{"name": "Blue",   "color_id": "blue",   "color": Color(0.25, 0.45, 0.85)},
	{"name": "Pink",   "color_id": "pink",   "color": Color(0.95, 0.45, 0.70)},
	{"name": "Brown",  "color_id": "orange", "color": Color(0.55, 0.30, 0.10)},
]

# ─────────────────────────────────────────────────────────────
# CURRENT SELECTIONS
# ─────────────────────────────────────────────────────────────
var _skin_idx:         int = 2
var _hair_color_idx:   int = 1
var _hair_style_idx:   int = 0
var _outfit_idx:       int = 0
var _shoe_idx:         int = 0
var _outfit_style_idx: int = 0
var _eyewear_idx:      int = 0
var _headwear_idx:     int = 0
var _facial_hair_idx:  int = 0
var _makeup_idx:       int = 0
var _vehicle_idx:      int = 0

# Reference to the live preview renderer
var _renderer: Node2D = null

# ─────────────────────────────────────────────────────────────
# READY — build the entire UI in code for maximum flexibility
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	# Fade in
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

	_build_ui()
	_refresh_preview()
	print("[AvatarCreation] Avatar creation screen ready.")


func _build_ui() -> void:
	# ── BACKGROUND ──────────────────────────────────────────
	var bg := ColorRect.new()
	bg.color = Color(0.10, 0.08, 0.22)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# ── TITLE ───────────────────────────────────────────────
	var title := Label.new()
	title.text = "🎨 Create Your Avatar"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.modulate = Color(1.0, 0.9, 0.3)
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 16
	title.offset_bottom = 60
	add_child(title)

	# ── MAIN CONTENT: PREVIEW LEFT + OPTIONS RIGHT ──────────
	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_top = 70
	hbox.offset_bottom = -80
	hbox.offset_left = 20
	hbox.offset_right = -20
	hbox.add_theme_constant_override("separation", 20)
	add_child(hbox)

	# ── LEFT: PREVIEW PANEL ─────────────────────────────────
	var preview_panel := PanelContainer.new()
	preview_panel.custom_minimum_size = Vector2(260, 0)
	preview_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	hbox.add_child(preview_panel)

	var preview_vbox := VBoxContainer.new()
	preview_panel.add_child(preview_vbox)

	var preview_title := Label.new()
	preview_title.text = "Preview"
	preview_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_title.add_theme_font_size_override("font_size", 18)
	preview_vbox.add_child(preview_title)

	# The preview viewport/container — centred in a fixed-size area
	var preview_area := Control.new()
	preview_area.custom_minimum_size = Vector2(240, 320)
	preview_vbox.add_child(preview_area)

	# Load and instantiate the renderer
	var renderer_script := load("res://scripts/player/AvatarRenderer.gd")
	_renderer = Node2D.new()
	_renderer.set_script(renderer_script)
	_renderer.position = Vector2(120, 200)  # centre of the preview area
	_renderer.figure_scale = 2.5
	preview_area.add_child(_renderer)

	# Name display under preview
	var name_label := Label.new()
	name_label.text = GameState.player_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.modulate = Color(1.0, 0.9, 0.5)
	preview_vbox.add_child(name_label)

	# ── RIGHT: OPTIONS PANEL ────────────────────────────────
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(scroll)

	var options_vbox := VBoxContainer.new()
	options_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options_vbox.add_theme_constant_override("separation", 16)
	scroll.add_child(options_vbox)

	# Build each section
	_add_section(options_vbox, "🎨 Skin Tone",     SKIN_OPTIONS,       _build_color_swatch, "_on_skin_selected")
	_add_section(options_vbox, "💇 Hair Style",    HAIR_STYLES,        _build_text_button,  "_on_hair_style_selected")
	_add_section(options_vbox, "🎨 Hair Colour",   HAIR_COLOR_OPTIONS, _build_color_swatch, "_on_hair_color_selected")
	_add_section(options_vbox, "👕 Outfit Colour", OUTFIT_OPTIONS,       _build_color_swatch, "_on_outfit_selected")
	_add_section(options_vbox, "🧥 Jacket Style",  OUTFIT_STYLE_OPTIONS, _build_text_button,  "_on_outfit_style_selected")
	_add_section(options_vbox, "👟 Shoe Colour",   SHOE_OPTIONS,         _build_color_swatch, "_on_shoe_selected")
	_add_section(options_vbox, "😎 Eyewear",       EYEWEAR_OPTIONS,      _build_text_button,  "_on_eyewear_selected")
	_add_section(options_vbox, "🎧 Headwear",      HEADWEAR_OPTIONS,     _build_text_button,  "_on_headwear_selected")
	if GameState.player_sex == "girl":
		_add_section(options_vbox, "💄 Makeup", MAKEUP_OPTIONS, _build_text_button, "_on_makeup_selected")
	elif GameState.player_sex == "boy":
		_add_section(options_vbox, "🧔 Facial Hair", FACIAL_HAIR_OPTIONS, _build_text_button, "_on_facial_hair_selected")
	else:
		_add_section(options_vbox, "💄 Makeup", MAKEUP_OPTIONS, _build_text_button, "_on_makeup_selected")
		_add_section(options_vbox, "🧔 Facial Hair", FACIAL_HAIR_OPTIONS, _build_text_button, "_on_facial_hair_selected")
	_add_section(options_vbox, "🛴 Ride", VEHICLE_OPTIONS, _build_text_button, "_on_vehicle_selected")

	# ── BOTTOM BUTTONS ──────────────────────────────────────
	var bottom := HBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -72
	bottom.offset_bottom = -8
	bottom.offset_left = 20
	bottom.offset_right = -20
	bottom.add_theme_constant_override("separation", 16)
	add_child(bottom)

	var btn_back := Button.new()
	btn_back.text = "← Back"
	btn_back.custom_minimum_size = Vector2(130, 55)
	btn_back.add_theme_font_size_override("font_size", 18)
	btn_back.pressed.connect(_on_back_pressed)
	bottom.add_child(btn_back)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(spacer)

	var btn_enter := Button.new()
	btn_enter.text = "🚀  Enter the World!"
	btn_enter.custom_minimum_size = Vector2(260, 55)
	btn_enter.add_theme_font_size_override("font_size", 22)
	btn_enter.pressed.connect(_on_enter_world_pressed)
	bottom.add_child(btn_enter)


# ─────────────────────────────────────────────────────────────
# SECTION BUILDER HELPERS
# ─────────────────────────────────────────────────────────────
func _add_section(parent: Control, label_text: String, options: Array,
		button_builder: Callable, _callback: String) -> void:
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 6)
	parent.add_child(section)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.modulate = Color(0.9, 0.9, 1.0)
	section.add_child(lbl)

	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	section.add_child(flow)

	for i in range(options.size()):
		var btn: Button = button_builder.call(options[i])
		btn.pressed.connect(_on_option_button_pressed.bind(_callback, i))
		flow.add_child(btn)


func _build_color_swatch(option: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(38, 38)
	btn.tooltip_text = option.get("name", "")
	# Every option now has either "color" (Color) or "hex" (String).
	# No cross-script lookup needed.
	if option.has("color"):
		btn.modulate = option["color"]
	elif option.has("hex"):
		var hex: String = option["hex"]
		if hex.is_valid_html_color():
			btn.modulate = Color(hex)
	return btn


func _build_text_button(option: Dictionary) -> Button:
	var btn := Button.new()
	btn.text = option.get("name", "?")
	btn.custom_minimum_size = Vector2(90, 36)
	btn.add_theme_font_size_override("font_size", 14)
	return btn


# ─────────────────────────────────────────────────────────────
# OPTION SELECTED
# ─────────────────────────────────────────────────────────────
func _on_option_button_pressed(callback: String, index: int) -> void:
	match callback:
		"_on_skin_selected":        _skin_idx = index
		"_on_hair_style_selected":  _hair_style_idx = index
		"_on_hair_color_selected":  _hair_color_idx = index
		"_on_outfit_selected":      _outfit_idx = index
		"_on_shoe_selected":        _shoe_idx = index
		"_on_outfit_style_selected": _outfit_style_idx = index
		"_on_eyewear_selected":     _eyewear_idx = index
		"_on_headwear_selected":    _headwear_idx = index
		"_on_facial_hair_selected": _facial_hair_idx = index
		"_on_makeup_selected":      _makeup_idx = index
		"_on_vehicle_selected":     _vehicle_idx = index
	_refresh_preview()


# ─────────────────────────────────────────────────────────────
# REFRESH THE LIVE PREVIEW
# ─────────────────────────────────────────────────────────────
func _refresh_preview() -> void:
	if _renderer == null:
		return

	var config := _build_config()
	_renderer.apply_config(config)


func _build_config() -> Dictionary:
	return {
		"skin_tone":     SKIN_OPTIONS[_skin_idx]["tone_id"],
		"hair_color":    HAIR_COLOR_OPTIONS[_hair_color_idx]["hex"],
		"hairstyle":     HAIR_STYLES[_hair_style_idx]["style_id"],
		"outfit_color":  OUTFIT_OPTIONS[_outfit_idx]["color_id"],
		"shoe_color":    SHOE_OPTIONS[_shoe_idx]["color_id"],
		"outfit_style":  OUTFIT_STYLE_OPTIONS[_outfit_style_idx]["style_id"],
		"eyewear":       EYEWEAR_OPTIONS[_eyewear_idx]["style_id"],
		"headwear":      HEADWEAR_OPTIONS[_headwear_idx]["style_id"],
		"facial_hair":   FACIAL_HAIR_OPTIONS[_facial_hair_idx]["style_id"],
		"makeup":        MAKEUP_OPTIONS[_makeup_idx]["style_id"],
		"vehicle":       VEHICLE_OPTIONS[_vehicle_idx]["style_id"],
	}


# ─────────────────────────────────────────────────────────────
# SAVE CONFIG AND ENTER THE WORLD
# ─────────────────────────────────────────────────────────────
func _on_enter_world_pressed() -> void:
	var config := _build_config()

	# Persist to AvatarManager
	AvatarManager.set_skin_tone(config["skin_tone"])
	AvatarManager.set_hair_color(config["hair_color"])
	for key in ["hairstyle", "outfit_color", "shoe_color", "outfit_style",
			"eyewear", "headwear", "facial_hair", "makeup", "vehicle"]:
		AvatarManager._config[key] = config[key]
	AvatarManager.emit_signal("avatar_updated", AvatarManager.get_config())

	GameState.avatar_created = true
	SaveManager.save_game()

	print("[AvatarCreation] Avatar saved. Entering the world!")
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	await tween.finished
	get_tree().change_scene_to_file(SCENE_START_AREA)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(SCENE_WELCOME)
