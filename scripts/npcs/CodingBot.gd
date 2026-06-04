## CodingBot.gd
## =============================================================
## Teaches patterns first, then a ladder of math & coding puzzles.
## =============================================================
extends "res://scripts/npcs/NPC.gd"

signal puzzle_presented()
signal puzzle_answered(correct: bool)

const MISSION_ID: String = "pattern_power"
const PuzzleBank := preload("res://scripts/data/CodingPuzzleBank.gd")

var _in_puzzle_mode: bool = false
var _mission_data: Dictionary = {}
var _training_mode: bool = false


func _ready() -> void:
	npc_name = "Coding Bot"
	npc_id = "coding_bot"
	sprite_color = Color(0.4, 0.8, 1.0)
	_mission_data = MissionDatabase.get_mission(MISSION_ID)
	super._ready()
	_update_quest_marker()


func _get_dialogue_lines() -> Array:
	if not MissionManager.is_mission_complete(MISSION_ID):
		return _mission_data.get("dialogue_intro", [])
	var lvl: int = GameState.coding_bot_level
	var tier: String = PuzzleBank.tier_label(lvl)
	return [
		"[Coding Bot] You're on training level %d — %s puzzles!" % [lvl + 1, tier],
		"[Coding Bot] Each win levels you up. Ready?",
	]


func on_player_interact(_player: Node) -> void:
	if _is_talking:
		return
	_is_talking = true

	var dialogue_box := _find_dialogue_box()

	if MissionManager.is_mission_complete(MISSION_ID):
		_training_mode = true
		if dialogue_box:
			dialogue_box.show_dialogue(npc_name, _get_dialogue_lines(), self, true)
		else:
			_present_puzzle()
		return

	_training_mode = false
	MissionManager.start_mission(MISSION_ID)
	if dialogue_box:
		dialogue_box.show_dialogue(npc_name, _mission_data.get("dialogue_intro", []), self, true)
	else:
		_present_puzzle()


func _present_puzzle() -> void:
	_in_puzzle_mode = true
	emit_signal("puzzle_presented")

	var puzzle: Dictionary
	if _training_mode:
		puzzle = PuzzleBank.get_puzzle_for_level(GameState.coding_bot_level)
		puzzle["question"] = "Level %d · %s\n%s" % [
			GameState.coding_bot_level + 1,
			PuzzleBank.tier_label(GameState.coding_bot_level),
			puzzle.get("question", ""),
		]
	else:
		puzzle = _mission_data.get("puzzle", {})

	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_puzzle"):
		hud.show_puzzle(puzzle, self)
	else:
		push_warning("[CodingBot] Could not find HUD to show puzzle!")


func on_puzzle_answered(answer_index: int) -> void:
	_in_puzzle_mode = false
	var puzzle: Dictionary
	if _training_mode:
		puzzle = PuzzleBank.get_puzzle_for_level(GameState.coding_bot_level)
	else:
		puzzle = _mission_data.get("puzzle", {})

	var correct_index: int = puzzle.get("correct_index", 0)
	var correct: bool = (answer_index == correct_index)
	emit_signal("puzzle_answered", correct)

	var dialogue_box := _find_dialogue_box()

	if correct:
		if _training_mode:
			GameState.coding_bot_level += 1
			GameState.add_tokens(3 + GameState.coding_bot_level)
			GameState.add_xp(8 + GameState.coding_bot_level * 2)
			SaveManager.save_game()
			if dialogue_box:
				dialogue_box.show_dialogue(npc_name, [
					"[Coding Bot] Level cleared! 🌟",
					"[Coding Bot] You're now training level %d. Keep going!" % (GameState.coding_bot_level + 1),
				], self)
		else:
			var rewards: Dictionary = _mission_data.get("rewards", {})
			RewardManager.grant_reward(rewards)
			MissionManager.complete_mission(MISSION_ID, rewards)
			SaveManager.save_game()
			_update_quest_marker()
			if dialogue_box:
				dialogue_box.show_dialogue(npc_name, _mission_data.get("dialogue_success", []), self)
	else:
		var fail_lines: Array
		if _training_mode:
			fail_lines = [
				"[Coding Bot] Close! Level %d is tricky." % (GameState.coding_bot_level + 1),
				"[Coding Bot] Read the hint and try again!",
			]
		else:
			fail_lines = _mission_data.get("dialogue_failure", [])
		if dialogue_box:
			dialogue_box.show_dialogue(npc_name, fail_lines, self)
		await get_tree().create_timer(0.5).timeout
		_is_talking = false


func on_dialogue_finished() -> void:
	_is_talking = false
	emit_signal("dialogue_ended")


func _update_quest_marker() -> void:
	var marker := get_node_or_null("QuestMarker")
	if marker:
		marker.visible = not MissionManager.is_mission_complete(MISSION_ID)
