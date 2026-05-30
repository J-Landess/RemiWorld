## StoreUI.gd
## =============================================================
## The Storefront screen — shows items available for purchase
## with VIBE tokens.
##
## Features:
##   - Shows all store items with prices
##   - Shows player's current VIBE balance
##   - Allows purchasing items
##   - Purchased items go to the Backpack
##   - Can also open Avatar Closet
##
## Attached to: scenes/ui/HUD.tscn → StoreUI node
## Node type: Control
## =============================================================
extends Control

# ─────────────────────────────────────────────────────────────
# NODE REFERENCES
# ─────────────────────────────────────────────────────────────
@onready var close_button: Button   = $Panel/VBoxContainer/TopBar/CloseButton
@onready var token_label: Label     = $Panel/VBoxContainer/TopBar/TokenLabel
@onready var items_grid: GridContainer = $Panel/VBoxContainer/ScrollContainer/ItemsGrid
@onready var status_label: Label    = $Panel/VBoxContainer/StatusLabel
@onready var open_closet_btn: Button = $Panel/VBoxContainer/BottomBar/OpenClosetButton

# ─────────────────────────────────────────────────────────────
# READY
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	visible = false

	if close_button:
		close_button.pressed.connect(_on_close_pressed)

	if open_closet_btn:
		open_closet_btn.pressed.connect(_on_open_closet_pressed)

	# Update token display when tokens change
	GameState.tokens_changed.connect(_on_tokens_changed)


# ─────────────────────────────────────────────────────────────
# REFRESH — rebuild the store UI
# ─────────────────────────────────────────────────────────────
func refresh() -> void:
	if not visible:
		return

	# Update token balance display
	if token_label:
		token_label.text = "⭐ %d VIBE" % GameState.vibe_tokens

	# Clear previous items
	if items_grid:
		for child in items_grid.get_children():
			child.queue_free()

	# Build item cards for each store item
	var store_items := ItemDatabase.get_store_items()
	for item in store_items:
		if items_grid:
			items_grid.add_child(_make_store_card(item))

	if status_label:
		status_label.text = ""


# ─────────────────────────────────────────────────────────────
# STORE CARD — one item in the store
# ─────────────────────────────────────────────────────────────
func _make_store_card(item: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(160, 220)

	var vbox := VBoxContainer.new()
	card.add_child(vbox)

	# Item preview (colored placeholder)
	var preview := ColorRect.new()
	preview.custom_minimum_size = Vector2(120, 100)
	preview.color = Color(randf_range(0.5, 1.0), randf_range(0.5, 1.0), randf_range(0.5, 1.0))
	preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(preview)

	# Item name
	var name_label := Label.new()
	name_label.text = item.get("name", "?")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(name_label)

	# Description
	var desc_label := Label.new()
	desc_label.text = item.get("description", "")
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(140, 0)
	vbox.add_child(desc_label)

	# Price
	var price: int = item.get("store_price", 0)
	var price_label := Label.new()
	price_label.text = "⭐ %d VIBE" % price
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_font_size_override("font_size", 14)
	price_label.modulate = Color(1.0, 0.85, 0.0)
	vbox.add_child(price_label)

	# Buy button — disabled if already owned or can't afford
	var buy_btn := Button.new()
	var item_id: String = item.get("item_id", "")
	var already_owned: bool = InventoryManager.has_item(item_id)
	var can_afford: bool = GameState.vibe_tokens >= price

	if already_owned:
		buy_btn.text = "✅ Owned"
		buy_btn.disabled = true
	elif not can_afford:
		buy_btn.text = "🔒 Need %d VIBE" % price
		buy_btn.disabled = true
		buy_btn.modulate = Color(0.6, 0.6, 0.6)
	else:
		buy_btn.text = "Buy — %d VIBE" % price
		buy_btn.pressed.connect(_on_buy_pressed.bind(item, buy_btn))

	vbox.add_child(buy_btn)

	return card


# ─────────────────────────────────────────────────────────────
# PURCHASE HANDLER
# ─────────────────────────────────────────────────────────────
func _on_buy_pressed(item: Dictionary, button: Button) -> void:
	var price: int = item.get("store_price", 0)
	var item_id: String = item.get("item_id", "")

	# Try to spend the tokens
	var success := GameState.spend_tokens(price)

	if success:
		# Add item to backpack
		var owned_item := item.duplicate(true)
		owned_item["owned"] = true
		owned_item["quantity"] = 1
		InventoryManager.add_item(owned_item)

		# Update button to show it's owned
		button.text = "✅ Owned"
		button.disabled = true

		# Show success message
		if status_label:
			status_label.text = "✅ Purchased: %s!" % item.get("name", "item")
			status_label.modulate = Color(0.2, 0.9, 0.2)

		# Save progress
		SaveManager.save_game()

		# Update token display
		if token_label:
			token_label.text = "⭐ %d VIBE" % GameState.vibe_tokens

		print("[StoreUI] Purchased: ", item.get("name", item_id))
	else:
		# Not enough tokens
		if status_label:
			status_label.text = "❌ Not enough VIBE tokens!"
			status_label.modulate = Color(0.9, 0.3, 0.3)


# ─────────────────────────────────────────────────────────────
# SIGNAL HANDLERS
# ─────────────────────────────────────────────────────────────
func _on_tokens_changed(new_amount: int) -> void:
	if token_label:
		token_label.text = "⭐ %d VIBE" % new_amount


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
		if event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_on_close_pressed()


func _on_open_closet_pressed() -> void:
	var hud := get_parent()
	if hud and hud.has_method("open_avatar_closet"):
		hud.open_avatar_closet()
