## CodingBot.gd
## =============================================================
## The first NPC the player meets in Remi's Start Area.
## Coding Bot teaches logic patterns and gives the first mission.
##
## Mission: "Pattern Power"
## Reward:  10 VIBE + 25 XP + Pattern Star Badge NFT
##
## Inherits from NPC.gd (which handles basic interaction logic)
## =============================================================
extends "res://scripts/npcs/NPC.gd"

# ─────────────────────────────────────────────────────────────
# SIGNALS (mission-specific)
# ─────────────────────────────────────────────────────────────
signal puzzle_presented()
signal puzzle_answered(correct: bool)

# ─────────────────────────────────────────────────────────────
# MISSION DATA
# ─────────────────────────────────────────────────────────────
const MISSION_ID: String = "pattern_power"

# ─────────────────────────────────────────────────────────────
# INTERNAL STATE
# ─────────────────────────────────────────────────────────────
var _in_puzzle_mode: bool = false
var _mission_data: Dictionary = {}


# ─────────────────────────────────────────────────────────────
# SETUP
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	# Set default NPC properties
	npc_name = "Coding Bot"
	npc_id = "coding_bot"
	sprite_color = Color(0.4, 0.8, 1.0)  # Light blue placeholder color

	# Load mission data from the database
	_mission_data = MissionDatabase.get_mission(MISSION_ID)

	# Call the parent ready (sets up name tag, groups, etc.)
	super._ready()
	_update_quest_marker()


# ─────────────────────────────────────────────────────────────
# OVERRIDE: Return the right dialogue based on mission state
# ─────────────────────────────────────────────────────────────
func _get_dialogue_lines() -> Array:
	if MissionManager.is_mission_complete(MISSION_ID):
		return _mission_data.get("dialogue_complete", [
			"[Coding Bot] You already solved my pattern! Great work! 🌟"
		])
	else:
		return _mission_data.get("dialogue_intro", [
			"[Coding Bot] Hi! I'm Coding Bot! Can you solve my pattern puzzle?"
		])


# ─────────────────────────────────────────────────────────────
# OVERRIDE: Custom interaction triggers the puzzle
# ─────────────────────────────────────────────────────────────
func on_player_interact(_player: Node) -> void:
	if _is_talking:
		return

	_is_talking = true

	var dialogue_box := _find_dialogue_box()

	# If the mission is already complete, just show completion dialogue
	if MissionManager.is_mission_complete(MISSION_ID):
		if dialogue_box:
			dialogue_box.show_dialogue(npc_name, _get_dialogue_lines(), self)
		return

	# Otherwise, start the mission and show intro dialogue
	MissionManager.start_mission(MISSION_ID)
	if dialogue_box:
		# Show intro dialogue, then trigger the puzzle when it's done
		dialogue_box.show_dialogue(
			npc_name,
			_get_dialogue_lines(),
			self,
			true  # "show_puzzle_after" flag
		)
	else:
		# No dialogue box — show puzzle directly (fallback)
		_present_puzzle()


# ─────────────────────────────────────────────────────────────
# PUZZLE — show the logic challenge
# ─────────────────────────────────────────────────────────────
func _present_puzzle() -> void:
	_in_puzzle_mode = true
	emit_signal("puzzle_presented")

	# Find the puzzle UI and activate it
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_puzzle"):
		hud.show_puzzle(_mission_data.get("puzzle", {}), self)
	else:
		push_warning("[CodingBot] Could not find HUD to show puzzle!")


# ─────────────────────────────────────────────────────────────
# CALLED WHEN PLAYER ANSWERS THE PUZZLE
# ─────────────────────────────────────────────────────────────
func on_puzzle_answered(answer_index: int) -> void:
	_in_puzzle_mode = false
	var puzzle: Dictionary = _mission_data.get("puzzle", {})
	var correct_index: int = puzzle.get("correct_index", 0)
	var correct: bool = (answer_index == correct_index)

	emit_signal("puzzle_answered", correct)

	var dialogue_box := _find_dialogue_box()

	if correct:
		# Grant the reward!
		var rewards: Dictionary = _mission_data.get("rewards", {})
		RewardManager.grant_reward(rewards)
		MissionManager.complete_mission(MISSION_ID, rewards)
		SaveManager.save_game()
		_update_quest_marker()

		if dialogue_box:
			dialogue_box.show_dialogue(
				npc_name,
				_mission_data.get("dialogue_success", ["[Coding Bot] Amazing! You got it! 🌟"]),
				self
			)
	else:
		if dialogue_box:
			dialogue_box.show_dialogue(
				npc_name,
				_mission_data.get("dialogue_failure", ["[Coding Bot] Hmm, not quite! Try again!"]),
				self
			)
		# Let them try again after the dialogue
		await get_tree().create_timer(0.5).timeout
		_is_talking = false


# Called by the dialogue box when it's done displaying
func on_dialogue_finished() -> void:
	_is_talking = false
	emit_signal("dialogue_ended")


func _update_quest_marker() -> void:
	var marker := get_node_or_null("QuestMarker")
	if marker:
		marker.visible = not MissionManager.is_mission_complete(MISSION_ID)
