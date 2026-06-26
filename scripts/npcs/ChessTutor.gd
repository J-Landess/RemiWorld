## ChessTutor.gd
## =============================================================
## Chess Park hustler — sit at the table vs AI or a friend.
##
## Mission: "chess_knight_jump" (badge on first win)
## Reward:  12 VIBE + 30 XP + Knight Star Badge NFT
## =============================================================
extends "res://scripts/npcs/NPC.gd"

const MISSION_ID: String = "chess_knight_jump"

var _mission_data: Dictionary = {}


func _ready() -> void:
	npc_name = "Chess Tutor"
	npc_id = "chess_tutor"
	sprite_color = Color(0.55, 0.42, 0.78)

	_mission_data = MissionDatabase.get_mission(MISSION_ID)

	super._ready()
	_update_quest_marker()


func _get_dialogue_lines() -> Array:
	if MissionManager.is_mission_complete(MISSION_ID):
		return _mission_data.get("dialogue_complete", [])
	return _mission_data.get("dialogue_intro", [])


func on_player_interact(_player: Node) -> void:
	if _is_talking:
		return
	_is_talking = true

	var dialogue_box := _find_dialogue_box()

	# Badge already earned — skip the speech and sit at the board.
	if MissionManager.is_mission_complete(MISSION_ID):
		_present_puzzle()
		return

	if MissionManager.get_mission_status(MISSION_ID) == MissionManager.STATUS_LOCKED:
		MissionManager.unlock_mission(MISSION_ID)
	MissionManager.start_mission(MISSION_ID)

	if dialogue_box:
		dialogue_box.show_dialogue(npc_name, _get_dialogue_lines(), self)
	else:
		_present_puzzle()


func _present_puzzle() -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if not hud:
		push_warning("[ChessTutor] HUD not found — cannot open Chess Park.")
		_is_talking = false
		return
	if not hud.has_method("show_challenge"):
		push_warning("[ChessTutor] HUD has no show_challenge().")
		_is_talking = false
		return

	var panel := hud.get_node_or_null("ChessParkPanel")
	if not panel:
		push_warning("[ChessTutor] ChessParkPanel missing from HUD.")
		_is_talking = false
		return

	# Defer one frame so DialogueBox can finish closing first.
	hud.call_deferred("show_challenge", "ChessParkPanel", _mission_data, self)


func on_challenge_finished(success: bool) -> void:
	var dialogue_box := _find_dialogue_box()

	if success and not MissionManager.is_mission_complete(MISSION_ID):
		var rewards: Dictionary = _mission_data.get("rewards", {}).duplicate()
		rewards["source_id"] = _mission_data.get("mission_id", MISSION_ID)
		RewardManager.grant_reward(rewards)
		MissionManager.complete_mission(MISSION_ID, rewards)
		SaveManager.save_game()
		_update_quest_marker()
		if dialogue_box:
			dialogue_box.show_dialogue(npc_name, _mission_data.get("dialogue_success", []), self)
			return

	_is_talking = false


func on_dialogue_finished() -> void:
	# First-visit dialogue ends → open the chess board regardless of which choice was made.
	# Post-win success dialogue ends → just release the player.
	if not MissionManager.is_mission_complete(MISSION_ID):
		_present_puzzle()
		return
	_is_talking = false
	emit_signal("dialogue_ended")


func _update_quest_marker() -> void:
	var marker := get_node_or_null("QuestMarker")
	if marker:
		marker.visible = not MissionManager.is_mission_complete(MISSION_ID)
