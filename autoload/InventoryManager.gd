## InventoryManager.gd
## =============================================================
## Manages the player's Backpack — all items, NFT collectibles,
## avatar items, tokens, badges, and quest items.
##
## Usage from any script:
##   InventoryManager.add_item(item_dict)
##   InventoryManager.has_item("pink_sneakers")
##   InventoryManager.get_items_by_category("Clothes")
## =============================================================
extends Node

# ─────────────────────────────────────────────────────────────
# SIGNALS
# ─────────────────────────────────────────────────────────────
signal inventory_updated()
signal item_added(item: Dictionary)
signal item_removed(item_id: String)

# ─────────────────────────────────────────────────────────────
# CATEGORIES — these match the Backpack tab names
# ─────────────────────────────────────────────────────────────
const CATEGORIES: Array = [
	"Tokens",
	"NFTs",
	"Clothes",
	"Accessories",
	"Quest Items",
	"Badges",
]

# ─────────────────────────────────────────────────────────────
# RARITY LEVELS (from common to rarest)
# ─────────────────────────────────────────────────────────────
const RARITY_COMMON: String     = "common"
const RARITY_UNCOMMON: String   = "uncommon"
const RARITY_RARE: String       = "rare"
const RARITY_EPIC: String       = "epic"
const RARITY_LEGENDARY: String  = "legendary"
const RARITY_SECRET: String     = "secret"

# ─────────────────────────────────────────────────────────────
# STORAGE — dictionary keyed by item_id
# Each item looks like:
# {
#   "item_id": "pink_sneakers",
#   "name": "Pink Sneakers",
#   "description": "Cute sneakers!",
#   "category": "Clothes",
#   "rarity": "common",
#   "icon_path": "res://assets/icons/pink_sneakers.png",
#   "quantity": 1,
#   "is_equippable": true,
#   "is_nft": false,
#   "token_value": 5,
#   "owned": true
# }
# ─────────────────────────────────────────────────────────────
var _items: Dictionary = {}  # item_id -> item Dictionary

# NFT collectibles use a slightly different data structure
# {
#   "nft_id": "pattern_star_badge",
#   "name": "Pattern Star Badge",
#   "description": "Awarded for solving the Pattern Power puzzle!",
#   "rarity": "common",
#   "image_path": "res://assets/icons/pattern_star_badge.png",
#   "discovered_from": "Pattern Power",
#   "tradeable": false,
#   "equipped": false,
#   "token_value": 5,
# }
var _nfts: Dictionary = {}   # nft_id -> NFT Dictionary


# ─────────────────────────────────────────────────────────────
# ADD AN ITEM TO THE BACKPACK
# ─────────────────────────────────────────────────────────────
func add_item(item: Dictionary) -> void:
	var item_id: String = item.get("item_id", "")
	if item_id.is_empty():
		push_error("[InventoryManager] Cannot add item with no item_id!")
		return

	if _items.has(item_id):
		# If we already have it, increase the quantity
		_items[item_id]["quantity"] += item.get("quantity", 1)
	else:
		# Add new item, ensure it has all required fields
		item["owned"] = true
		item["quantity"] = item.get("quantity", 1)
		_items[item_id] = item

	print("[InventoryManager] Added item: ", item.get("name", item_id))
	emit_signal("item_added", item)
	emit_signal("inventory_updated")


# ─────────────────────────────────────────────────────────────
# ADD AN NFT COLLECTIBLE
# ─────────────────────────────────────────────────────────────
func add_nft(nft: Dictionary) -> void:
	var nft_id: String = nft.get("nft_id", "")
	if nft_id.is_empty():
		push_error("[InventoryManager] Cannot add NFT with no nft_id!")
		return

	# NFTs are unique — you can only have one of each
	if not _nfts.has(nft_id):
		nft["equipped"] = nft.get("equipped", false)
		_nfts[nft_id] = nft
		print("[InventoryManager] Added NFT: ", nft.get("name", nft_id))
		emit_signal("item_added", nft)
		emit_signal("inventory_updated")
	else:
		print("[InventoryManager] Already own NFT: ", nft_id)


# ─────────────────────────────────────────────────────────────
# REMOVE AN ITEM
# ─────────────────────────────────────────────────────────────
func remove_item(item_id: String, amount: int = 1) -> bool:
	if not _items.has(item_id):
		return false

	_items[item_id]["quantity"] -= amount
	if _items[item_id]["quantity"] <= 0:
		_items.erase(item_id)

	emit_signal("item_removed", item_id)
	emit_signal("inventory_updated")
	return true


# ─────────────────────────────────────────────────────────────
# QUERY HELPERS
# ─────────────────────────────────────────────────────────────
func has_item(item_id: String) -> bool:
	return _items.has(item_id)


func has_nft(nft_id: String) -> bool:
	return _nfts.has(nft_id)


func get_item(item_id: String) -> Dictionary:
	return _items.get(item_id, {})


func get_all_items() -> Array:
	return _items.values()


func get_all_nfts() -> Array:
	return _nfts.values()


func get_items_by_category(category: String) -> Array:
	# Return only items that match the given category
	var result: Array = []
	for item in _items.values():
		if item.get("category", "") == category:
			result.append(item)
	return result


func get_total_item_count() -> int:
	return _items.size() + _nfts.size()


# ─────────────────────────────────────────────────────────────
# EQUIP SYSTEM — marks an item as "currently equipped"
# ─────────────────────────────────────────────────────────────
func mark_equipped(item_id: String, equipped: bool) -> void:
	if _items.has(item_id):
		_items[item_id]["equipped"] = equipped
		emit_signal("inventory_updated")


# ─────────────────────────────────────────────────────────────
# SERIALIZATION — save/load support
# ─────────────────────────────────────────────────────────────
func to_dict() -> Dictionary:
	return {
		"items": _items,
		"nfts": _nfts,
	}


func from_dict(data: Dictionary) -> void:
	_items = data.get("items", {})
	_nfts = data.get("nfts", {})
	emit_signal("inventory_updated")


func clear() -> void:
	_items.clear()
	_nfts.clear()
	emit_signal("inventory_updated")
