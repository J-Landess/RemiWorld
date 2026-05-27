## ShopkeeperRose.gd
## =============================================================
## Shopkeeper Rose sells avatar items in exchange for VIBE tokens.
## Talking to Rose opens the Storefront UI.
##
## Inherits from NPC.gd
## =============================================================
extends "res://scripts/npcs/NPC.gd"


# ─────────────────────────────────────────────────────────────
# SETUP
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	npc_name = "Shopkeeper Rose"
	npc_id = "shopkeeper_rose"
	sprite_color = Color(1.0, 0.6, 0.8)  # Pink placeholder color

	default_dialogue = [
		"[Shopkeeper Rose] Welcome to my shop! 🌸",
		"[Shopkeeper Rose] I have lovely items for your avatar!",
		"[Shopkeeper Rose] Spend your VIBE tokens to look amazing!",
	]

	super._ready()


# ─────────────────────────────────────────────────────────────
# OVERRIDE: Opens the store instead of just showing dialogue
# ─────────────────────────────────────────────────────────────
func on_player_interact(player: Node) -> void:
	if _is_talking:
		return

	_is_talking = true

	# Show greeting dialogue first, then open the store
	var dialogue_box := _find_dialogue_box()
	if dialogue_box:
		dialogue_box.show_dialogue(npc_name, default_dialogue, self, false, true)
		# The dialogue box will call back to open the store via on_dialogue_finished
	else:
		_open_store()


func on_dialogue_finished() -> void:
	_is_talking = false
	emit_signal("dialogue_ended")
	_open_store()


func _open_store() -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("open_store"):
		hud.open_store()
