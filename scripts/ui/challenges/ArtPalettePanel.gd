## ArtPalettePanel.gd
## =============================================================
## "Rainbow Maker" mini-game.
##
## A target color is shown alongside a hint name (e.g. "sunset
## orange"). The player slides three R/G/B sliders to match it.
##
## Win condition: 2 out of 3 rounds within tolerance.
## =============================================================
extends Control

# ─────────────────────────────────────────────────────────────
# COLOR LIBRARY — labelled targets shown to the player.
# ─────────────────────────────────────────────────────────────
const TARGETS: Array = [
	["Sunset orange", Color(0.98, 0.55, 0.25)],
	["Ocean blue",    Color(0.20, 0.55, 0.85)],
	["Forest green",  Color(0.25, 0.55, 0.30)],
	["Bubble-gum pink", Color(0.98, 0.55, 0.78)],
	["Lemon yellow",  Color(0.98, 0.88, 0.30)],
	["Royal purple",  Color(0.50, 0.30, 0.75)],
	["Cherry red",    Color(0.90, 0.20, 0.25)],
	["Sky blue",      Color(0.55, 0.78, 0.95)],
	["Mint",          Color(0.55, 0.92, 0.78)],
	["Lavender",      Color(0.78, 0.70, 0.95)],
]

# ─────────────────────────────────────────────────────────────
# NODE REFERENCES
# ─────────────────────────────────────────────────────────────
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var prompt_label: Label = $Panel/VBoxContainer/PromptLabel
@onready var swatches_row: HBoxContainer = $Panel/VBoxContainer/SwatchesRow
@onready var target_swatch: ColorRect = $Panel/VBoxContainer/SwatchesRow/TargetSwatch
@onready var your_swatch: ColorRect = $Panel/VBoxContainer/SwatchesRow/YourSwatch
@onready var r_slider: HSlider = $Panel/VBoxContainer/SlidersGrid/RSlider
@onready var g_slider: HSlider = $Panel/VBoxContainer/SlidersGrid/GSlider
@onready var b_slider: HSlider = $Panel/VBoxContainer/SlidersGrid/BSlider
@onready var done_button: Button = $Panel/VBoxContainer/DoneButton
@onready var feedback_label: Label = $Panel/VBoxContainer/FeedbackLabel
@onready var round_label: Label = $Panel/VBoxContainer/RoundLabel
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton

# ─────────────────────────────────────────────────────────────
# STATE
# ─────────────────────────────────────────────────────────────
var _mission_data: Dictionary = {}
var _caller: Node = null
var _rounds: int = 3
var _required_correct: int = 2
var _tolerance: float = 0.12
var _current_round: int = 0
var _correct_count: int = 0
var _target_color: Color = Color.WHITE
var _answered_this_round: bool = false


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	for s in [r_slider, g_slider, b_slider]:
		if s:
			s.min_value = 0.0
			s.max_value = 1.0
			s.step = 0.01
			s.value_changed.connect(_on_slider_changed)
	if done_button:
		done_button.pressed.connect(_on_done_pressed)
	if close_button:
		close_button.pressed.connect(_on_close_pressed)


# ─────────────────────────────────────────────────────────────
# ENTRY POINT
# ─────────────────────────────────────────────────────────────
func show_challenge(mission_data: Dictionary, caller: Node) -> void:
	_mission_data = mission_data
	_caller = caller

	var cfg: Dictionary = mission_data.get("challenge", {})
	_rounds = int(cfg.get("rounds", 3))
	_required_correct = int(cfg.get("required_correct", 2))
	_tolerance = float(cfg.get("tolerance", 0.12))
	_current_round = 0
	_correct_count = 0

	if title_label:
		title_label.text = "🎨  %s" % mission_data.get("title", "Rainbow Maker")
	if close_button:
		close_button.text = "Give Up"

	visible = true
	_start_round()


# ─────────────────────────────────────────────────────────────
# ROUND MANAGEMENT
# ─────────────────────────────────────────────────────────────
func _start_round() -> void:
	_answered_this_round = false
	_current_round += 1

	var pick: Array = TARGETS[randi() % TARGETS.size()]
	var name: String = pick[0]
	_target_color = pick[1]

	if target_swatch:
		target_swatch.color = _target_color

	# Reset sliders to mid-grey so the player has to actually mix
	if r_slider:
		r_slider.value = 0.5
	if g_slider:
		g_slider.value = 0.5
	if b_slider:
		b_slider.value = 0.5

	_refresh_your_swatch()

	if prompt_label:
		prompt_label.text = 'Mix "%s" — slide R, G, and B until the swatches match!' % name
		prompt_label.modulate = Color(1, 1, 1, 1)
	if feedback_label:
		feedback_label.text = ""
	if done_button:
		done_button.text = "Done!"
		done_button.disabled = false
	if round_label:
		round_label.text = "Round %d / %d   ·   Matches so far: %d" % [_current_round, _rounds, _correct_count]


func _current_color() -> Color:
	return Color(r_slider.value, g_slider.value, b_slider.value, 1.0)


func _refresh_your_swatch() -> void:
	if your_swatch:
		your_swatch.color = _current_color()


func _on_slider_changed(_v: float) -> void:
	if _answered_this_round:
		return
	AudioManager.play_sfx("slider_tick", 0.1)
	_refresh_your_swatch()


# ─────────────────────────────────────────────────────────────
# CHECK MATCH
# ─────────────────────────────────────────────────────────────
func _on_done_pressed() -> void:
	if _answered_this_round:
		return
	_answered_this_round = true
	AudioManager.play_sfx("paint_brush")

	var c: Color = _current_color()
	var dr: float = abs(c.r - _target_color.r)
	var dg: float = abs(c.g - _target_color.g)
	var db: float = abs(c.b - _target_color.b)
	var max_diff: float = max(dr, max(dg, db))
	var matched: bool = max_diff <= _tolerance

	AudioManager.play_sfx("correct" if matched else "wrong")

	if matched:
		_correct_count += 1
		if feedback_label:
			feedback_label.text = "✨  Beautiful match!"
			feedback_label.modulate = Color(0.35, 1.0, 0.45)
	else:
		if feedback_label:
			feedback_label.text = "🎨  Close — biggest channel was off by %d%%." % int(round(max_diff * 100.0))
			feedback_label.modulate = Color(1.0, 0.5, 0.5)

	if done_button:
		done_button.disabled = true
	if round_label:
		round_label.text = "Round %d / %d   ·   Matches so far: %d" % [_current_round, _rounds, _correct_count]

	await get_tree().create_timer(1.4).timeout

	if _current_round >= _rounds:
		_finish_challenge()
	else:
		_start_round()


# ─────────────────────────────────────────────────────────────
# FINISH
# ─────────────────────────────────────────────────────────────
func _finish_challenge() -> void:
	var success := _correct_count >= _required_correct
	visible = false
	if _caller and _caller.has_method("on_challenge_finished"):
		_caller.on_challenge_finished(success)
	var hud := get_parent()
	if hud and hud.has_method("close_all_panels"):
		hud.close_all_panels()


func _on_close_pressed() -> void:
	AudioManager.play_sfx("click")
	_finish_challenge()
