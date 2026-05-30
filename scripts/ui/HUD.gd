## HUD.gd
## =============================================================
## The HUD (Heads-Up Display) is the UI shown while playing the game.
## It shows: token balance, XP bar, player name, and contains
## the dialogue box, backpack, store, and avatar closet as children.
##
## The HUD is always visible during gameplay and acts as the
# central controller for all in-game UI panels.
##
## Attached to: scenes/ui/HUD.tscn
## Node type: CanvasLayer
## =============================================================
extends CanvasLayer

# ─────────────────────────────────────────────────────────────
# NODE REFERENCES
# ─────────────────────────────────────────────────────────────
@onready var token_label: Label   = $TopBar/TokenLabel
@onready var xp_bar: ProgressBar  = $TopBar/XPBar
@onready var level_label: Label   = $TopBar/LevelLabel
@onready var player_name_label: Label = $TopBar/PlayerNameLabel

# Sub-panels (loaded as children)
@onready var dialogue_box: Control  = $DialogueBox
@onready var backpack_ui: Control   = $BackpackUI
@onready var store_ui: Control      = $StoreUI
@onready var avatar_closet: Control = $AvatarCloset
@onready var reward_popup: Control  = $RewardPopup
@onready var puzzle_panel: Control  = $PuzzlePanel
@onready var pause_menu: Control    = $PauseMenu


# ─────────────────────────────────────────────────────────────
# CALLED WHEN HUD LOADS
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	add_to_group("hud")

	# ── CRITICAL: make all HUD nodes work even when the game tree is paused.
	# When get_tree().paused = true, nodes default to PROCESS_MODE_INHERIT and
	# stop responding to input. Setting ALWAYS on the HUD and all children
	# ensures every button click / keyboard press still registers.
	_set_process_mode_always(self)

	# Connect to GameState signals so HUD updates automatically
	GameState.tokens_changed.connect(_on_tokens_changed)
	GameState.xp_changed.connect(_on_xp_changed)
	RewardManager.reward_granted.connect(_on_reward_granted)

	# Close all panels on start
	_hide_all_panels()

	# Initial display update
	_refresh_hud()

	print("[HUD] HUD ready.")


func _set_process_mode_always(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_ALWAYS
	for child in node.get_children():
		_set_process_mode_always(child)


# ─────────────────────────────────────────────────────────────
# KEYBOARD INPUT — handle Esc for pause
# ─────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	# Guard against motion events — only key/button events carry action state.
	if not (event is InputEventKey or event is InputEventJoypadButton):
		return
	if event.is_action_pressed("pause") and not event.is_echo():
		_toggle_pause()


# ─────────────────────────────────────────────────────────────
# REFRESH HUD VALUES
# ─────────────────────────────────────────────────────────────
func _refresh_hud() -> void:
	if token_label:
		token_label.text = "⭐ %d VIBE" % GameState.vibe_tokens
	if level_label:
		level_label.text = "Lv.%d" % GameState.player_level
	if player_name_label:
		player_name_label.text = GameState.player_name
	if xp_bar:
		xp_bar.value = GameState.get_xp_progress() * 100.0


# ─────────────────────────────────────────────────────────────
# SIGNAL HANDLERS
# ─────────────────────────────────────────────────────────────
func _on_tokens_changed(new_amount: int) -> void:
	if token_label:
		token_label.text = "⭐ %d VIBE" % new_amount


func _on_xp_changed(_new_xp: int, new_level: int) -> void:
	if level_label:
		level_label.text = "Lv.%d" % new_level
	if xp_bar:
		xp_bar.value = GameState.get_xp_progress() * 100.0


func _on_reward_granted(reward_summary: Dictionary) -> void:
	# Show the reward popup
	if reward_popup and reward_popup.has_method("show_reward"):
		reward_popup.show_reward(reward_summary)


# ─────────────────────────────────────────────────────────────
# PANEL MANAGEMENT
# ─────────────────────────────────────────────────────────────
func _hide_all_panels() -> void:
	for panel in [dialogue_box, backpack_ui, store_ui, avatar_closet, reward_popup, puzzle_panel, pause_menu]:
		if panel:
			panel.visible = false


func toggle_backpack() -> void:
	if not backpack_ui:
		return
	var opening := not backpack_ui.visible
	_hide_all_panels()
	backpack_ui.visible = opening
	if opening and backpack_ui.has_method("refresh"):
		backpack_ui.refresh()
	_set_game_paused(opening)


func open_store() -> void:
	_hide_all_panels()
	if store_ui:
		store_ui.visible = true
		if store_ui.has_method("refresh"):
			store_ui.refresh()
	_set_game_paused(true)


func open_avatar_closet() -> void:
	_hide_all_panels()
	if avatar_closet:
		avatar_closet.visible = true
		if avatar_closet.has_method("refresh"):
			avatar_closet.refresh()
	_set_game_paused(true)


func close_all_panels() -> void:
	_hide_all_panels()
	_set_game_paused(false)


func show_puzzle(puzzle_data: Dictionary, caller: Node) -> void:
	if puzzle_panel and puzzle_panel.has_method("show_puzzle"):
		_hide_all_panels()
		puzzle_panel.visible = true
		puzzle_panel.show_puzzle(puzzle_data, caller)
		_set_game_paused(true)


func _toggle_pause() -> void:
	# If any panel is open, close it instead of pausing
	for panel in [backpack_ui, store_ui, avatar_closet, puzzle_panel]:
		if panel and panel.visible:
			close_all_panels()
			return

	# Toggle pause menu
	if pause_menu:
		pause_menu.visible = not pause_menu.visible
		_set_game_paused(pause_menu.visible)


func _set_game_paused(paused: bool) -> void:
	# Pause the physics/process of the game world (not the UI)
	get_tree().paused = paused
