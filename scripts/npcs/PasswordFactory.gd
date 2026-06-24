## PasswordFactory.gd — repeatable password-cracking job with scaling VIBE pay.
extends "res://scripts/npcs/NPC.gd"

signal puzzle_presented()
signal puzzle_answered(correct: bool)

const MISSION_ID: String = "pattern_power"
const PuzzleBank := preload("res://scripts/data/PasswordPuzzleBank.gd")

var _in_puzzle_mode: bool = false
var _mission_data: Dictionary = {}
var _work_mode: bool = false


func _ready() -> void:
	npc_name = "The Password Factory"
	npc_id = "password_factory"
	sprite_color = Color(0.0, 0.9, 1.0)
	_mission_data = MissionDatabase.get_mission(MISSION_ID)
	super._ready()
	_update_quest_marker()


func _get_dialogue_lines() -> Array:
	if not MissionManager.is_mission_complete(MISSION_ID):
		return _mission_data.get("dialogue_intro", [])
	var lvl: int = GameState.password_factory_level
	var tier: String = PuzzleBank.tier_label(lvl)
	return [
		"[The Password Factory] Welcome back, code cracker!",
		"[The Password Factory] Shift %d — %s tier. Pay: +%d VIBE per stamp." % [
			lvl + 1, tier, PuzzleBank.payout_for_level(lvl),
		],
		{
			"type": "question",
			"text": "Ready to clock in for another shift?",
			"choices": ["Let's crack codes!", "Not right now"],
			"responses": [
				[{"type": "action", "action": "present_puzzle"}],
				["[The Password Factory] The factory never sleeps. Come back anytime!"],
			],
		},
	]


func on_player_interact(_player: Node) -> void:
	if _is_talking:
		return
	_is_talking = true

	var dialogue_box := _find_dialogue_box()

	if MissionManager.is_mission_complete(MISSION_ID):
		_work_mode = true
		if dialogue_box:
			dialogue_box.show_dialogue(npc_name, _get_dialogue_lines(), self)
		else:
			_present_puzzle()
		return

	_work_mode = false
	MissionManager.start_mission(MISSION_ID)
	if dialogue_box:
		dialogue_box.show_dialogue(npc_name, _mission_data.get("dialogue_intro", []), self)
	else:
		_present_puzzle()


func _present_puzzle() -> void:
	_in_puzzle_mode = true
	emit_signal("puzzle_presented")

	var level: int = GameState.password_factory_level
	var puzzle: Dictionary

	if _work_mode:
		puzzle = PuzzleBank.get_puzzle_for_level(level)
	else:
		puzzle = _mission_data.get("puzzle", {}).duplicate(true)
		puzzle["mode"] = "choice"

	var mission_payload := {
		"puzzle": puzzle,
		"level": level if _work_mode else 0,
		"payout": PuzzleBank.payout_for_level(level if _work_mode else 0),
	}

	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_challenge"):
		hud.show_challenge("PasswordFactoryPanel", mission_payload, self)
	else:
		push_warning("[PasswordFactory] Could not find HUD to show challenge!")


func on_challenge_finished(success: bool) -> void:
	_in_puzzle_mode = false
	emit_signal("puzzle_answered", success)

	var dialogue_box := _find_dialogue_box()
	var level: int = GameState.password_factory_level

	if success:
		if _work_mode:
			var payout: int = PuzzleBank.payout_for_level(level)
			GameState.password_factory_level += 1
			GameState.add_tokens(payout)
			GameState.add_xp(6 + level * 2)
			SaveManager.save_game()
			if dialogue_box:
				dialogue_box.show_dialogue(npc_name, [
					"[The Password Factory] Password stamped! +%d VIBE 💰" % payout,
					"[The Password Factory] You're now shift level %d. Harder codes, bigger pay!" % (
						GameState.password_factory_level + 1
					),
				], self)
		else:
			var rewards: Dictionary = _mission_data.get("rewards", {}).duplicate()
			rewards["source_id"] = _mission_data.get("mission_id", MISSION_ID)
			RewardManager.grant_reward(rewards)
			MissionManager.complete_mission(MISSION_ID, rewards)
			SaveManager.save_game()
			_update_quest_marker()
			if dialogue_box:
				dialogue_box.show_dialogue(npc_name, _mission_data.get("dialogue_success", []), self)
	else:
		var fail_lines: Array
		if _work_mode:
			fail_lines = [
				"[The Password Factory] Conveyor jam! Shift %d is tricky." % (level + 1),
				"[The Password Factory] Read the hint and try the line again!",
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
