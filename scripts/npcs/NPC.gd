## NPC.gd
## =============================================================
## Base class for all NPCs (Non-Player Characters) in the game.
## Every NPC inherits from this and adds their own behaviour.
##
## Features:
##   - Name tag above the NPC
##   - Interact zone (so player knows they can talk)
##   - Basic dialogue trigger
##   - Can be set as a mission giver
##
## Node type: StaticBody2D
## =============================================================
extends StaticBody2D

# ─────────────────────────────────────────────────────────────
# SIGNALS
# ─────────────────────────────────────────────────────────────
signal dialogue_started(npc_name: String, lines: Array)
signal dialogue_ended()

# ─────────────────────────────────────────────────────────────
# NPC PROPERTIES — set these in the Inspector or in child scripts
# ─────────────────────────────────────────────────────────────
@export var npc_name: String = "NPC"
@export var npc_id: String = ""          # Matches MissionDatabase npc_id
@export var default_dialogue: Array = [] # What the NPC says when not on a mission
@export var sprite_color: Color = Color.WHITE  # Tint for placeholder colored sprites

const CharacterShadowScene := preload("res://scenes/effects/CharacterShadow.tscn")

# ─────────────────────────────────────────────────────────────
# NODE REFERENCES
# ─────────────────────────────────────────────────────────────
@onready var name_label: Label = $NameLabel
@onready var sprite: Sprite2D = $Sprite2D
@onready var interact_area: Area2D = $InteractArea

# ─────────────────────────────────────────────────────────────
# INTERNAL STATE
# ─────────────────────────────────────────────────────────────
var _is_talking: bool = false


# ─────────────────────────────────────────────────────────────
# CALLED WHEN THE SCENE IS READY
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	# Show the NPC's name above them
	if name_label:
		name_label.text = npc_name

	# Apply color tint to sprite (for placeholder art)
	if sprite:
		sprite.modulate = sprite_color

	# Add to groups so the player's interact zone can find us
	add_to_group("interactable")
	add_to_group("npc")

	if not get_node_or_null("CharacterShadow"):
		var shadow := CharacterShadowScene.instantiate()
		add_child(shadow)
		move_child(shadow, 0)

	print("[NPC] %s is ready." % npc_name)


# ─────────────────────────────────────────────────────────────
# CALLED BY THE PLAYER WHEN THEY PRESS E NEAR THIS NPC
# Child NPCs should override this to add mission logic.
# ─────────────────────────────────────────────────────────────
func on_player_interact(_player: Node) -> void:
	if _is_talking:
		return  # Prevent double-interaction

	_is_talking = true

	# Get the appropriate dialogue to show
	var dialogue_lines := _get_dialogue_lines()

	if dialogue_lines.is_empty():
		dialogue_lines = ["[%s] Hi there!" % npc_name]

	# Tell the dialogue system to show these lines
	emit_signal("dialogue_started", npc_name, dialogue_lines)

	# Find the dialogue box in the scene and show it
	var dialogue_box := _find_dialogue_box()
	if dialogue_box:
		dialogue_box.show_dialogue(npc_name, dialogue_lines, self)
	else:
		# Fallback: print to console if no dialogue box found
		push_warning("[NPC] No dialogue box found in scene!")
		_is_talking = false


# ─────────────────────────────────────────────────────────────
# CALLED WHEN DIALOGUE ENDS
# ─────────────────────────────────────────────────────────────
func on_dialogue_finished() -> void:
	_is_talking = false
	emit_signal("dialogue_ended")


# ─────────────────────────────────────────────────────────────
# OVERRIDE IN CHILD CLASSES to return mission-specific dialogue
# ─────────────────────────────────────────────────────────────
func _get_dialogue_lines() -> Array:
	return default_dialogue


# ─────────────────────────────────────────────────────────────
# FIND THE DIALOGUE BOX IN THE CURRENT SCENE
# ─────────────────────────────────────────────────────────────
func _find_dialogue_box() -> Node:
	# Look for DialogueBox in the HUD group
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		return hud.get_node_or_null("DialogueBox")
	return null
