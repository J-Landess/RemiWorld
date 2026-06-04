## CodingPuzzleBank.gd — progressive math & coding puzzles for Coding Bot.
class_name CodingPuzzleBank
extends RefCounted


static func get_puzzle_for_level(level: int) -> Dictionary:
	var tier := clampi(level, 0, 12)
	if tier <= 2:
		return _pattern_puzzle(tier)
	if tier <= 6:
		return _math_puzzle(tier)
	return _coding_puzzle(tier)


static func tier_label(level: int) -> String:
	if level <= 2:
		return "Patterns"
	if level <= 6:
		return "Math"
	return "Coding"


static func _pattern_puzzle(tier: int) -> Dictionary:
	var puzzles: Array = [
		{
			"question": "What comes next?\n🔴 Red, 🔵 Blue, 🔴 Red, 🔵 Blue, ___?",
			"display_pattern": ["🔴", "🔵", "🔴", "🔵", "❓"],
			"choices": ["Red", "Blue", "Green"],
			"correct_index": 0,
			"hint": "The colors alternate.",
			"explanation": "Red, Blue, Red, Blue — next is Red!",
		},
		{
			"question": "What comes next?\n⭐ Star, 🌙 Moon, ⭐ Star, 🌙 Moon, ___?",
			"display_pattern": ["⭐", "🌙", "⭐", "🌙", "❓"],
			"choices": ["Star", "Moon", "Sun"],
			"correct_index": 0,
			"hint": "Star and Moon take turns.",
			"explanation": "The pattern repeats: Star, Moon, Star, Moon…",
		},
		{
			"question": "What comes next?\n1, 2, 3, 4, ___?",
			"display_pattern": ["1", "2", "3", "4", "❓"],
			"choices": ["5", "4", "6"],
			"correct_index": 0,
			"hint": "Count up by one each time.",
			"explanation": "Each number is one bigger: 5 comes next!",
		},
	]
	return _wrap(puzzles[tier % puzzles.size()], "pattern")


static func _math_puzzle(tier: int) -> Dictionary:
	var a := 2 + (tier - 3)
	var b := 1 + (tier % 3)
	var correct: int
	var question: String
	if tier <= 4:
		correct = a + b
		question = "What is %d + %d?" % [a, b]
	else:
		correct = a * b
		question = "What is %d × %d?" % [a, b]
	var choices: Array = [str(correct), str(correct + 2), str(maxi(correct - 1, 1))]
	var correct_index := randi() % 3
	var pick: Array = choices.duplicate()
	pick[0] = choices[correct_index]
	pick[correct_index] = choices[0]
	return _wrap({
		"question": question,
		"display_pattern": [],
		"choices": pick,
		"correct_index": correct_index,
		"hint": "Take your time and add or multiply carefully.",
		"explanation": "The answer is %d." % correct,
	}, "math")


static func _coding_puzzle(tier: int) -> Dictionary:
	var puzzles: Array = [
		{
			"question": "In code, what does `print(\"Hi\")` do?",
			"choices": ["Shows text on screen", "Deletes a file", "Moves the player"],
			"correct_index": 0,
			"hint": "Print means show a message.",
			"explanation": "print() displays text — like saying Hi!",
		},
		{
			"question": "Which is a variable name?",
			"choices": ["score", "123jump", "my score"],
			"correct_index": 0,
			"hint": "Variables can't start with a number or have spaces.",
			"explanation": "`score` is a valid name. Numbers-first and spaces break the rules.",
		},
		{
			"question": "What does `if health < 1` check?",
			"choices": ["Is health below 1?", "Adds 1 to health", "Draws a circle"],
			"correct_index": 0,
			"hint": "`<` means less than.",
			"explanation": "An if checks a condition — here, health under 1.",
		},
		{
			"question": "A `for i in range(3)` loop runs how many times?",
			"choices": ["3 times", "1 time", "Forever"],
			"correct_index": 0,
			"hint": "range(3) counts 0, 1, 2.",
			"explanation": "range(3) gives three steps — the loop runs 3 times.",
		},
		{
			"question": "Which line stores the number 10 in `lives`?",
			"choices": ["lives = 10", "10 = lives", "lives + 10"],
			"correct_index": 0,
			"hint": "Put the variable name on the left of =",
			"explanation": "`lives = 10` saves 10 into the lives variable.",
		},
	]
	var idx := (tier - 7) % puzzles.size()
	return _wrap(puzzles[idx], "coding")


static func _wrap(data: Dictionary, kind: String) -> Dictionary:
	data["type"] = "multiple_choice"
	data["kind"] = kind
	return data
