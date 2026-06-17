## ChessTutor.gd
## =============================================================
## Chess Park hustler — sit at the table vs AI or a friend.
##
## Mission: "chess_knight_jump" (badge on first visit)
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


func on_player_interact(_player: Node) -> void:
	if _is_talking:
		return
	_is_talking = true

	if not MissionManager.is_mission_complete(MISSION_ID):
		MissionManager.start_mission(MISSION_ID)

	var dialogue_box := _find_dialogue_box()

	# Repeat visitors: skip the speech and sit at the board immediately.
	if MissionManager.is_mission_complete(MISSION_ID):
		_open_chess_park()
		return

	# First visit: one quick park intro, then open the board automatically.
	if dialogue_box:
		dialogue_box.show_dialogue(npc_name, [
			"[Chess Tutor] Welcome to the park, young thinker. ♟️",
			"[Chess Tutor] Street chess — play the hustler AI or a friend on the same device.",
			{"type": "action", "action": "present_puzzle"},
		], self)
	else:
		_open_chess_park()


func _present_puzzle() -> void:
	_open_chess_park()


func _open_chess_park() -> void:
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

	hud.show_challenge("ChessParkPanel", _mission_data, self)


func on_challenge_finished(success: bool) -> void:
	var dialogue_box := _find_dialogue_box()

	# Backing out shouldn't grant the badge.
	if success and not MissionManager.is_mission_complete(MISSION_ID):
		var rewards: Dictionary = _mission_data.get("rewards", {})
		RewardManager.grant_reward(rewards)
		MissionManager.complete_mission(MISSION_ID, rewards)
		SaveManager.save_game()
		_update_quest_marker()
		if dialogue_box:
			dialogue_box.show_dialogue(npc_name, _mission_data.get("dialogue_success", []), self)
			return

	_is_talking = false


func on_dialogue_finished() -> void:
	_is_talking = false
	emit_signal("dialogue_ended")


func _update_quest_marker() -> void:
	var marker := get_node_or_null("QuestMarker")
	if marker:
		marker.visible = not MissionManager.is_mission_complete(MISSION_ID)
