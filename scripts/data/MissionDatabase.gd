## MissionDatabase.gd
## =============================================================
## A central registry of all missions (quests) in the game.
## Each mission has its title, description, puzzle data,
## and reward information stored here.
##
## Usage:
##   var mission = MissionDatabase.get_mission("pattern_power")
##
## class_name lets any script call MissionDatabase.get_mission()
## without needing to load or instantiate this file first.
## =============================================================
class_name MissionDatabase
extends RefCounted

# ─────────────────────────────────────────────────────────────
# ALL MISSIONS
# ─────────────────────────────────────────────────────────────
const ALL_MISSIONS: Dictionary = {

	"pattern_power": {
		"mission_id": "pattern_power",
		"title": "Pattern Power",
		"description": "Help Coding Bot find the missing piece of the pattern!",
		"npc_id": "coding_bot",
		"npc_name": "Coding Bot",

		# The puzzle shown to the player
		"puzzle": {
			"type": "multiple_choice",         # Puzzle type (more types in future versions)
			"question": "What comes next?\nRed, Blue, Red, Blue, ___?",
			"display_pattern": ["🔴 Red", "🔵 Blue", "🔴 Red", "🔵 Blue", "❓"],
			"choices": ["Red", "Blue", "Green"],
			"correct_answer": "Red",            # Index 0
			"correct_index": 0,
			"hint": "Look at the pattern from the beginning. What color goes in the blank?",
			"explanation": "The pattern goes Red, Blue, Red, Blue... so the next one is Red!",
		},

		# Rewards for completing this mission
		"rewards": {
			"tokens": 10,
			"xp": 25,
			"nft": {
				"nft_id": "pattern_star_nft",
				"name": "Pattern Star Badge",
				"description": "A digital badge for solving the Pattern Power puzzle!",
				"rarity": "common",
				"image_path": "res://assets/icons/nfts/pattern_star_nft.png",
				"discovered_from": "Pattern Power",
				"tradeable": false,
				"equipped": false,
				"token_value": 5,
			},
		},

		# Can this mission be repeated?
		"repeatable": false,

		# Intro dialogue (before puzzle)
		"dialogue_intro": [
			"[Coding Bot] Hi there! I'm Coding Bot! 🤖",
			"[Coding Bot] I love patterns — they're like secret codes!",
			"[Coding Bot] Can you help me figure out what comes next in my pattern?",
		],

		# Success dialogue (after correct answer)
		"dialogue_success": [
			"[Coding Bot] Amazing! You got it! 🌟",
			"[Coding Bot] Red comes next because the pattern repeats: Red, Blue, Red, Blue...",
			"[Coding Bot] You're a pattern expert! Here's your reward!",
		],

		# Failure dialogue (after wrong answer)
		"dialogue_failure": [
			"[Coding Bot] Hmm, not quite! Let me give you a hint...",
			"[Coding Bot] Look at the colors from the very beginning.",
			"[Coding Bot] Do you see the repeating pattern?",
		],

		# Completion dialogue (if already done)
		"dialogue_complete": [
			"[Coding Bot] You already solved my pattern puzzle! Great job! 🌟",
			"[Coding Bot] Keep exploring Remi's World — there are more puzzles out there!",
		],
	},
}


# ─────────────────────────────────────────────────────────────
# LOOKUP FUNCTIONS
# ─────────────────────────────────────────────────────────────
static func get_mission(mission_id: String) -> Dictionary:
	return ALL_MISSIONS.get(mission_id, {}).duplicate(true)


static func get_all_missions() -> Array:
	return ALL_MISSIONS.values()


static func get_missions_by_npc(npc_id: String) -> Array:
	var result: Array = []
	for mission in ALL_MISSIONS.values():
		if mission.get("npc_id", "") == npc_id:
			result.append(mission.duplicate(true))
	return result
