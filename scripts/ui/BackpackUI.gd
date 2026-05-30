## BackpackUI.gd
## =============================================================
## The Backpack screen — shows everything the player owns.
##
## Tabs:
##   Tokens | NFTs | Clothes | Accessories | Quest Items | Badges
##
## Opened by pressing B or through the HUD.
##
## Attached to: scenes/ui/HUD.tscn → BackpackUI node
## Node type: Control
## =============================================================
extends Control

# ─────────────────────────────────────────────────────────────
# NODE REFERENCES
# ─────────────────────────────────────────────────────────────
@onready var close_button: Button     = $Panel/VBoxContainer/TopBar/CloseButton
@onready var token_display: Label     = $Panel/VBoxContainer/TopBar/TokenDisplay
@onready var tab_container: TabContainer = $Panel/VBoxContainer/TabContainer
@onready var item_grid_template: GridContainer = $Panel/VBoxContainer/TabContainer/Clothes/ItemGrid

# ─────────────────────────────────────────────────────────────
# ITEM CARD SCENE — each item in the grid
# (In future versions this would be a separate PackedScene)
# ─────────────────────────────────────────────────────────────
const RARITY_COLORS: Dictionary = {
	"common":    Color(0.8, 0.8, 0.8),   # Gray
	"uncommon":  Color(0.2, 0.8, 0.2),   # Green
	"rare":      Color(0.2, 0.4, 1.0),   # Blue
	"epic":      Color(0.7, 0.2, 1.0),   # Purple
	"legendary": Color(1.0, 0.6, 0.0),   # Orange/Gold
	"secret":    Color(1.0, 0.2, 0.4),   # Red/Pink
}

# Track which tab index corresponds to which category
const TAB_CATEGORIES: Array = [
	"Tokens",
	"NFTs",
	"Clothes",
	"Accessories",
	"Quest Items",
	"Badges",
]


# ─────────────────────────────────────────────────────────────
# CALLED WHEN THE NODE IS READY
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

	# Connect to inventory updates so we auto-refresh
	InventoryManager.inventory_updated.connect(refresh)

	# Start hidden
	visible = false


# ─────────────────────────────────────────────────────────────
# REFRESH — rebuild the UI with current inventory data
# ─────────────────────────────────────────────────────────────
func refresh() -> void:
	if not visible:
		return

	# Update token display
	if token_display:
		token_display.text = "⭐ %d VIBE Tokens" % GameState.vibe_tokens

	# Rebuild each tab
	_build_tokens_tab()
	_build_nft_tab()
	_build_items_tab("Clothes")
	_build_items_tab("Accessories")
	_build_items_tab("Quest Items")
	_build_items_tab("Badges")


# ─────────────────────────────────────────────────────────────
# TAB BUILDERS
# ─────────────────────────────────────────────────────────────
func _build_tokens_tab() -> void:
	var tab := _get_tab_node("Tokens")
	if not tab:
		return
	_clear_children(tab)

	# Token summary
	var vbox := VBoxContainer.new()
	tab.add_child(vbox)

	var title := Label.new()
	title.text = "Your VIBE Token Balance"
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)

	var amount := Label.new()
	amount.text = "⭐ %d VIBE" % GameState.vibe_tokens
	amount.add_theme_font_size_override("font_size", 48)
	amount.modulate = Color(1.0, 0.85, 0.0)
	vbox.add_child(amount)

	var info := Label.new()
	info.text = "VIBE tokens are earned by completing puzzles and missions!\nSpend them at the store to buy cool avatar items."
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(info)


func _build_nft_tab() -> void:
	var tab := _get_tab_node("NFTs")
	if not tab:
		return
	_clear_children(tab)

	var nfts := InventoryManager.get_all_nfts()
	if nfts.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No NFT collectibles yet!\nComplete missions to earn rare digital items. 🌟"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tab.add_child(empty_label)
		return

	var grid := GridContainer.new()
	grid.columns = 3
	tab.add_child(grid)

	for nft in nfts:
		grid.add_child(_make_nft_card(nft))


func _build_items_tab(category: String) -> void:
	var tab := _get_tab_node(category)
	if not tab:
		return
	_clear_children(tab)

	var items := InventoryManager.get_items_by_category(category)
	if items.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No %s yet!\nComplete missions or visit the store." % category.to_lower()
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tab.add_child(empty_label)
		return

	var grid := GridContainer.new()
	grid.columns = 4
	tab.add_child(grid)

	for item in items:
		grid.add_child(_make_item_card(item))


# ─────────────────────────────────────────────────────────────
# CARD BUILDERS — create UI elements for each item
# ─────────────────────────────────────────────────────────────
func _make_item_card(item: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(120, 140)

	var vbox := VBoxContainer.new()
	card.add_child(vbox)

	# Item icon (placeholder colored box)
	var icon_rect := ColorRect.new()
	icon_rect.custom_minimum_size = Vector2(80, 80)
	var rarity: String = item.get("rarity", "common")
	icon_rect.color = RARITY_COLORS.get(rarity, Color.GRAY)
	icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(icon_rect)

	# Item name
	var name_label := Label.new()
	name_label.text = item.get("name", "?")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_label)

	# Rarity badge
	var rarity_label := Label.new()
	rarity_label.text = rarity.capitalize()
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.add_theme_font_size_override("font_size", 9)
	rarity_label.modulate = RARITY_COLORS.get(rarity, Color.GRAY)
	vbox.add_child(rarity_label)

	# Equip button if equippable
	if item.get("is_equippable", false):
		var equip_btn := Button.new()
		var is_equipped: bool = AvatarManager.is_item_equipped(item.get("item_id", ""))
		equip_btn.text = "Unequip" if is_equipped else "Equip"
		equip_btn.pressed.connect(_on_equip_item.bind(item, equip_btn))
		vbox.add_child(equip_btn)

	return card


func _make_nft_card(nft: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(140, 160)

	var vbox := VBoxContainer.new()
	card.add_child(vbox)

	# NFT image placeholder
	var img_rect := ColorRect.new()
	img_rect.custom_minimum_size = Vector2(100, 100)
	var rarity: String = nft.get("rarity", "common")
	img_rect.color = RARITY_COLORS.get(rarity, Color.GRAY)
	img_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(img_rect)

	# NFT name
	var name_label := Label.new()
	name_label.text = nft.get("name", "?")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(name_label)

	# Discovered from
	var from_label := Label.new()
	from_label.text = "From: " + nft.get("discovered_from", "Unknown")
	from_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	from_label.add_theme_font_size_override("font_size", 9)
	from_label.modulate = Color(0.7, 0.7, 0.7)
	vbox.add_child(from_label)

	return card


# ─────────────────────────────────────────────────────────────
# EQUIP HANDLER
# ─────────────────────────────────────────────────────────────
func _on_equip_item(item: Dictionary, button: Button) -> void:
	var item_id: String = item.get("item_id", "")
	var slot: String = item.get("avatar_slot", "accessory")

	if AvatarManager.is_item_equipped(item_id):
		AvatarManager.unequip_slot(slot)
		button.text = "Equip"
	else:
		AvatarManager.equip_item(slot, item_id)
		button.text = "Unequip"

	SaveManager.save_game()


# ─────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────
func _get_tab_node(category: String) -> Control:
	if not tab_container:
		return null
	for i in range(tab_container.get_tab_count()):
		if tab_container.get_tab_title(i) == category:
			return tab_container.get_tab_control(i)
	return null


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()


func _on_close_pressed() -> void:
	var hud := get_parent()
	if hud and hud.has_method("close_all_panels"):
		hud.close_all_panels()
	else:
		visible = false


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_B:
			get_viewport().set_input_as_handled()
			_on_close_pressed()
