## AvatarManager.gd
## =============================================================
## Manages the player's avatar customization.
##
## The AvatarConfig stores what the player's character looks like:
##   - body type
##   - skin tone
##   - hairstyle and color
##   - outfit, shoes, accessory
##   - special effects (for rare items)
##
## This is designed to ALSO work with a future 3D avatar system.
## See: docs/3d_avatar_roadmap.md for the future plan.
##
## Usage from any script:
##   AvatarManager.equip_item("outfit", "sparkle_shirt")
##   AvatarManager.get_config()
## =============================================================
extends Node

# ─────────────────────────────────────────────────────────────
# SIGNALS
# ─────────────────────────────────────────────────────────────
signal avatar_updated(config: Dictionary)
signal item_equipped(slot: String, item_id: String)
signal item_unequipped(slot: String)

# ─────────────────────────────────────────────────────────────
# AVATAR SLOTS — each slot holds one item at a time
# ─────────────────────────────────────────────────────────────
const SLOTS: Array = [
	"hairstyle",
	"outfit",
	"shoes",
	"accessory",
	"special_effect",
]

# ─────────────────────────────────────────────────────────────
# DEFAULT AVATAR CONFIG
# This is what the player starts with before customizing.
# ─────────────────────────────────────────────────────────────
var _config: Dictionary = {
	# Body
	"body_type": "default",     # e.g. "default", "slim", "round"
	"skin_tone": "medium",      # e.g. "light", "medium", "dark", "warm", "cool"
	# Hair
	"hairstyle": "default_hair", # Item ID of equipped hairstyle
	"hair_color": "#4A2800",    # Hex color string
	# Clothing
	"outfit": "default_outfit",  # Item ID of equipped outfit
	"shoes": "default_shoes",    # Item ID of equipped shoes
	"accessory": "",             # Item ID of equipped accessory (empty = none)
	"special_effect": "",        # Item ID of special effect (rare items)
	# Equipped items list (for quick lookup)
	"equipped_items": [],
}

# Color options players can choose from
const SKIN_TONES: Array = ["light", "medium_light", "medium", "medium_dark", "dark", "warm", "cool"]
const HAIR_COLORS: Array = ["#4A2800", "#FFD700", "#FF6B6B", "#1B2B5E", "#6B4E2B", "#C0C0C0", "#FF4500"]


# ─────────────────────────────────────────────────────────────
# GET THE CURRENT AVATAR CONFIG
# ─────────────────────────────────────────────────────────────
func get_config() -> Dictionary:
	return _config.duplicate(true)  # Return a copy so external code can't accidentally modify it


# ─────────────────────────────────────────────────────────────
# EQUIP AN ITEM INTO A SLOT
# ─────────────────────────────────────────────────────────────
func equip_item(slot: String, item_id: String) -> bool:
	if not slot in SLOTS:
		push_error("[AvatarManager] Unknown slot: " + slot)
		return false

	# Check if the player actually owns this item
	if not InventoryManager.has_item(item_id) and item_id != "" and not item_id.begins_with("default_"):
		push_error("[AvatarManager] Player does not own item: " + item_id)
		return false

	# Unequip the previous item in this slot
	var old_item_id: String = _config.get(slot, "")
	if not old_item_id.is_empty() and not old_item_id.begins_with("default_"):
		InventoryManager.mark_equipped(old_item_id, false)
		_config["equipped_items"].erase(old_item_id)

	# Equip the new item
	_config[slot] = item_id
	if not item_id.is_empty() and not item_id.begins_with("default_"):
		InventoryManager.mark_equipped(item_id, true)
		if not item_id in _config["equipped_items"]:
			_config["equipped_items"].append(item_id)

	emit_signal("item_equipped", slot, item_id)
	emit_signal("avatar_updated", _config.duplicate())
	print("[AvatarManager] Equipped '%s' in slot '%s'" % [item_id, slot])
	return true


func unequip_slot(slot: String) -> void:
	equip_item(slot, "")
	emit_signal("item_unequipped", slot)


# ─────────────────────────────────────────────────────────────
# BODY / SKIN CUSTOMIZATION
# ─────────────────────────────────────────────────────────────
func set_skin_tone(tone: String) -> void:
	if tone in SKIN_TONES:
		_config["skin_tone"] = tone
		emit_signal("avatar_updated", _config.duplicate())


func set_hair_color(color_hex: String) -> void:
	_config["hair_color"] = color_hex
	emit_signal("avatar_updated", _config.duplicate())


func set_body_type(body_type: String) -> void:
	_config["body_type"] = body_type
	emit_signal("avatar_updated", _config.duplicate())


# ─────────────────────────────────────────────────────────────
# QUERY
# ─────────────────────────────────────────────────────────────
func is_slot_empty(slot: String) -> bool:
	var item_id: String = _config.get(slot, "")
	return item_id.is_empty()


func get_equipped_item(slot: String) -> String:
	return _config.get(slot, "")


func is_item_equipped(item_id: String) -> bool:
	return item_id in _config.get("equipped_items", [])


# ─────────────────────────────────────────────────────────────
# SERIALIZATION
# ─────────────────────────────────────────────────────────────
func to_dict() -> Dictionary:
	return _config.duplicate(true)


func from_dict(data: Dictionary) -> void:
	if data.is_empty():
		return
	# Load saved config but keep any new fields from the default
	for key in data:
		_config[key] = data[key]
	emit_signal("avatar_updated", _config.duplicate())
