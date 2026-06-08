## RoadToBostonManager.gd — timed roller-skate run to Zia in Boston.
extends Node2D

const HUDScene := preload("res://scenes/ui/HUD.tscn")
const RunnerScript := preload("res://scripts/systems/game_state/RoadSkateRunner.gd")
const PLAYGROUND_PATH := "res://scenes/levels/v1_playground/Playground.tscn"
const MISSION_ID := "road_to_boston"

const JOURNEY_TIME: float = 480.0

var _hud: Node = null
var _runner: Control = null
var _timer_label: Label = null
var _hint_label: Label = null
var _failed: bool = false
var _won: bool = false
var _exit_started: bool = false
var _mission_data: Dictionary = {}


func _ready() -> void:
	get_tree().paused = false
	GameState.current_scene = "res://scenes/levels/v1_road_to_boston/RoadToBoston.tscn"
	_mission_data = MissionDatabase.get_mission(MISSION_ID)

	if not GameState.road_journey_active:
		GameState.start_road_journey(JOURNEY_TIME)

	_spawn_hud()
	_spawn_runner()
	_setup_timer_ui()
	_update_timer_label()
	AudioManager.play_music("road_to_boston")
	_show_intro()


func _show_intro() -> void:
	if _hud and _hud.has_method("show_notification"):
		_hud.show_notification("🛼 Skate to Zia in Boston! Dodge, jump, trick — beat the clock!")


func _spawn_hud() -> void:
	_hud = HUDScene.instantiate()
	add_child(_hud)


func _spawn_runner() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	_runner = Control.new()
	_runner.set_script(RunnerScript)
	_runner.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_runner)
	_runner.section_cleared.connect(_on_section_cleared)
	_runner.stumble_hit.connect(_on_stumble)
	_runner.air_trick.connect(_on_air_trick)
	_runner.reached_zia.connect(_on_reached_zia)


func _process(delta: float) -> void:
	if _failed or _won or not GameState.road_journey_active:
		return

	GameState.road_time_remaining = maxf(GameState.road_time_remaining - delta, 0.0)
	_update_timer_label()

	if GameState.road_time_remaining <= 0.0:
		_on_time_up()


func _on_time_up() -> void:
	if _failed or _exit_started:
		return
	_exit_started = true
	_failed = true
	GameState.apply_zia_curse()
	AudioManager.play_sfx("wrong")
	if _hud and _hud.has_method("show_notification"):
		_hud.show_notification("⏰ Too late! Zia's curse: Daisy is a frog and your hair fell out!")
	await get_tree().create_timer(3.0).timeout
	_return_to_playground()


func _on_section_cleared(idx: int) -> void:
	GameState.road_milestone = idx + 1
	SaveManager.save_game()
	if _hud and _hud.has_method("show_notification"):
		_hud.show_notification("✅ %s cleared! (%d/5)" % [
			RoadSkateRunner.SECTIONS[idx].name, GameState.road_milestone
		])
	_update_timer_label()


func _on_stumble() -> void:
	if _runner:
		GameState.road_time_remaining = maxf(
			GameState.road_time_remaining - _runner.get_time_penalty(), 0.0
		)
	if _hud and _hud.has_method("show_notification"):
		_hud.show_notification("💥 Stumble! -%ds" % int(_runner.get_time_penalty()))
	_update_timer_label()


func _on_air_trick() -> void:
	if _runner:
		GameState.road_time_remaining += _runner.get_trick_bonus()
	if _hud and _hud.has_method("show_notification"):
		_hud.show_notification("✨ Air trick! +%ds" % int(_runner.get_trick_bonus()))


func _on_reached_zia() -> void:
	if _won or _failed:
		return
	if GameState.road_milestone < 5:
		return
	_won = true
	var box := _get_dialogue_box()
	var lines: Array = _mission_data.get("dialogue_success", [
		"[Zia] Remi! My darling! You skated here on time!",
		"[Zia] Star cookies for my favorite grandkid. Never sass a witch!",
	])
	if box:
		box.show_dialogue("Zia", lines, self, true)
	else:
		_finish_success()


func _present_puzzle() -> void:
	_finish_success()


func on_dialogue_finished() -> void:
	pass  # Rewards + exit handled in _present_puzzle (show_puzzle_after flow)


func _finish_success() -> void:
	if _exit_started:
		return
	_exit_started = true
	_won = true

	var rewards: Dictionary = _mission_data.get("rewards", {})
	RewardManager.grant_reward(rewards)
	MissionManager.complete_mission(MISSION_ID, rewards)
	journey_succeeded()
	GameState.daisy_is_frog = false
	GameState.remi_bald = false
	GameState.zia_curse_active = false
	SaveManager.save_game()
	AudioManager.play_sfx("reward")
	await get_tree().create_timer(2.0).timeout
	_return_to_playground()


func _return_to_playground() -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	if tree:
		tree.call_deferred("change_scene_to_file", PLAYGROUND_PATH)


func _setup_timer_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_timer_label = Label.new()
	_timer_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_timer_label.offset_top = 52
	_timer_label.offset_left = -200
	_timer_label.offset_right = 200
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.add_theme_font_size_override("font_size", 22)
	_timer_label.modulate = Color(1, 0.92, 0.55)
	layer.add_child(_timer_label)
	_hint_label = Label.new()
	_hint_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_hint_label.offset_top = 78
	_hint_label.offset_left = -280
	_hint_label.offset_right = 280
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_font_size_override("font_size", 13)
	layer.add_child(_hint_label)


func _update_timer_label() -> void:
	if not _timer_label:
		return
	var t: float = GameState.road_time_remaining
	var mins: int = int(t) / 60
	var secs: int = int(t) % 60
	_timer_label.text = "⏱️ Boston: %d:%02d" % [mins, secs]
	_timer_label.modulate = Color(1, 0.35, 0.35) if t < 60.0 else Color(1, 0.92, 0.55)
	if _hint_label:
		_hint_label.text = "Sections: %d / 5  ·  Reach Zia's cottage!" % GameState.road_milestone


func _get_dialogue_box() -> Node:
	if _hud:
		return _hud.get_node_or_null("DialogueBox")
	return null


func journey_succeeded() -> void:
	_failed = true
	GameState.clear_road_journey()
	GameState.zia_curse_active = false
	GameState.daisy_is_frog = false
	GameState.remi_bald = false
