## StartAreaManager.gd
## =============================================================
## Manages the Start Area level scene.
## Handles: spawning the player, loading NPCs, connecting the HUD,
## and saving position when the player exits.
##
## Attached to: scenes/levels/v1_start_area/StartArea.tscn (root node)
## =============================================================
extends Node2D

# ─────────────────────────────────────────────────────────────
# SCENE REFERENCES (preloaded for fast instantiation)
# ─────────────────────────────────────────────────────────────
const PlayerScene    := preload("res://scenes/player/Player.tscn")
const CodingBotScene := preload("res://scenes/npcs/CodingBot.tscn")
const RoseScene      := preload("res://scenes/npcs/ShopkeeperRose.tscn")
const HUDScene       := preload("res://scenes/ui/HUD.tscn")

# ─────────────────────────────────────────────────────────────
# INTERNAL REFERENCES
# ─────────────────────────────────────────────────────────────
var _player: Node = null
var _hud: Node = null


# ─────────────────────────────────────────────────────────────
# CALLED WHEN THE LEVEL LOADS
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	print("[StartArea] Loading Remi's Start Area...")
	GameState.current_scene = "res://scenes/levels/v1_start_area/StartArea.tscn"

	# Spawn the HUD (in-game UI)
	_spawn_hud()

	# Spawn the player at the correct position
	_spawn_player()

	# Spawn NPCs with their scripts
	_spawn_npcs()

	print("[StartArea] Start Area ready! Welcome, %s!" % GameState.player_name)


# ─────────────────────────────────────────────────────────────
# SPAWN THE HUD
# ─────────────────────────────────────────────────────────────
func _spawn_hud() -> void:
	_hud = HUDScene.instantiate()
	add_child(_hud)
	print("[StartArea] HUD spawned.")


# ─────────────────────────────────────────────────────────────
# SPAWN THE PLAYER
# ─────────────────────────────────────────────────────────────
func _spawn_player() -> void:
	_player = PlayerScene.instantiate()
	add_child(_player)

	# Find the spawn point marker in the scene
	var spawn_point := get_node_or_null("PlayerSpawn")
	if spawn_point:
		# If we have a saved position, restore it; otherwise use spawn point
		if GameState.player_position != Vector2.ZERO:
			_player.global_position = GameState.player_position
		else:
			_player.global_position = spawn_point.global_position
	else:
		# Fallback position if no spawn marker
		_player.global_position = Vector2(0, 100)

	print("[StartArea] Player spawned at: ", _player.global_position)


# ─────────────────────────────────────────────────────────────
# SPAWN NPCs WITH THEIR SCRIPTS
# ─────────────────────────────────────────────────────────────
func _spawn_npcs() -> void:
	# Coding Bot — positioned left of center
	var coding_bot_node := get_node_or_null("NPCs/CodingBot")
	if coding_bot_node:
		# Attach the CodingBot script to the existing node
		var bot_scene := CodingBotScene.instantiate()
		var bot_pos: Vector2 = coding_bot_node.global_position
		coding_bot_node.queue_free()  # Remove placeholder
		bot_scene.global_position = bot_pos
		get_node("NPCs").add_child(bot_scene)
		print("[StartArea] Coding Bot spawned at: ", bot_pos)

	# Shopkeeper Rose — positioned right of center
	var rose_node := get_node_or_null("NPCs/ShopkeeperRose")
	if rose_node:
		var rose_scene := RoseScene.instantiate()
		var rose_pos: Vector2 = rose_node.global_position
		rose_node.queue_free()
		rose_scene.global_position = rose_pos
		get_node("NPCs").add_child(rose_scene)
		print("[StartArea] Shopkeeper Rose spawned at: ", rose_pos)


# ─────────────────────────────────────────────────────────────
# AUTO-SAVE WHEN EXITING THE SCENE
# ─────────────────────────────────────────────────────────────
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		if _player:
			GameState.player_position = _player.global_position
		SaveManager.save_game()
