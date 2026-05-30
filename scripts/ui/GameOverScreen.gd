## GameOverScreen.gd
## =============================================================
## Shown when the player is caught (e.g. by Ms. Huffy).
##
## Displays who caught them, a reminder that items collected
## since the last checkpoint are lost, and two buttons:
##   "Try Again"  — calls CheckpointManager.trigger_respawn()
##   "Main Menu"  — goes back to the main menu
##
## This node is a CanvasLayer so it always renders on top.
## process_mode is PROCESS_MODE_ALWAYS so buttons work while
## the game tree is paused.
##
## Instantiated and added as a child of the HUD by HUD.show_game_over().
## =============================================================
extends CanvasLayer

# ─────────────────────────────────────────────────────────────
# NODE REFERENCES — built dynamically in _build_ui()
# ─────────────────────────────────────────────────────────────
var _title_label: Label   = null
var _lost_label: Label    = null
var _try_again_btn: Button = null
var _main_menu_btn: Button = null


# ─────────────────────────────────────────────────────────────
# READY
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()


# ─────────────────────────────────────────────────────────────
# BUILD UI PROGRAMMATICALLY
# ─────────────────────────────────────────────────────────────
func _build_ui() -> void:
	# Dark semi-transparent overlay
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.65)
	add_child(overlay)

	# Centred panel
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.size = Vector2(480, 300)
	panel.position = Vector2(-240, -150)
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	# Spacer
	var top_gap := Control.new()
	top_gap.custom_minimum_size = Vector2(0, 16)
	vbox.add_child(top_gap)

	# Title
	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 26)
	_title_label.text = "😱 Oh no!"
	vbox.add_child(_title_label)

	# Lost items message
	_lost_label = Label.new()
	_lost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lost_label.add_theme_font_size_override("font_size", 14)
	_lost_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lost_label.text = "You lost tokens and items collected\nsince your last checkpoint save."
	vbox.add_child(_lost_label)

	# Spacer
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(gap)

	# Button row
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 24)
	vbox.add_child(hbox)

	_try_again_btn = Button.new()
	_try_again_btn.text = "🔄 Try Again"
	_try_again_btn.custom_minimum_size = Vector2(140, 44)
	_try_again_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	_try_again_btn.pressed.connect(_on_try_again)
	hbox.add_child(_try_again_btn)

	_main_menu_btn = Button.new()
	_main_menu_btn.text = "🏠 Main Menu"
	_main_menu_btn.custom_minimum_size = Vector2(140, 44)
	_main_menu_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	_main_menu_btn.pressed.connect(_on_main_menu)
	hbox.add_child(_main_menu_btn)

	_try_again_btn.grab_focus()


# ─────────────────────────────────────────────────────────────
# SHOW — called by HUD.show_game_over()
# ─────────────────────────────────────────────────────────────
func show_game_over(catcher_name: String) -> void:
	_title_label.text = "😱 Caught by %s!" % catcher_name
	get_tree().paused = true


# ─────────────────────────────────────────────────────────────
# BUTTON HANDLERS
# ─────────────────────────────────────────────────────────────
func _on_try_again() -> void:
	get_tree().paused = false
	CheckpointManager.trigger_respawn()


func _on_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")
