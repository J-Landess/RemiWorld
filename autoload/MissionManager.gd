## MissionManager.gd
## =============================================================
## Tracks all missions (quests) in the game: which are available,
## which are in-progress, and which are completed.
##
## Usage from any script:
##   MissionManager.start_mission("pattern_power")
##   MissionManager.complete_mission("pattern_power")
##   MissionManager.is_mission_complete("pattern_power")
## =============================================================
extends Node

# ─────────────────────────────────────────────────────────────
# SIGNALS
# ─────────────────────────────────────────────────────────────
signal mission_started(mission_id: String)
signal mission_completed(mission_id: String, rewards: Dictionary)
signal mission_status_changed(mission_id: String, status: String)

# ─────────────────────────────────────────────────────────────
# MISSION STATUS VALUES
# ─────────────────────────────────────────────────────────────
const STATUS_LOCKED: String     = "locked"     # Not yet available
const STATUS_AVAILABLE: String  = "available"  # Can be started
const STATUS_IN_PROGRESS: String = "in_progress" # Started but not done
const STATUS_COMPLETE: String   = "complete"   # Successfully finished
const STATUS_FAILED: String     = "failed"     # Failed (if applicable)

# ─────────────────────────────────────────────────────────────
# MISSION REGISTRY — stores status and progress for each mission
# Key = mission_id (String), Value = mission status dict
# ─────────────────────────────────────────────────────────────
var _mission_states: Dictionary = {}

# How many times each mission has been completed (for repeatable missions)
var _completion_counts: Dictionary = {}


# ─────────────────────────────────────────────────────────────
# CALLED WHEN GAME STARTS
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	# Register all missions with their starting status
	_register_default_missions()


func _register_default_missions() -> void:
	# All missions start as "available" unless they require prerequisites
	_set_mission_status("pattern_power", STATUS_AVAILABLE)
	# Future missions can be added here and set to STATUS_LOCKED until unlocked


# ─────────────────────────────────────────────────────────────
# MISSION STATUS MANAGEMENT
# ─────────────────────────────────────────────────────────────
func get_mission_status(mission_id: String) -> String:
	return _mission_states.get(mission_id, STATUS_LOCKED)


func _set_mission_status(mission_id: String, status: String) -> void:
	_mission_states[mission_id] = status
	emit_signal("mission_status_changed", mission_id, status)


func start_mission(mission_id: String) -> bool:
	var status := get_mission_status(mission_id)
	if status != STATUS_AVAILABLE:
		print("[MissionManager] Cannot start mission '%s' — status: %s" % [mission_id, status])
		return false

	_set_mission_status(mission_id, STATUS_IN_PROGRESS)
	emit_signal("mission_started", mission_id)
	print("[MissionManager] Mission started: ", mission_id)
	return true


func complete_mission(mission_id: String, rewards: Dictionary = {}) -> bool:
	var status := get_mission_status(mission_id)

	# Allow completing from either in_progress or available state
	if status != STATUS_IN_PROGRESS and status != STATUS_AVAILABLE:
		print("[MissionManager] Cannot complete mission '%s' — status: %s" % [mission_id, status])
		return false

	_set_mission_status(mission_id, STATUS_COMPLETE)
	_completion_counts[mission_id] = _completion_counts.get(mission_id, 0) + 1

	emit_signal("mission_completed", mission_id, rewards)
	print("[MissionManager] Mission completed: ", mission_id)
	return true


# ─────────────────────────────────────────────────────────────
# QUERY HELPERS
# ─────────────────────────────────────────────────────────────
func is_mission_complete(mission_id: String) -> bool:
	return get_mission_status(mission_id) == STATUS_COMPLETE


func is_mission_available(mission_id: String) -> bool:
	return get_mission_status(mission_id) == STATUS_AVAILABLE


func is_mission_in_progress(mission_id: String) -> bool:
	return get_mission_status(mission_id) == STATUS_IN_PROGRESS


func get_completion_count(mission_id: String) -> int:
	return _completion_counts.get(mission_id, 0)


func get_all_mission_statuses() -> Dictionary:
	return _mission_states.duplicate()


func get_completed_missions() -> Array:
	var completed: Array = []
	for mission_id in _mission_states:
		if _mission_states[mission_id] == STATUS_COMPLETE:
			completed.append(mission_id)
	return completed


# ─────────────────────────────────────────────────────────────
# UNLOCK A MISSION (used when prerequisites are met)
# ─────────────────────────────────────────────────────────────
func unlock_mission(mission_id: String) -> void:
	if get_mission_status(mission_id) == STATUS_LOCKED:
		_set_mission_status(mission_id, STATUS_AVAILABLE)
		print("[MissionManager] Mission unlocked: ", mission_id)


# ─────────────────────────────────────────────────────────────
# SERIALIZATION
# ─────────────────────────────────────────────────────────────
func to_dict() -> Dictionary:
	return {
		"mission_states": _mission_states,
		"completion_counts": _completion_counts,
	}


func from_dict(data: Dictionary) -> void:
	_mission_states = data.get("mission_states", {})
	_completion_counts = data.get("completion_counts", {})
	# Make sure default missions exist even in old saves
	if not _mission_states.has("pattern_power"):
		_mission_states["pattern_power"] = STATUS_AVAILABLE
