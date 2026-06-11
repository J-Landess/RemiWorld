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
		"title": "First Shift at the Password Factory",
		"description": "Crack your first code and stamp a password for pay!",
		"npc_id": "password_factory",
		"npc_name": "The Password Factory",

		"puzzle": {
			"type": "multiple_choice",
			"mode": "choice",
			"question": "Clue: pet name + lucky number\nWhich password fits?",
			"choices": ["Remi7", "7Remi", "RemiRemi"],
			"correct_answer": "Remi7",
			"correct_index": 0,
			"hint": "Name first, then the lucky number 7.",
			"explanation": "Remi7 matches the clue — your first stamped password!",
		},

		"rewards": {
			"tokens": 10,
			"xp": 25,
			"nft": {
				"nft_id": "pattern_star_nft",
				"name": "Factory Worker Badge",
				"description": "Awarded for completing your first shift at the Password Factory!",
				"rarity": "common",
				"image_path": "res://assets/icons/nfts/pattern_star_nft.png",
				"discovered_from": "First Shift at the Password Factory",
				"tradeable": false,
				"equipped": false,
				"token_value": 5,
			},
		},

		"repeatable": false,

		"dialogue_intro": [
			"[The Password Factory] *WHIRR-CLANK* Welcome to the Password Factory! 🏭",
			"[The Password Factory] I'm the machine that turns cracked codes into stamped passwords.",
			"[The Password Factory] Your job? Crack clues, build passwords, earn VIBE tokens!",
			{
				"type": "question",
				"text": "Ready to clock in for your first shift?",
				"choices": ["Let's crack codes!", "Not yet"],
				"responses": [
					[
						"[The Password Factory] Conveyor's warming up — here's your first clue!",
						{"type": "action", "action": "present_puzzle"},
					],
					[
						"[The Password Factory] No rush — the factory runs 24/7. Come back anytime!",
					],
				],
			},
		],

		"dialogue_success": [
			"[The Password Factory] *STAMP* Password accepted! 🌟",
			"[The Password Factory] Remi7 — name plus lucky number. Perfect crack!",
			"[The Password Factory] First shift complete! Here's your pay and badge!",
		],

		"dialogue_failure": [
			"[The Password Factory] Conveyor jam! That code didn't fit.",
			"[The Password Factory] Hint: pet name FIRST, then the lucky number.",
			"[The Password Factory] Try the line again — you've got this!",
		],

		"dialogue_complete": [
			"[The Password Factory] First shift done! You're on the payroll now.",
			"[The Password Factory] Clock in anytime — codes get harder, pay gets bigger!",
		],
	},

	# ──────────────────────────────────────────────────────────
	# CHESS — "Knight's Jump"
	# ──────────────────────────────────────────────────────────
	"chess_knight_jump": {
		"mission_id": "chess_knight_jump",
		"title": "Save the Piece",
		"description": "Move threatened chess pieces to safety on a real 8×8 board!",
		"npc_id": "chess_tutor",
		"npc_name": "Chess Tutor",

		"challenge": {
			"panel": "ChessPuzzlePanel",
			"rounds": 3,
			"required_correct": 2,
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
			"[Chess Tutor] On a real board, pieces can come under attack — your job is to move them to safety.",
			{
				"type": "question",
				"text": "Ready to save some pieces in danger?",
				"choices": ["Let's play!", "Tell me more"],
				"responses": [
					[
						"[Chess Tutor] Click a green-highlighted square to move the red piece to safety!",
						{"type": "action", "action": "present_puzzle"},
					],
					[
						"[Chess Tutor] Green squares show where the piece can move. Pick one the attacker can't reach!",
						{"type": "action", "action": "present_puzzle"},
					],
				],
			},
		],
		"dialogue_success": [
			"[Chess Tutor] Brilliant! You kept your pieces safe! ♞",
			"[Chess Tutor] Here's your badge — wear it with pride!",
		],
		"dialogue_failure": [
			"[Chess Tutor] That square was still under attack — look at what the enemy covers.",
			"[Chess Tutor] Try again and find a truly safe escape!",
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
			{
				"type": "question",
				"text": "Think you can score 2 out of 3 goals?",
				"choices": ["Bring it on!", "I'm still learning"],
				"responses": [
					[
						"[Coach Kick] That's the spirit! Step up to the spot!",
						{"type": "action", "action": "present_puzzle"},
					],
					[
						"[Coach Kick] Everyone starts somewhere — give it a try!",
						{"type": "action", "action": "present_puzzle"},
					],
				],
			},
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
			{
				"type": "question",
				"text": "Do you have a good eye for color mixing?",
				"choices": ["Absolutely!", "I'll try my best"],
				"responses": [
					[
						"[Artist Pip] Love the confidence — let's paint!",
						{"type": "action", "action": "present_puzzle"},
					],
					[
						"[Artist Pip] That's all you need — practice makes perfect!",
						{"type": "action", "action": "present_puzzle"},
					],
				],
			},
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
			{
				"type": "question",
				"text": "Want to play fetch with Daisy?",
				"choices": ["Yes! Throw the sticks!", "Maybe later"],
				"responses": [
					[
						"[Daisy] (Daisy barks and wags her tail!)",
						{"type": "action", "action": "present_puzzle"},
					],
					[
						"[Daisy] (Daisy lies down with a hopeful look.)",
					],
				],
			},
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
			{
				"type": "question",
				"text": "Ready to put VIBE on the line?",
				"choices": ["Let's fight!", "Not today"],
				"responses": [
					[
						"[Pit Boss Mara] Win at least 2 rounds and cash out. Let's go!",
						{"type": "action", "action": "present_puzzle"},
					],
					[
						"[Pit Boss Mara] Smart to wait until you're loaded with VIBE.",
					],
				],
			},
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
			{
				"type": "question",
				"text": "Is Daisy ready to run the course?",
				"choices": ["She's ready!", "We need practice"],
				"responses": [
					[
						"[Coach Bolt] Then let's graduate! Get at least 3 out of 5!",
						{"type": "action", "action": "present_puzzle"},
					],
					[
						"[Coach Bolt] Practice makes perfect — run it anyway!",
						{"type": "action", "action": "present_puzzle"},
					],
				],
			},
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
			{
				"type": "question",
				"text": "Eight minutes to Boston — think you can make it?",
				"choices": ["I'm ready to roll!", "Tell me more first"],
				"responses": [
					[
						"[Maple] Go! Fall and you'll stumble — that costs time!",
						{"type": "action", "action": "present_puzzle"},
					],
					[
						"[Maple] If you're late, Daisy becomes a frog and your hair falls out. Now GO!",
						{"type": "action", "action": "present_puzzle"},
					],
				],
			},
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
