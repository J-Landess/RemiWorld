## CheckpointManager.gd
## =============================================================
## Handles the checkpoint save system.
##
## Checkpoints are triggered three ways:
##   1. Timed      — every 3 minutes of active play
##   2. Location   — player walks through a CheckpointZone Area2D
##   3. Event      — key story moments (finding leash, catching Daisy)
##
## On death or capture, trigger_respawn() rolls back GameState,
## InventoryManager, and MissionManager to the last snapshot,
## then teleports the player back to the checkpoint position.
## Tokens and NFTs collected AFTER the checkpoint are lost.
##
## Usage from any script:
##   CheckpointManager.save_checkpoint(player.global_position)
##   CheckpointManager.trigger_respawn()
## =============================================================
extends Node

# ─────────────────────────────────────────────────────────────
# SIGNALS
# ─────────────────────────────────────────────────────────────
signal checkpoint_saved(position: Vector2)
signal respawn_triggered()

# ─────────────────────────────────────────────────────────────
# SETTINGS
# ─────────────────────────────────────────────────────────────
const TIMED_INTERVAL: float = 180.0  # Seconds between automatic checkpoints

# ─────────────────────────────────────────────────────────────
# CHECKPOINT SNAPSHOT (everything needed to roll back)
# ─────────────────────────────────────────────────────────────
var _checkpoint_position: Vector2 = Vector2.ZERO
var _checkpoint_scene: String = ""
var _checkpoint_game_state: Dictionary = {}
var _checkpoint_inventory: Dictionary = {}
var _checkpoint_missions: Dictionary = {}

var _has_checkpoint: bool = false
var _timer: float = 0.0


# ─────────────────────────────────────────────────────────────
# READY
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	print("[CheckpointManager] Checkpoint system ready.")


# ─────────────────────────────────────────────────────────────
# PROCESS — timed auto-checkpoint
# ─────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if not GameState.has_active_game:
		return
	_timer += delta
	if _timer >= TIMED_INTERVAL:
		_timer = 0.0
		var player := get_tree().get_first_node_in_group("player")
		if player:
			save_checkpoint(player.global_position)
			_show_checkpoint_notification("⏱ Auto-checkpoint saved!")


# ─────────────────────────────────────────────────────────────
# SAVE A CHECKPOINT
# Snapshots GameState, inventory, and missions at this moment.
# Call from CheckpointZone nodes, item pickups, or story events.
# ─────────────────────────────────────────────────────────────
func save_checkpoint(world_position: Vector2) -> void:
	_checkpoint_position   = world_position
	_checkpoint_scene      = GameState.current_scene
	_checkpoint_game_state = GameState.to_dict()
	_checkpoint_inventory  = InventoryManager.to_dict()
	_checkpoint_missions   = MissionManager.to_dict()
	_has_checkpoint = true
	_timer = 0.0  # Reset timed interval after any save

	emit_signal("checkpoint_saved", world_position)
	print("[CheckpointManager] ✅ Checkpoint saved at: ", world_position)


# ─────────────────────────────────────────────────────────────
# TRIGGER RESPAWN
# Restores all managers from the last snapshot, then loads
# the checkpoint scene with the player at the saved position.
# ─────────────────────────────────────────────────────────────
func trigger_respawn() -> void:
	print("[CheckpointManager] 💀 Respawning at checkpoint...")

	if not _has_checkpoint:
		# No checkpoint taken yet — just reload the current scene from the start
		_do_scene_load(GameState.current_scene, Vector2.ZERO)
		return

	# Roll back all game data (tokens/NFTs gained since checkpoint are lost)
	GameState.from_dict(_checkpoint_game_state)
	InventoryManager.from_dict(_checkpoint_inventory)
	MissionManager.from_dict(_checkpoint_missions)

	# Put the player at the checkpoint position when the scene loads
	GameState.player_position = _checkpoint_position

	emit_signal("respawn_triggered")

	var target := _checkpoint_scene
	if target.is_empty():
		target = "res://scenes/levels/v1_start_area/StartArea.tscn"
	_do_scene_load(target, _checkpoint_position)


func _do_scene_load(scene_path: String, _at_position: Vector2) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(scene_path)


# ─────────────────────────────────────────────────────────────
# QUERY
# ─────────────────────────────────────────────────────────────
func has_checkpoint() -> bool:
	return _has_checkpoint


# ─────────────────────────────────────────────────────────────
# INTERNAL — show a brief notification via the HUD if one exists
# ─────────────────────────────────────────────────────────────
func _show_checkpoint_notification(message: String) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_notification"):
		hud.show_notification(message)
