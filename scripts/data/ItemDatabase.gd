## ItemDatabase.gd
## =============================================================
## A central registry of all items in the game.
## Instead of hardcoding item data everywhere, we look it up here.
##
## Usage:
##   var item = ItemDatabase.get_item("pink_sneakers")
##   var store_items = ItemDatabase.get_store_items()
##
## class_name lets any script call ItemDatabase.get_store_items()
## without needing to load or instantiate this file first.
## =============================================================
class_name ItemDatabase
extends RefCounted

# ─────────────────────────────────────────────────────────────
# ALL ITEMS IN THE GAME
# Add new items here as the game grows.
# ─────────────────────────────────────────────────────────────
const ALL_ITEMS: Dictionary = {

	# ── STORE ITEMS (purchasable with VIBE tokens) ────────────
	"pink_sneakers": {
		"item_id": "pink_sneakers",
		"name": "Pink Sneakers",
		"description": "Bright pink sneakers that make you run faster... maybe!",
		"category": "Clothes",
		"rarity": "common",
		"icon_path": "res://assets/icons/items/pink_sneakers.png",
		"quantity": 1,
		"is_equippable": true,
		"is_nft": false,
		"token_value": 5,
		"owned": false,
		"store_price": 5,       # Costs 5 VIBE to buy
		"avatar_slot": "shoes", # Goes into the "shoes" avatar slot
	},

	"star_hair_clip": {
		"item_id": "star_hair_clip",
		"name": "Star Hair Clip",
		"description": "A shiny star-shaped clip. Very sparkly!",
		"category": "Accessories",
		"rarity": "common",
		"icon_path": "res://assets/icons/items/star_hair_clip.png",
		"quantity": 1,
		"is_equippable": true,
		"is_nft": false,
		"token_value": 8,
		"owned": false,
		"store_price": 8,
		"avatar_slot": "accessory",
	},

	"sparkle_shirt": {
		"item_id": "sparkle_shirt",
		"name": "Sparkle Shirt",
		"description": "A shirt covered in tiny sparkles. You'll shine!",
		"category": "Clothes",
		"rarity": "uncommon",
		"icon_path": "res://assets/icons/items/sparkle_shirt.png",
		"quantity": 1,
		"is_equippable": true,
		"is_nft": false,
		"token_value": 10,
		"owned": false,
		"store_price": 10,
		"avatar_slot": "outfit",
	},

	"rainbow_backpack": {
		"item_id": "rainbow_backpack",
		"name": "Rainbow Backpack",
		"description": "Every color of the rainbow in one backpack!",
		"category": "Accessories",
		"rarity": "uncommon",
		"icon_path": "res://assets/icons/items/rainbow_backpack.png",
		"quantity": 1,
		"is_equippable": true,
		"is_nft": false,
		"token_value": 15,
		"owned": false,
		"store_price": 15,
		"avatar_slot": "accessory",
	},

	# ── MISSION REWARD ITEMS ──────────────────────────────────
	"pattern_star_badge": {
		"item_id": "pattern_star_badge",
		"name": "Pattern Star Badge",
		"description": "Awarded for mastering the Pattern Power puzzle!",
		"category": "Badges",
		"rarity": "common",
		"icon_path": "res://assets/icons/items/pattern_star_badge.png",
		"quantity": 1,
		"is_equippable": false,
		"is_nft": false,
		"token_value": 3,
		"owned": false,
	},

	# ── QUEST / KEY ITEMS ─────────────────────────────────────
	"daisys_leash": {
		"item_id": "daisys_leash",
		"name": "Daisy's Leash",
		"description": "A colourful dog leash hidden in the school locker. "
			+ "Maybe it belongs to that white dog near the flowers?",
		"category": "Quest Items",
		"rarity": "uncommon",
		"icon_path": "res://assets/icons/items/daisys_leash.png",
		"quantity": 1,
		"is_equippable": false,
		"is_nft": false,
		"token_value": 0,
		"owned": false,
	},
}

# ─────────────────────────────────────────────────────────────
# NFT COLLECTIBLES DATABASE
# ─────────────────────────────────────────────────────────────
const ALL_NFTS: Dictionary = {
	"pattern_star_nft": {
		"nft_id": "pattern_star_nft",
		"name": "Pattern Star Badge",
		"description": "A rare digital badge for solving the Pattern Power puzzle! Only skilled pattern-readers earn this.",
		"rarity": "common",
		"image_path": "res://assets/icons/nfts/pattern_star_nft.png",
		"discovered_from": "Pattern Power",
		"tradeable": false,   # Will be true in future blockchain version
		"equipped": false,
		"token_value": 5,
	},
}

# ─────────────────────────────────────────────────────────────
# LOOKUP FUNCTIONS
# ─────────────────────────────────────────────────────────────
static func get_item(item_id: String) -> Dictionary:
	return ALL_ITEMS.get(item_id, {}).duplicate(true)


static func get_nft(nft_id: String) -> Dictionary:
	return ALL_NFTS.get(nft_id, {}).duplicate(true)


static func get_store_items() -> Array:
	# Return all items that have a store_price (sold in the shop)
	var store_items: Array = []
	for item in ALL_ITEMS.values():
		if item.has("store_price"):
			store_items.append(item.duplicate(true))
	return store_items


static func get_items_by_category(category: String) -> Array:
	var result: Array = []
	for item in ALL_ITEMS.values():
		if item.get("category", "") == category:
			result.append(item.duplicate(true))
	return result
