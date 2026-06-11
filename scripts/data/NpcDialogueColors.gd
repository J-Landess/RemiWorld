## NpcDialogueColors.gd — bright per-NPC dialogue accent colors.
class_name NpcDialogueColors
extends RefCounted

const COLORS: Dictionary = {
	"password_factory": Color(0.0, 0.9, 1.0),
	"coding_bot": Color(0.0, 0.9, 1.0),
	"shopkeeper_rose": Color(1.0, 0.35, 0.65),
	"chess_tutor": Color(0.65, 0.35, 0.95),
	"coach_kick": Color(0.45, 1.0, 0.35),
	"artist_pip": Color(1.0, 0.6, 0.15),
	"pit_boss_mara": Color(0.95, 0.25, 0.3),
	"course_coach": Color(0.35, 0.75, 1.0),
	"journey_guide": Color(1.0, 0.85, 0.2),
	"zia_witch": Color(0.75, 0.4, 1.0),
	"groomer_greta": Color(0.45, 0.95, 0.75),
	"daisy_doodles": Color(1.0, 0.55, 0.45),
}


static func get_color(npc_id: String, _speaker_name: String = "") -> Color:
	if COLORS.has(npc_id):
		return COLORS[npc_id]
	return Color(1.0, 0.9, 0.3)


static func to_bbcode(color: Color) -> String:
	return "#%02x%02x%02x" % [int(color.r * 255.0), int(color.g * 255.0), int(color.b * 255.0)]
