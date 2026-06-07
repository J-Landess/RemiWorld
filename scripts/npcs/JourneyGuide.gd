## JourneyGuide.gd — starts the timed Road to Boston journey.
extends "res://scripts/npcs/NPC.gd"

const MISSION_ID: String = "road_to_boston"
const ROAD_SCENE: String = "res://scenes/levels/v1_road_to_boston/RoadToBoston.tscn"

var _mission_data: Dictionary = {}


func _ready() -> void:
	npc_name = "Maple the Guide"
	npc_id = "journey_guide"
	sprite_color = Color(0.45, 0.65, 0.35)
	_mission_data = MissionDatabase.get_mission(MISSION_ID)
	super._ready()
	_update_quest_marker()


func _get_dialogue_lines() -> Array:
	if MissionManager.is_mission_complete(MISSION_ID):
		return _mission_data.get("dialogue_complete", [])
	if GameState.road_journey_active:
		return [
			"[Maple] You're already on the road! Hurry — Zia is waiting in Boston!",
		]
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

	if GameState.road_journey_active:
		if dialogue_box:
			dialogue_box.show_dialogue(npc_name, _get_dialogue_lines(), self)
		return

	if MissionManager.get_mission_status(MISSION_ID) == MissionManager.STATUS_LOCKED:
		MissionManager.unlock_mission(MISSION_ID)
	MissionManager.start_mission(MISSION_ID)

	if dialogue_box:
		dialogue_box.show_dialogue(npc_name, _get_dialogue_lines(), self, true)
	else:
		_present_puzzle()


func _present_puzzle() -> void:
	GameState.start_road_journey(480.0)
	SaveManager.save_game()
	get_tree().change_scene_to_file(ROAD_SCENE)


func on_dialogue_finished() -> void:
	_is_talking = false
	emit_signal("dialogue_ended")


func _update_quest_marker() -> void:
	var marker := get_node_or_null("QuestMarker")
	if marker:
		marker.visible = not MissionManager.is_mission_complete(MISSION_ID)
