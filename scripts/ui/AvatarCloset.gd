## AvatarCloset.gd
## =============================================================
## The Avatar Closet lets players customize their character's look.
##
## Features:
##   - Shows owned clothing and accessory items
##   - Lets players equip or unequip items
##   - Shows a 2D avatar preview
##   - Locked items appear grayed out
##
## Future 3D Note: This system maps to a 3D avatar later.
## See: docs/3d_avatar_roadmap.md
##
## Attached to: scenes/ui/HUD.tscn → AvatarCloset node
## Node type: Control
## =============================================================
extends Control

# ─────────────────────────────────────────────────────────────
# NODE REFERENCES
# ─────────────────────────────────────────────────────────────
@onready var close_button: Button       = $Panel/HBoxContainer/RightPanel/TopBar/CloseButton
@onready var avatar_preview: Control    = $Panel/HBoxContainer/LeftPanel/AvatarPreview
@onready var skin_tone_options: HBoxContainer = $Panel/HBoxContainer/LeftPanel/SkinToneRow
@onready var outfit_grid: GridContainer = $Panel/HBoxContainer/RightPanel/TabContainer/Outfits/ItemGrid
@onready var accessory_grid: GridContainer = $Panel/HBoxContainer/RightPanel/TabContainer/Accessories/ItemGrid
@onready var status_label: Label        = $Panel/HBoxContainer/RightPanel/StatusLabel

# ─────────────────────────────────────────────────────────────
# AVATAR PREVIEW COLORS
# ─────────────────────────────────────────────────────────────
const SKIN_TONE_COLORS: Dictionary = {
	"light":       Color(1.0, 0.87, 0.73),
	"medium_light": Color(0.94, 0.76, 0.55),
	"medium":      Color(0.8, 0.60, 0.35),
	"medium_dark": Color(0.6, 0.40, 0.20),
	"dark":        Color(0.35, 0.22, 0.10),
	"warm":        Color(0.9, 0.70, 0.45),
	"cool":        Color(0.85, 0.75, 0.65),
}


# ─────────────────────────────────────────────────────────────
# READY
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	visible = false

	if close_button:
		close_button.pressed.connect(_on_close_pressed)

	# Connect to avatar updates
	AvatarManager.avatar_updated.connect(_on_avatar_updated)
	InventoryManager.inventory_updated.connect(refresh)


# ─────────────────────────────────────────────────────────────
# REFRESH — rebuild the closet UI
# ─────────────────────────────────────────────────────────────
func refresh() -> void:
	if not visible:
		return

	_refresh_avatar_preview()
	_refresh_skin_tones()
	_refresh_clothing_grid()
	_refresh_accessory_grid()


# ─────────────────────────────────────────────────────────────
# AVATAR PREVIEW (2D placeholder)
# ─────────────────────────────────────────────────────────────
func _refresh_avatar_preview() -> void:
	if not avatar_preview:
		return

	var config := AvatarManager.get_config()
	var skin_tone: String = config.get("skin_tone", "medium")
	var skin_color: Color = SKIN_TONE_COLORS.get(skin_tone, Color(0.8, 0.60, 0.35))

	# Find the avatar body color rect and update it
	var body_rect := avatar_preview.get_node_or_null("BodyRect")
	if body_rect:
		body_rect.color = skin_color

	# Update outfit color based on what's equipped
	var outfit_id: String = config.get("outfit", "")
	var outfit_rect := avatar_preview.get_node_or_null("OutfitRect")
	if outfit_rect:
		if outfit_id == "sparkle_shirt":
			outfit_rect.color = Color(0.6, 0.3, 0.8)  # Purple sparkle
		elif outfit_id == "default_outfit":
			outfit_rect.color = Color(0.3, 0.5, 0.9)  # Default blue
		else:
			outfit_rect.color = Color(0.5, 0.5, 0.5)  # Unknown = gray


# ─────────────────────────────────────────────────────────────
# SKIN TONE SELECTOR
# ─────────────────────────────────────────────────────────────
func _refresh_skin_tones() -> void:
	if not skin_tone_options:
		return

	for child in skin_tone_options.get_children():
		child.queue_free()

	var current_tone: String = AvatarManager.get_config().get("skin_tone", "medium")

	for tone_id in AvatarManager.SKIN_TONES:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(36, 36)
		btn.tooltip_text = tone_id.replace("_", " ").capitalize()

		# Color the button to match the skin tone
		var color: Color = SKIN_TONE_COLORS.get(tone_id, Color.GRAY)
		btn.modulate = color

		if tone_id == current_tone:
			btn.text = "✓"  # Mark selected

		btn.pressed.connect(AvatarManager.set_skin_tone.bind(tone_id))
		skin_tone_options.add_child(btn)


# ─────────────────────────────────────────────────────────────
# CLOTHING GRID
# ─────────────────────────────────────────────────────────────
func _refresh_clothing_grid() -> void:
	if not outfit_grid:
		return

	for child in outfit_grid.get_children():
		child.queue_free()

	var clothes := InventoryManager.get_items_by_category("Clothes")
	if clothes.is_empty():
		var label := Label.new()
		label.text = "No clothes yet!\nBuy some at the store. 🛍️"
		outfit_grid.add_child(label)
		return

	for item in clothes:
		outfit_grid.add_child(_make_closet_card(item, "outfit"))


# ─────────────────────────────────────────────────────────────
# ACCESSORY GRID
# ─────────────────────────────────────────────────────────────
func _refresh_accessory_grid() -> void:
	if not accessory_grid:
		return

	for child in accessory_grid.get_children():
		child.queue_free()

	var accessories := InventoryManager.get_items_by_category("Accessories")
	if accessories.is_empty():
		var label := Label.new()
		label.text = "No accessories yet!\nBuy some at the store. 🛍️"
		accessory_grid.add_child(label)
		return

	for item in accessories:
		accessory_grid.add_child(_make_closet_card(item, item.get("avatar_slot", "accessory")))


# ─────────────────────────────────────────────────────────────
# CLOSET CARD — one item in the closet
# ─────────────────────────────────────────────────────────────
func _make_closet_card(item: Dictionary, slot: String) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(110, 140)

	var vbox := VBoxContainer.new()
	card.add_child(vbox)

	# Color preview
	var color_rect := ColorRect.new()
	color_rect.custom_minimum_size = Vector2(80, 80)
	color_rect.color = Color(randf_range(0.3, 0.9), randf_range(0.3, 0.9), randf_range(0.3, 0.9))
	color_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(color_rect)

	# Name
	var name_label := Label.new()
	name_label.text = item.get("name", "?")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(name_label)

	# Equip/Unequip button
	var item_id: String = item.get("item_id", "")
	var is_equipped: bool = AvatarManager.is_item_equipped(item_id)

	var equip_btn := Button.new()
	equip_btn.text = "✅ On" if is_equipped else "Equip"
	equip_btn.pressed.connect(_on_equip_item.bind(item_id, slot, equip_btn))
	vbox.add_child(equip_btn)

	return card


# ─────────────────────────────────────────────────────────────
# EQUIP HANDLER
# ─────────────────────────────────────────────────────────────
func _on_equip_item(item_id: String, slot: String, button: Button) -> void:
	if AvatarManager.is_item_equipped(item_id):
		AvatarManager.unequip_slot(slot)
		button.text = "Equip"
		if status_label:
			status_label.text = "Unequipped!"
	else:
		AvatarManager.equip_item(slot, item_id)
		button.text = "✅ On"
		if status_label:
			status_label.text = "Equipped! Looking great! 🌟"

	SaveManager.save_game()
	_refresh_avatar_preview()


# ─────────────────────────────────────────────────────────────
# SIGNAL HANDLERS
# ─────────────────────────────────────────────────────────────
func _on_avatar_updated(_config: Dictionary) -> void:
	_refresh_avatar_preview()


func _on_close_pressed() -> void:
	var hud := get_parent()
	if hud and hud.has_method("close_all_panels"):
		hud.close_all_panels()
	else:
		visible = false
