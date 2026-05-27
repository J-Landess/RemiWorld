## RewardPopup.gd
## =============================================================
## A popup that briefly shows when the player earns a reward.
## Appears with an animation, shows what was earned, then fades out.
##
## Attached to: scenes/ui/HUD.tscn → RewardPopup node
## Node type: Control
## =============================================================
extends Control

# ─────────────────────────────────────────────────────────────
# NODE REFERENCES
# ─────────────────────────────────────────────────────────────
@onready var title_label: Label   = $Panel/VBoxContainer/TitleLabel
@onready var reward_label: Label  = $Panel/VBoxContainer/RewardLabel
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton


# ─────────────────────────────────────────────────────────────
# READY
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	visible = false
	if close_button:
		close_button.pressed.connect(func(): visible = false)


# ─────────────────────────────────────────────────────────────
# SHOW REWARD
# Displays the reward popup with animation.
# ─────────────────────────────────────────────────────────────
func show_reward(reward_summary: Dictionary) -> void:
	if not title_label or not reward_label:
		return

	title_label.text = "🎉 Reward Earned!"

	# Build reward text
	var lines: Array = []
	if reward_summary.has("tokens"):
		lines.append("⭐ +%d VIBE Tokens" % reward_summary["tokens"])
	if reward_summary.has("xp"):
		lines.append("✨ +%d XP" % reward_summary["xp"])
	if reward_summary.has("nft"):
		lines.append("🌟 NFT: %s" % reward_summary["nft"])
	if reward_summary.has("item"):
		lines.append("🎁 Item: %s" % reward_summary["item"])
	if reward_summary.has("items"):
		for item_name in reward_summary["items"]:
			lines.append("🎁 Item: %s" % item_name)

	reward_label.text = "\n".join(lines)

	# Pop-in animation
	modulate.a = 0.0
	scale = Vector2(0.5, 0.5)
	visible = true

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	tween.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BOUNCE)

	# Auto-close after a few seconds (if close button not pressed)
	await get_tree().create_timer(4.0).timeout
	if visible:
		var fade := create_tween()
		fade.tween_property(self, "modulate:a", 0.0, 0.5)
		await fade.finished
		visible = false
