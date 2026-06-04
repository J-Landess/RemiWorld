## SchoolInteriorManager.gd
## =============================================================
## Manages the School Library interior level.
##
## What happens here:
##   • Ms. Huffy sleeps at her desk — wake her and she chases you.
##     Tiptoe (Shift) past her to reach the back locker.
##   • Daisy's Leash is locked in a locker at the back.
##     Press [E] near the locker to grab it.
##   • The exit door at the bottom sends the player back to the
##     Start Area.
##   • A checkpoint is saved automatically when the player enters.
##
## Attached to: scenes/levels/v1_school_interior/SchoolInterior.tscn
## =============================================================
extends Node2D

# ─────────────────────────────────────────────────────────────
# SCENE PRELOADS
# ─────────────────────────────────────────────────────────────
const PlayerScene  := preload("res://scenes/player/Player.tscn")
const MsHuffyScene := preload("res://scenes/npcs/MsHuffy.tscn")
const HUDScene     := preload("res://scenes/ui/HUD.tscn")

# ─────────────────────────────────────────────────────────────
# INTERNAL REFERENCES
# ─────────────────────────────────────────────────────────────
var _player: Node = null
var _hud: Node    = null
var _near_locker: bool = false
var _near_exit: bool   = false
var _locker_label: Label = null   # The lock emoji on the locker
var _exit_hint_label: Label = null


# ─────────────────────────────────────────────────────────────
# READY
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	print("[SchoolInterior] Entering the school library...")
	GameState.current_scene = "res://scenes/levels/v1_school_interior/SchoolInterior.tscn"

	_spawn_hud()
	_spawn_player()
	_spawn_ms_huffy()
	_setup_locker()
	_setup_exit()
	AudioManager.play_music("school")

	# Checkpoint: entering the school is itself a checkpoint moment
	if _player:
		CheckpointManager.save_checkpoint(_player.global_position)

	print("[SchoolInterior] School library ready.")


# ─────────────────────────────────────────────────────────────
# PROCESS — handle E-key interactions for locker and exit door
# ─────────────────────────────────────────────────────────────
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		if _near_locker and not GameState.has_leash:
			_pickup_leash()
		elif _near_exit:
			_exit_school()


# ─────────────────────────────────────────────────────────────
# SPAWN HUD
# ─────────────────────────────────────────────────────────────
func _spawn_hud() -> void:
	_hud = HUDScene.instantiate()
	add_child(_hud)
	print("[SchoolInterior] HUD spawned.")


# ─────────────────────────────────────────────────────────────
# SPAWN PLAYER
# ─────────────────────────────────────────────────────────────
func _spawn_player() -> void:
	_player = PlayerScene.instantiate()
	add_child(_player)
	var spawn := get_node_or_null("PlayerSpawn")
	if spawn:
		_player.global_position = spawn.global_position
	else:
		_player.global_position = Vector2(0, 230)
	print("[SchoolInterior] Player spawned at: ", _player.global_position)


# ─────────────────────────────────────────────────────────────
# SPAWN MS. HUFFY (only if leash not yet collected)
# ─────────────────────────────────────────────────────────────
func _spawn_ms_huffy() -> void:
	if GameState.daisy_captured or GameState.has_leash:
		print("[SchoolInterior] Leash/Daisy already sorted — Ms. Huffy is off duty.")
		return

	var spawn_marker := get_node_or_null("NPCSpawns/MsHuffySpawn")
	if not spawn_marker:
		return

	var huffy := MsHuffyScene.instantiate()
	huffy.global_position = spawn_marker.global_position
	get_node("NPCSpawns").add_child(huffy)
	print("[SchoolInterior] Ms. Huffy spawned at: ", huffy.global_position)


# ─────────────────────────────────────────────────────────────
# SETUP LOCKER PICKUP ZONE
# ─────────────────────────────────────────────────────────────
func _setup_locker() -> void:
	var locker_zone := get_node_or_null("Objects/LockerZone")
	if locker_zone == null:
		return

	# Hide it if already picked up
	if GameState.has_leash:
		locker_zone.visible = false
		return

	locker_zone.body_entered.connect(_on_locker_entered)
	locker_zone.body_exited.connect(_on_locker_exited)

	# Find the interaction hint label inside the zone
	_locker_label = locker_zone.get_node_or_null("HintLabel")


func _on_locker_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_near_locker = true
		if _locker_label:
			_locker_label.visible = true


func _on_locker_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_near_locker = false
		if _locker_label:
			_locker_label.visible = false


# ─────────────────────────────────────────────────────────────
# PICK UP THE LEASH
# ─────────────────────────────────────────────────────────────
func _pickup_leash() -> void:
	var leash_data := ItemDatabase.get_item("daisys_leash")
	if not leash_data.is_empty():
		InventoryManager.add_item(leash_data)

	GameState.has_leash = true

	# Hide the locker zone
	var locker_zone := get_node_or_null("Objects/LockerZone")
	if locker_zone:
		locker_zone.visible = false
	_near_locker = false

	if _hud and _hud.has_method("show_notification"):
		_hud.show_notification("🦮 Found Daisy's Leash! Head outside and find her in the flowers!")

	# This is a story beat — save a checkpoint
	if _player:
		CheckpointManager.save_checkpoint(_player.global_position)

	print("[SchoolInterior] 🦮 Leash collected!")


# ─────────────────────────────────────────────────────────────
# SETUP EXIT DOOR
# ─────────────────────────────────────────────────────────────
func _setup_exit() -> void:
	var exit_zone := get_node_or_null("ExitZone")
	if exit_zone == null:
		return

	exit_zone.body_entered.connect(_on_exit_entered)
	exit_zone.body_exited.connect(_on_exit_exited)

	_exit_hint_label = exit_zone.get_node_or_null("HintLabel")


func _on_exit_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_near_exit = true
		if _exit_hint_label:
			_exit_hint_label.visible = true


func _on_exit_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_near_exit = false
		if _exit_hint_label:
			_exit_hint_label.visible = false


# ─────────────────────────────────────────────────────────────
# EXIT TO START AREA
# ─────────────────────────────────────────────────────────────
func _exit_school() -> void:
	if _player:
		# Place the player near the school door on return
		GameState.player_position = Vector2(-200, -220)
	get_tree().change_scene_to_file("res://scenes/levels/v1_start_area/StartArea.tscn")


# ─────────────────────────────────────────────────────────────
# AUTO-SAVE ON CLOSE
# ─────────────────────────────────────────────────────────────
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		if _player:
			GameState.player_position = _player.global_position
		SaveManager.save_game()
