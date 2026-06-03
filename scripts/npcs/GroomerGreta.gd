## GroomerGreta.gd
## =============================================================
## Groomer NPC — opens the GroomerPanel service.
## No formal mission; it's always available as a shop.
## =============================================================
extends "res://scripts/npcs/NPC.gd"


func _ready() -> void:
	npc_name     = "Groomer Greta"
	npc_id       = "groomer_greta"
	sprite_color = Color(0.72, 0.42, 0.72)
	super._ready()


func on_player_interact(_player: Node) -> void:
	if _is_talking:
		return
	_is_talking = true

	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_groomer"):
		hud.show_groomer(self)
	else:
		_is_talking = false


func on_groomer_closed() -> void:
	_is_talking = false


func on_dialogue_finished() -> void:
	_is_talking = false
	emit_signal("dialogue_ended")
