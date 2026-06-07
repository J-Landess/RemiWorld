## ZiaWitch.gd — Remi's grandmother in Boston (a good witch, mostly).
extends "res://scripts/npcs/NPC.gd"

const MISSION_ID: String = "road_to_boston"
const PLAYGROUND_PATH: String = "res://scenes/levels/v1_playground/Playground.tscn"

var _mission_data: Dictionary = {}


func _ready() -> void:
	npc_name = "Zia"
	npc_id = "zia_witch"
	sprite_color = Color(0.55, 0.35, 0.72)
	add_to_group("zia_witch")
	_mission_data = MissionDatabase.get_mission(MISSION_ID)
	super._ready()


func on_player_interact(_player: Node) -> void:
	if _is_talking:
		return
	if GameState.road_milestone < 5:
		var hud := get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_notification"):
			hud.show_notification("Finish every stop on the road first!")
		return

	_is_talking = true
	var dialogue_box := _find_dialogue_box()

	if MissionManager.is_mission_complete(MISSION_ID):
		if dialogue_box:
			dialogue_box.show_dialogue(npc_name, _mission_data.get("dialogue_complete", []), self)
		return

	var lines: Array = _mission_data.get("dialogue_success", [
		"[Zia] Remi! My darling! You made it!",
		"[Zia] I baked star cookies. Never sass a witch — but you were perfect.",
	])
	if dialogue_box:
		dialogue_box.show_dialogue(npc_name, lines, self, true)
	else:
		_on_arrival_success()


func _present_puzzle() -> void:
	_on_arrival_success()


func _on_arrival_success() -> void:
	var rewards: Dictionary = _mission_data.get("rewards", {})
	RewardManager.grant_reward(rewards)
	MissionManager.complete_mission(MISSION_ID, rewards)

	var manager := get_tree().current_scene
	if manager and manager.has_method("journey_succeeded"):
		manager.journey_succeeded()

	GameState.daisy_is_frog = false
	GameState.remi_bald = false
	GameState.zia_curse_active = false
	SaveManager.save_game()

	_is_talking = false
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file(PLAYGROUND_PATH)


func on_dialogue_finished() -> void:
	_is_talking = false
	emit_signal("dialogue_ended")


func _find_dialogue_box() -> Node:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		return hud.get_node_or_null("DialogueBox")
	return null
