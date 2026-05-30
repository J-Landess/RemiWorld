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
	{"name": "Short",     "style_id": "short"},
	{"name": "Long",      "style_id": "long"},
	{"name": "Curly",     "style_id": "curly"},
	{"name": "Ponytail",  "style_id": "ponytail"},
	{"name": "Bun",       "style_id": "bun"},
]

const OUTFIT_OPTIONS: Array = [
	{"name": "Blue",   "color_id": "blue"},
	{"name": "Red",    "color_id": "red"},
	{"name": "Green",  "color_id": "green"},
	{"name": "Yellow", "color_id": "yellow"},
	{"name": "Purple", "color_id": "purple"},
	{"name": "Pink",   "color_id": "pink"},
	{"name": "Teal",   "color_id": "teal"},
	{"name": "Orange", "color_id": "orange"},
	{"name": "White",  "color_id": "white"},
	{"name": "Black",  "color_id": "black"},
]

const SHOE_OPTIONS: Array = [
	{"name": "Black",  "color_id": "black"},
	{"name": "White",  "color_id": "white"},
	{"name": "Red",    "color_id": "red"},
	{"name": "Blue",   "color_id": "blue"},
	{"name": "Pink",   "color_id": "pink"},
	{"name": "Brown",  "color_id": "orange"},
]

# ─────────────────────────────────────────────────────────────
# CURRENT SELECTIONS
# ─────────────────────────────────────────────────────────────
var _skin_idx:    int = 2   # medium
var _hair_color_idx: int = 1
var _hair_style_idx: int = 0
var _outfit_idx:  int = 0
var _shoe_idx:    int = 0

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
	_add_section(options_vbox, "🎨 Skin Tone",    SKIN_OPTIONS,       _build_color_swatch.bind(true),  "_on_skin_selected")
	_add_section(options_vbox, "💇 Hair Style",   HAIR_STYLES,        _build_text_button,              "_on_hair_style_selected")
	_add_section(options_vbox, "🎨 Hair Colour",  HAIR_COLOR_OPTIONS, _build_color_swatch.bind(false), "_on_hair_color_selected")
	_add_section(options_vbox, "👕 Outfit Colour",OUTFIT_OPTIONS,     _build_color_swatch.bind(false), "_on_outfit_selected")
	_add_section(options_vbox, "👟 Shoe Colour",  SHOE_OPTIONS,       _build_color_swatch.bind(false), "_on_shoe_selected")

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


func _build_color_swatch(_is_skin: bool, option: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(38, 38)
	btn.tooltip_text = option.get("name", "")
	# Colour the button face using modulate
	var hex_or_id = option.get("hex", option.get("color_id", ""))
	if hex_or_id is Color:
		btn.modulate = hex_or_id
	elif option.has("color"):
		btn.modulate = option["color"]
	elif hex_or_id is String and (hex_or_id as String).is_valid_html_color():
		btn.modulate = Color(hex_or_id)
	elif hex_or_id is String and hex_or_id in AvatarRenderer.OUTFIT_COLORS:
		btn.modulate = AvatarRenderer.OUTFIT_COLORS[hex_or_id]
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
		"_on_skin_selected":       _skin_idx = index
		"_on_hair_style_selected": _hair_style_idx = index
		"_on_hair_color_selected": _hair_color_idx = index
		"_on_outfit_selected":     _outfit_idx = index
		"_on_shoe_selected":       _shoe_idx = index
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
		"skin_tone":    SKIN_OPTIONS[_skin_idx]["tone_id"],
		"hair_color":   HAIR_COLOR_OPTIONS[_hair_color_idx]["hex"],
		"hairstyle":    HAIR_STYLES[_hair_style_idx]["style_id"],
		"outfit_color": OUTFIT_OPTIONS[_outfit_idx]["color_id"],
		"shoe_color":   SHOE_OPTIONS[_shoe_idx]["color_id"],
	}


# ─────────────────────────────────────────────────────────────
# SAVE CONFIG AND ENTER THE WORLD
# ─────────────────────────────────────────────────────────────
func _on_enter_world_pressed() -> void:
	var config := _build_config()

	# Persist to AvatarManager
	AvatarManager.set_skin_tone(config["skin_tone"])
	AvatarManager.set_hair_color(config["hair_color"])
	AvatarManager.equip_item("hairstyle", config["hairstyle"])
	AvatarManager._config["outfit_color"] = config["outfit_color"]
	AvatarManager._config["shoe_color"]   = config["shoe_color"]

	GameState.avatar_created = true
	SaveManager.save_game()

	print("[AvatarCreation] Avatar saved. Entering the world!")
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	await tween.finished
	get_tree().change_scene_to_file(SCENE_START_AREA)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(SCENE_WELCOME)
