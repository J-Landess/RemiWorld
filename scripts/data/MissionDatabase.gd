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
			"[Coding Bot] You beat Pattern Power! 🌟",
			"[Coding Bot] Talk to me anytime for harder math and coding training levels!",
		],
	},

	# ──────────────────────────────────────────────────────────
	# CHESS — "Knight's Jump"
	# ──────────────────────────────────────────────────────────
	"chess_knight_jump": {
		"mission_id": "chess_knight_jump",
		"title": "Knight's Jump",
		"description": "Help the Chess Tutor capture the treasure in one knight move!",
		"npc_id": "chess_tutor",
		"npc_name": "Chess Tutor",

		"challenge": {
			"panel": "ChessPuzzlePanel",
			"rounds": 3,         # Number of puzzles in a row
			"required_correct": 2,
			"grid_size": 4,      # 4x4 board
		},

		"rewards": {
			"tokens": 12,
			"xp": 30,
			"nft": {
				"nft_id": "knight_star_nft",
				"name": "Knight Star Badge",
				"description": "Awarded for mastering the knight's leap!",
				"rarity": "common",
				"image_path": "res://assets/icons/nfts/knight_star_nft.png",
				"discovered_from": "Knight's Jump",
				"tradeable": false,
				"equipped": false,
				"token_value": 6,
			},
		},
		"repeatable": false,

		"dialogue_intro": [
			"[Chess Tutor] Welcome, young thinker! ♞",
			"[Chess Tutor] The knight moves in an L: two squares one way, then one square sideways.",
			"[Chess Tutor] Find the move that lands on the treasure!",
		],
		"dialogue_success": [
			"[Chess Tutor] Brilliant! A true knight in the making! ♞",
			"[Chess Tutor] Here's your badge — wear it with pride!",
		],
		"dialogue_failure": [
			"[Chess Tutor] Not quite — remember, the knight always moves in an L.",
			"[Chess Tutor] Two squares one way, then one to the side. Try again!",
		],
		"dialogue_complete": [
			"[Chess Tutor] You've already proven yourself a master of the knight!",
			"[Chess Tutor] Come back any time to share a game.",
		],
	},

	# ──────────────────────────────────────────────────────────
	# SOCCER — "Goal Kicker"
	# ──────────────────────────────────────────────────────────
	"soccer_goal_kicker": {
		"mission_id": "soccer_goal_kicker",
		"title": "Goal Kicker",
		"description": "Score 2 out of 3 kicks against Coach Kick!",
		"npc_id": "coach_kick",
		"npc_name": "Coach Kick",

		"challenge": {
			"panel": "SoccerKickPanel",
			"shots": 3,
			"required_goals": 2,
		},

		"rewards": {
			"tokens": 12,
			"xp": 30,
			"nft": {
				"nft_id": "golden_cleats_nft",
				"name": "Golden Cleats Badge",
				"description": "Earned by scoring goals with style!",
				"rarity": "common",
				"image_path": "res://assets/icons/nfts/golden_cleats_nft.png",
				"discovered_from": "Goal Kicker",
				"tradeable": false,
				"equipped": false,
				"token_value": 6,
			},
		},
		"repeatable": false,

		"dialogue_intro": [
			"[Coach Kick] Ready to take some shots, champ? ⚽",
			"[Coach Kick] Press SPACE to stop the power bar, then SPACE again to stop the aim.",
			"[Coach Kick] Score 2 out of 3 and you'll earn the Golden Cleats!",
		],
		"dialogue_success": [
			"[Coach Kick] GOAL! 🎉 You did it!",
			"[Coach Kick] You've got the touch, kid. Wear that badge proudly!",
		],
		"dialogue_failure": [
			"[Coach Kick] So close! Keep practising your timing.",
			"[Coach Kick] Come back any time and we'll try again!",
		],
		"dialogue_complete": [
			"[Coach Kick] You've already earned your Golden Cleats!",
			"[Coach Kick] Want to come kick a few more for fun?",
		],
	},

	# ──────────────────────────────────────────────────────────
	# ART — "Rainbow Maker"
	# ──────────────────────────────────────────────────────────
	"art_rainbow_maker": {
		"mission_id": "art_rainbow_maker",
		"title": "Rainbow Maker",
		"description": "Mix colors to match Artist Pip's swatches!",
		"npc_id": "artist_pip",
		"npc_name": "Artist Pip",

		"challenge": {
			"panel": "ArtPalettePanel",
			"rounds": 3,
			"required_correct": 2,
			"tolerance": 0.12,    # Per-channel match tolerance (0–1 scale)
		},

		"rewards": {
			"tokens": 12,
			"xp": 30,
			"nft": {
				"nft_id": "palette_badge_nft",
				"name": "Palette Badge",
				"description": "For artists with a true eye for color!",
				"rarity": "common",
				"image_path": "res://assets/icons/nfts/palette_badge_nft.png",
				"discovered_from": "Rainbow Maker",
				"tradeable": false,
				"equipped": false,
				"token_value": 6,
			},
		},
		"repeatable": false,

		"dialogue_intro": [
			"[Artist Pip] Hi friend! 🎨",
			"[Artist Pip] I'll show you a target color. You slide R, G, and B to match it.",
			"[Artist Pip] Get 2 out of 3 close enough and you'll earn my Palette Badge!",
		],
		"dialogue_success": [
			"[Artist Pip] Wow, that's a beautiful match! 🌈",
			"[Artist Pip] Here — this Palette Badge is for you!",
		],
		"dialogue_failure": [
			"[Artist Pip] Hmm, the colors weren't quite right.",
			"[Artist Pip] Don't worry, color mixing takes practice. Try again any time!",
		],
		"dialogue_complete": [
			"[Artist Pip] You're my favorite color-mixing friend!",
			"[Artist Pip] Come back any time to paint some more.",
		],
	},

	# ──────────────────────────────────────────────────────────
	# DAISY — "Fetch Game" (only after Daisy is a companion)
	# ──────────────────────────────────────────────────────────
	"daisy_fetch_game": {
		"mission_id": "daisy_fetch_game",
		"title": "Daisy's Fetch Game",
		"description": "Play fetch with Daisy! Throw 3 sticks for her to catch.",
		"npc_id": "daisy_doodles",
		"npc_name": "Daisy",

		"challenge": {
			"panel": "DaisyFetchPanel",
			"sticks": 3,
			"required_fetches": 3,
		},

		"rewards": {
			"tokens": 15,
			"xp": 40,
			"nft": {
				"nft_id": "best_friend_nft",
				"name": "Best Friend Badge",
				"description": "Daisy gave you this in return for so much fun together.",
				"rarity": "uncommon",
				"image_path": "res://assets/icons/nfts/best_friend_nft.png",
				"discovered_from": "Daisy's Fetch Game",
				"tradeable": false,
				"equipped": false,
				"token_value": 8,
			},
		},
		"repeatable": false,

		"dialogue_intro": [
			"[Daisy] Woof! 🐾 (Daisy spins in circles excitedly!)",
			"[Daisy] Click each stick to throw it — Daisy will fetch them all!",
		],
		"dialogue_success": [
			"[Daisy] Woof woof! 🐾 (Daisy gives you a happy lick!)",
			"[Daisy] (You feel something on her collar — a brand new badge!)",
		],
		"dialogue_failure": [
			"[Daisy] (Daisy looks confused but still wags her tail.)",
			"[Daisy] (Try throwing all the sticks for her!)",
		],
		"dialogue_complete": [
			"[Daisy] (Daisy is panting happily, satisfied from your earlier game.)",
			"[Daisy] Woof! 🐾",
		],
	},

	# ──────────────────────────────────────────────────────────
	# DAISY — "Dog Pit Bouts"
	# ──────────────────────────────────────────────────────────
	"daisy_dog_pit": {
		"mission_id": "daisy_dog_pit",
		"title": "Dog Pit Bouts",
		"description": "Wager VIBE and help Daisy survive 3 high-pressure bouts.",
		"npc_id": "pit_boss_mara",
		"npc_name": "Pit Boss Mara",

		"challenge": {
			"panel": "DaisyDogFightPanel",
			"rounds": 3,
			"required_wins": 2,
			"wager_cost": 6,
			"payout_bonus": 14,
			"owners": [
				{
					"name": "Rex's Owner",
					"taunt": "My bulldog Rex only needs one clean hit."
				},
				{
					"name": "Nova's Owner",
					"taunt": "Nova is faster than lightning. Daisy won't touch her."
				},
				{
					"name": "Brutus's Owner",
					"taunt": "This is the final round. Brutus never loses."
				},
			],
		},

		"rewards": {
			"tokens": 10,
			"xp": 50,
			"nft": {
				"nft_id": "pit_champion_nft",
				"name": "Pit Champion Badge",
				"description": "Awarded for guiding Daisy through the dog pit bouts.",
				"rarity": "uncommon",
				"image_path": "res://assets/icons/nfts/pit_champion_nft.png",
				"discovered_from": "Dog Pit Bouts",
				"tradeable": false,
				"equipped": false,
				"token_value": 10,
			},
		},
		"repeatable": false,

		"dialogue_intro": [
			"[Pit Boss Mara] Welcome to the Dog Pit. You can wager VIBE on Daisy's run.",
			"[Pit Boss Mara] It'll be a three-bout ladder, and each owner's got something to say.",
			"[Pit Boss Mara] Win at least 2 rounds and cash out. Lose, and your entry stays in the pot.",
		],
		"dialogue_success": [
			"[Pit Boss Mara] Daisy made it through the ladder! That's champion energy.",
			"[Pit Boss Mara] Your payout is settled. Come back when you want another showdown.",
		],
		"dialogue_failure": [
			"[Pit Boss Mara] Tough break. The pit is unforgiving.",
			"[Pit Boss Mara] Build up your VIBE and timing, then challenge the ladder again.",
		],
		"dialogue_complete": [
			"[Pit Boss Mara] You already cleared the pit once.",
			"[Pit Boss Mara] Online player-versus-player bouts are coming soon.",
		],
	},

	# ──────────────────────────────────────────────────────────
	# DAISY — "Obedience Course"
	# ──────────────────────────────────────────────────────────
	"daisy_obedience_course": {
		"mission_id":   "daisy_obedience_course",
		"title":        "Obedience Course",
		"description":  "Guide Daisy through five training obstacles in the right order.",
		"npc_id":       "course_coach",
		"npc_name":     "Coach Bolt",

		"challenge": {
			"panel": "ObstacleCoursePanel",
		},

		"rewards": {
			"tokens": 8,
			"xp": 40,
			"nft": {
				"nft_id":         "good_girl_nft",
				"name":           "Good Girl Badge",
				"description":    "Daisy completed the obedience course with flying colors.",
				"rarity":         "common",
				"image_path":     "res://assets/icons/nfts/good_girl_nft.png",
				"discovered_from":"Obedience Course",
				"tradeable":      false,
				"equipped":       false,
				"token_value":    8,
			},
		},
		"repeatable": false,

		"dialogue_intro": [
			"[Coach Bolt] Welcome to the obedience course!",
			"[Coach Bolt] Five obstacles, five commands. Watch the prompt and press the right key fast.",
			"[Coach Bolt] Get at least 3 out of 5 and Daisy graduates. Ready?",
		],
		"dialogue_success": [
			"[Coach Bolt] Outstanding! Daisy is a natural!",
			"[Coach Bolt] Come back any time to practise more.",
		],
		"dialogue_failure": [
			"[Coach Bolt] Not quite — Daisy needs a bit more practice.",
			"[Coach Bolt] Talk to me again to run the course.",
		],
		"dialogue_complete": [
			"[Coach Bolt] Daisy already earned her certificate!",
			"[Coach Bolt] Feel free to chat, but the course record stands.",
		],
	},

	# ──────────────────────────────────────────────────────────
	# ROAD TO BOSTON — meet Zia the witch (timed journey)
	# ──────────────────────────────────────────────────────────
	"road_to_boston": {
		"mission_id": "road_to_boston",
		"title": "Road to Boston",
		"description": "Roller-skate to Zia in Boston before time runs out. Dodge, jump, and land tricks!",
		"npc_id": "journey_guide",
		"npc_name": "Maple the Guide",

		"rewards": {
			"tokens": 25,
			"xp": 80,
			"nft": {
				"nft_id": "zia_cookie_nft",
				"name": "Zia's Star Cookie",
				"description": "A magical treat from your grandmother Zia in Boston.",
				"rarity": "uncommon",
				"image_path": "res://assets/icons/nfts/zia_cookie_nft.png",
				"discovered_from": "Road to Boston",
				"tradeable": false,
				"equipped": false,
				"token_value": 15,
			},
		},
		"repeatable": false,

		"dialogue_intro": [
			"[Maple] Remi! Zia in Boston misses you — strap on your roller skates!",
			"[Maple] Five stretches: oak logs, river puddles, hills, sassy kids, and a storm.",
			"[Maple] Jump obstacles, switch lanes, and pull air tricks for bonus seconds.",
			"[Maple] You have eight minutes. Fall and you'll stumble — that costs time!",
			"[Maple] If you're late, Daisy becomes a frog and your hair falls out. Go!",
		],
		"dialogue_success": [
			"[Zia] Remi, sweetheart! You made it on time!",
			"[Zia] I love all children — especially you. Never whisper sass, or I'll swap your words for sass all day!",
			"[Zia] Here — star cookies and a hug. Visit again soon.",
		],
		"dialogue_failure": [
			"[Zia] (from afar) Too slow, little one!",
			"[Zia] POOF — Daisy becomes a frog! Your hair — gone! Learn respect for time and tone.",
		],
		"dialogue_complete": [
			"[Zia] My darling Remi! The cottage door is always open.",
			"[Zia] Remember: good children get cookies. Sassy children get… interesting spells.",
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
