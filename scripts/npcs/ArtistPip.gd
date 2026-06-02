## ArtistPip.gd
## =============================================================
## Friendly artist who teaches color mixing.
##
## Mission: "Rainbow Maker"
## Reward:  12 VIBE + 30 XP + Palette Badge NFT
## =============================================================
extends "res://scripts/npcs/NPC.gd"

const MISSION_ID: String = "art_rainbow_maker"

var _mission_data: Dictionary = {}


func _ready() -> void:
	npc_name = "Artist Pip"
	npc_id = "artist_pip"
	sprite_color = Color(0.95, 0.55, 0.75)

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

	if MissionManager.is_mission_complete(MISSION_ID):
		if dialogue_box:
			dialogue_box.show_dialogue(npc_name, _get_dialogue_lines(), self)
		return

	MissionManager.start_mission(MISSION_ID)
	if dialogue_box:
		dialogue_box.show_dialogue(npc_name, _get_dialogue_lines(), self, true)
	else:
		_present_puzzle()


func _present_puzzle() -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_challenge"):
		hud.show_challenge("ArtPalettePanel", _mission_data, self)


func on_challenge_finished(success: bool) -> void:
	var dialogue_box := _find_dialogue_box()

	if success:
		var rewards: Dictionary = _mission_data.get("rewards", {})
		RewardManager.grant_reward(rewards)
		MissionManager.complete_mission(MISSION_ID, rewards)
		SaveManager.save_game()
		_update_quest_marker()
		if dialogue_box:
			dialogue_box.show_dialogue(npc_name, _mission_data.get("dialogue_success", []), self)
	else:
		if dialogue_box:
			dialogue_box.show_dialogue(npc_name, _mission_data.get("dialogue_failure", []), self)
		await get_tree().create_timer(0.5).timeout
		_is_talking = false


func on_dialogue_finished() -> void:
	_is_talking = false
	emit_signal("dialogue_ended")


func _update_quest_marker() -> void:
	var marker := get_node_or_null("QuestMarker")
	if marker:
		marker.visible = not MissionManager.is_mission_complete(MISSION_ID)
