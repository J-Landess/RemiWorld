## RewardManager.gd
## =============================================================
## Handles giving the player their rewards after completing
## missions, puzzles, or other activities.
##
## A "reward" can include:
##   - VIBE Tokens (in-game currency)
##   - XP (experience points for leveling up)
##   - Items (clothes, accessories, tools)
##   - NFT Collectibles (rare digital items)
##   - Badges
##
## Usage from any script:
##   RewardManager.grant_reward({
##     "tokens": 10,
##     "xp": 25,
##     "nft": { "nft_id": "pattern_star_badge", ... }
##   })
## =============================================================
extends Node

# ─────────────────────────────────────────────────────────────
# SIGNALS
# ─────────────────────────────────────────────────────────────
signal reward_granted(reward_summary: Dictionary)
signal tokens_rewarded(amount: int)
signal xp_rewarded(amount: int)
signal item_rewarded(item: Dictionary)
signal nft_rewarded(nft: Dictionary)


# ─────────────────────────────────────────────────────────────
# GRANT A FULL REWARD PACKAGE
# Pass in a dictionary with any combination of reward types.
#
# Example:
#   grant_reward({
#     "tokens": 10,
#     "xp": 25,
#     "items": [{ "item_id": "star_badge", ... }],
#     "nft": { "nft_id": "pattern_star", ... }
#   })
# ─────────────────────────────────────────────────────────────
func grant_reward(reward: Dictionary) -> Dictionary:
	var summary: Dictionary = {}
	print("[RewardManager] Granting reward: ", reward)

	# Grant VIBE tokens
	if reward.has("tokens") and reward["tokens"] > 0:
		var token_amount: int = reward["tokens"]
		GameState.add_tokens(token_amount)
		summary["tokens"] = token_amount
		emit_signal("tokens_rewarded", token_amount)

	# Grant XP
	if reward.has("xp") and reward["xp"] > 0:
		var xp_amount: int = reward["xp"]
		GameState.add_xp(xp_amount)
		summary["xp"] = xp_amount
		emit_signal("xp_rewarded", xp_amount)

	# Grant regular items (array of item dictionaries)
	if reward.has("items"):
		var items: Array = reward["items"]
		summary["items"] = []
		for item in items:
			InventoryManager.add_item(item)
			summary["items"].append(item.get("name", "Unknown Item"))
			emit_signal("item_rewarded", item)

	# Grant a single item shorthand
	if reward.has("item"):
		var item: Dictionary = reward["item"]
		InventoryManager.add_item(item)
		summary["item"] = item.get("name", "Unknown Item")
		emit_signal("item_rewarded", item)

	# Grant NFT collectible
	if reward.has("nft"):
		var nft: Dictionary = reward["nft"]
		InventoryManager.add_nft(nft)
		summary["nft"] = nft.get("name", "Unknown NFT")
		emit_signal("nft_rewarded", nft)

	emit_signal("reward_granted", summary)
	print("[RewardManager] Reward granted! Summary: ", summary)
	return summary


# ─────────────────────────────────────────────────────────────
# SHORTHAND HELPERS
# ─────────────────────────────────────────────────────────────
func grant_tokens(amount: int) -> void:
	grant_reward({"tokens": amount})


func grant_xp(amount: int) -> void:
	grant_reward({"xp": amount})


func grant_item(item: Dictionary) -> void:
	grant_reward({"item": item})


func grant_nft(nft: Dictionary) -> void:
	grant_reward({"nft": nft})


# ─────────────────────────────────────────────────────────────
# PRE-DEFINED ITEM/NFT CREATORS
# These are convenience functions to build common reward objects.
# ─────────────────────────────────────────────────────────────
func make_nft(nft_id: String, name: String, description: String,
		rarity: String, discovered_from: String, token_value: int = 5) -> Dictionary:
	return {
		"nft_id": nft_id,
		"name": name,
		"description": description,
		"rarity": rarity,
		"image_path": "res://assets/icons/nfts/%s.png" % nft_id,
		"discovered_from": discovered_from,
		"tradeable": false,
		"equipped": false,
		"token_value": token_value,
	}


func make_item(item_id: String, name: String, description: String,
		category: String, rarity: String = "common",
		token_value: int = 0, is_equippable: bool = false) -> Dictionary:
	return {
		"item_id": item_id,
		"name": name,
		"description": description,
		"category": category,
		"rarity": rarity,
		"icon_path": "res://assets/icons/items/%s.png" % item_id,
		"quantity": 1,
		"is_equippable": is_equippable,
		"is_nft": false,
		"token_value": token_value,
		"owned": true,
	}
