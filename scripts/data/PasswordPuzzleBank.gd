## PasswordPuzzleBank.gd — progressive password challenges for The Password Factory.
class_name PasswordPuzzleBank
extends RefCounted


static func get_puzzle_for_level(level: int) -> Dictionary:
	var tier := clampi(level, 0, 15)
	if tier <= 2:
		return _crack_code_choice(tier)
	if tier <= 5:
		return _valid_password_choice(tier)
	if tier <= 8:
		return _assembly_puzzle(tier)
	return _decode_assembly_puzzle(tier)


static func tier_label(level: int) -> String:
	if level <= 2:
		return "Code Crack"
	if level <= 5:
		return "Password Rules"
	if level <= 8:
		return "Assembly Line"
	return "Cipher Shift"


static func payout_for_level(level: int) -> int:
	return 5 + level * 2


static func _crack_code_choice(tier: int) -> Dictionary:
	var puzzles: Array = [
		{
			"question": "Clue: pet name + lucky number\nWhich password fits?",
			"choices": ["Remi7", "7Remi", "RemiRemi"],
			"correct_index": 0,
			"hint": "Name first, then the lucky number 7.",
			"explanation": "Remi7 matches the clue perfectly!",
		},
		{
			"question": "Clue: favorite color + star emoji code\nWhich is the secret password?",
			"choices": ["BlueStar", "StarBlue", "BlueBlue"],
			"correct_index": 0,
			"hint": "Color word comes before Star.",
			"explanation": "BlueStar is the right combo!",
		},
		{
			"question": "Clue: first letter of your name, then 123\nPick the cracked code:",
			"choices": ["R123", "123R", "RRR123"],
			"correct_index": 0,
			"hint": "One letter, then the number block.",
			"explanation": "R123 follows the pattern!",
		},
	]
	var p: Dictionary = puzzles[tier % puzzles.size()].duplicate(true)
	p["mode"] = "choice"
	return p


static func _valid_password_choice(tier: int) -> Dictionary:
	var puzzles: Array = [
		{
			"question": "Rule: must have a letter AND a number.\nWhich password is valid?",
			"choices": ["Puppy", "Dog42", "12345"],
			"correct_index": 1,
			"hint": "Look for both letters and digits.",
			"explanation": "Dog42 has letters and a number!",
		},
		{
			"question": "Rule: at least 6 characters with a capital letter.\nWhich one works?",
			"choices": ["remi", "Remi12", "REMI"],
			"correct_index": 1,
			"hint": "Count the characters and find the capital.",
			"explanation": "Remi12 is long enough with a capital R!",
		},
		{
			"question": "Rule: no spaces, must end with !\nPick the valid factory password:",
			"choices": ["Go Team!", "GoTeam!", "Go Team"],
			"correct_index": 1,
			"hint": "No spaces allowed.",
			"explanation": "GoTeam! has no spaces and ends with !",
		},
	]
	var idx := (tier - 3) % puzzles.size()
	var p: Dictionary = puzzles[idx].duplicate(true)
	p["mode"] = "choice"
	return p


static func _assembly_puzzle(tier: int) -> Dictionary:
	var answers: Array = ["CODE", "LOCK", "SAFE", "KEYS"]
	var answer: String = answers[(tier - 6) % answers.size()]
	var tiles: Array = answer.split("")
	tiles.append_array(["X", "1", "9", "Z"])
	tiles.shuffle()
	return {
		"mode": "assembly",
		"question": "Tap tiles to build the password:\nHint: a 4-letter security word",
		"answer": answer,
		"tiles": tiles,
		"slots": answer.length(),
		"hint": "Read the hint — only four letters needed.",
		"explanation": "You stamped %s on the conveyor!" % answer,
	}


static func _decode_assembly_puzzle(tier: int) -> Dictionary:
	var pairs: Array = [
		{"encoded": "IFMM", "answer": "HELL", "shift": 1},
		{"encoded": "QBTT", "answer": "PASS", "shift": 1},
		{"encoded": "GSPW", "answer": "SAFE", "shift": 1},
	]
	var pair: Dictionary = pairs[(tier - 9) % pairs.size()]
	var tiles: Array = pair["answer"].split("")
	tiles.append_array(["A", "B", "X", "9"])
	tiles.shuffle()
	return {
		"mode": "assembly",
		"question": "Cipher shift +%d:\nDecode %s, then build the password." % [pair["shift"], pair["encoded"]],
		"answer": pair["answer"],
		"tiles": tiles,
		"slots": pair["answer"].length(),
		"hint": "Each letter shifts back by one in the alphabet.",
		"explanation": "%s decodes to %s!" % [pair["encoded"], pair["answer"]],
	}
