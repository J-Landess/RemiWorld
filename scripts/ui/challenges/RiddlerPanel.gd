## RiddlerPanel.gd
## =============================================================
## The Riddler's 10-question timed animal trivia challenge.
## Player must score 8/10 to pass. Each question has 15 seconds.
## The Riddler inserts trick commentary to try to fool the player.
##
## Used by: RiddlerNPC → hud.show_challenge("RiddlerPanel", ...)
## =============================================================
extends Control

# ── Question bank (12 questions, 10 picked randomly each game) ───────────────
const ALL_QUESTIONS: Array[Dictionary] = [
	{
		"q": "What is the largest animal in the ocean?",
		"choices": ["Blue Whale", "Whale Shark", "Giant Squid", "Great White Shark"],
		"correct": 0,
		"trick": "Psst… a Giant Squid is ENORMOUS. Surely bigger than a whale?",
	},
	{
		"q": "How many legs does a spider have?",
		"choices": ["8", "6", "10", "4"],
		"correct": 0,
		"trick": "Wait… count again. Are you SURE it isn't 6?",
	},
	{
		"q": "What do dolphins mainly eat?",
		"choices": ["Fish and squid", "Seaweed", "Plankton only", "Crabs"],
		"correct": 0,
		"trick": "I heard dolphins love a good seaweed salad...",
	},
	{
		"q": "What color are flamingos when they first hatch?",
		"choices": ["White and grey", "Pink", "Red", "Orange"],
		"correct": 0,
		"trick": "Obviously pink! They're FLAMIngos. Pink is their whole brand!",
	},
	{
		"q": "How many hearts does an octopus have?",
		"choices": ["3", "1", "2", "4"],
		"correct": 0,
		"trick": "One heart, just like you and me — obviously!",
	},
	{
		"q": "What is the fastest land animal?",
		"choices": ["Cheetah", "Lion", "Horse", "Greyhound dog"],
		"correct": 0,
		"trick": "Horses are so big and powerful — surely fastest!",
	},
	{
		"q": "A group of fish swimming together is called a…",
		"choices": ["School", "Herd", "Pack", "Flock"],
		"correct": 0,
		"trick": "A flock! Like birds — they travel in groups too, same thing!",
	},
	{
		"q": "How many legs does an insect have?",
		"choices": ["6", "8", "4", "10"],
		"correct": 0,
		"trick": "8 legs — that's why they look like spiders, isn't it?",
	},
	{
		"q": "What is a baby cat called?",
		"choices": ["Kitten", "Cub", "Pup", "Foal"],
		"correct": 0,
		"trick": "A cub! Just like baby bears and lions — ALL baby animals are cubs!",
	},
	{
		"q": "Where do polar bears live?",
		"choices": ["Arctic (North Pole)", "Antarctica (South Pole)", "Africa", "Amazon jungle"],
		"correct": 0,
		"trick": "Antarctica! Penguins and polar bears are neighbours — everyone knows THAT!",
	},
	{
		"q": "What do bears eat?",
		"choices": ["Plants, berries, fish, and honey", "Only meat", "Only fish", "Leaves only"],
		"correct": 0,
		"trick": "Only meat — bears are fierce predators who eat NOTHING but flesh!",
	},
	{
		"q": "Which animal has black and white stripes and lives in Africa?",
		"choices": ["Zebra", "Tiger", "Skunk", "Badger"],
		"correct": 0,
		"trick": "Tigers! Orange and black stripes — close enough to black and white!",
	},
]

const QUESTION_TIME: float = 15.0
const TOTAL_QUESTIONS: int = 10
const REQUIRED_CORRECT: int = 8

# ── Node refs ─────────────────────────────────────────────────────────────────
@onready var title_label: Label         = $Backdrop/Panel/VBox/TitleLabel
@onready var trick_label: Label         = $Backdrop/Panel/VBox/TrickLabel
@onready var question_label: Label      = $Backdrop/Panel/VBox/QuestionLabel
@onready var timer_bar: ProgressBar     = $Backdrop/Panel/VBox/TimerBar
@onready var choices_box: VBoxContainer = $Backdrop/Panel/VBox/ChoicesBox
@onready var feedback_label: Label      = $Backdrop/Panel/VBox/FeedbackLabel
@onready var score_label: Label         = $Backdrop/Panel/VBox/ScoreLabel
@onready var close_button: Button       = $Backdrop/Panel/VBox/CloseButton

# ── State ─────────────────────────────────────────────────────────────────────
var _mission_data: Dictionary = {}
var _caller: Node = null
var _questions: Array[Dictionary] = []
var _current_q: int = 0
var _correct_count: int = 0
var _time_left: float = 0.0
var _answered: bool = false
var _done: bool = false


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	if close_button:
		close_button.pressed.connect(_on_give_up)


func show_challenge(mission_data: Dictionary, caller: Node) -> void:
	_mission_data = mission_data
	_caller = caller
	_correct_count = 0
	_current_q = 0
	_done = false

	# Shuffle and pick TOTAL_QUESTIONS questions
	var pool := ALL_QUESTIONS.duplicate()
	pool.shuffle()
	_questions.clear()
	for i in min(TOTAL_QUESTIONS, pool.size()):
		_questions.append(pool[i])

	if title_label:
		var animal: String = mission_data.get("animal_emoji", "🐾")
		title_label.text = "🎭 The Riddler's Challenge  %s" % animal
	if close_button:
		close_button.text = "Give Up"

	visible = true
	_ask_question()


func _process(delta: float) -> void:
	if not visible or _done or _answered:
		return
	_time_left -= delta
	if timer_bar:
		timer_bar.value = (_time_left / QUESTION_TIME) * 100.0
	if _time_left <= 0.0:
		_time_expired()


func _ask_question() -> void:
	if _current_q >= _questions.size():
		_finish()
		return

	_answered = false
	_time_left = QUESTION_TIME

	var q := _questions[_current_q]
	if question_label:
		question_label.text = "Q%d: %s" % [_current_q + 1, q.get("q", "")]
	if trick_label:
		trick_label.text = "💬 The Riddler: \"%s\"" % q.get("trick", "")
		trick_label.modulate = Color(1.0, 0.75, 0.25, 1)
	if feedback_label:
		feedback_label.text = ""
	if score_label:
		score_label.text = "Score: %d / %d  |  Q%d of %d" % [_correct_count, REQUIRED_CORRECT, _current_q + 1, _questions.size()]
	if timer_bar:
		timer_bar.value = 100.0

	_rebuild_choices(q.get("choices", []))


func _rebuild_choices(choices: Array) -> void:
	if not choices_box:
		return
	for child in choices_box.get_children():
		child.queue_free()
	for i in choices.size():
		var btn := Button.new()
		btn.text = choices[i]
		btn.custom_minimum_size = Vector2(0, 46)
		btn.add_theme_font_size_override("font_size", 17)
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(_on_choice.bind(i))
		choices_box.add_child(btn)


func _on_choice(idx: int) -> void:
	if _answered:
		return
	_answered = true
	_disable_choices()

	var correct_idx: int = _questions[_current_q].get("correct", 0)
	var correct: bool = (idx == correct_idx)

	if correct:
		_correct_count += 1
		if feedback_label:
			feedback_label.text = "✅ Correct!"
			feedback_label.modulate = Color(0.35, 1.0, 0.45)
		AudioManager.play_sfx("correct")
	else:
		var right_answer: String = _questions[_current_q].get("choices", ["?"])[correct_idx]
		if feedback_label:
			feedback_label.text = "❌ Wrong! The answer was: %s" % right_answer
			feedback_label.modulate = Color(1.0, 0.45, 0.45)
		AudioManager.play_sfx("wrong")

	if score_label:
		score_label.text = "Score: %d / %d  |  Q%d of %d" % [_correct_count, REQUIRED_CORRECT, _current_q + 1, _questions.size()]

	await get_tree().create_timer(1.6).timeout
	_current_q += 1
	_ask_question()


func _time_expired() -> void:
	_answered = true
	_disable_choices()
	if feedback_label:
		feedback_label.text = "⏰ Time's up! The Riddler laughs at your hesitation!"
		feedback_label.modulate = Color(1.0, 0.65, 0.20)
	AudioManager.play_sfx("wrong")
	await get_tree().create_timer(1.6).timeout
	_current_q += 1
	_ask_question()


func _disable_choices() -> void:
	if not choices_box:
		return
	for child in choices_box.get_children():
		if child is Button:
			child.disabled = true


func _finish() -> void:
	_done = true
	var success := _correct_count >= REQUIRED_CORRECT
	visible = false
	var hud := get_parent()
	if hud and hud.has_method("close_all_panels"):
		hud.close_all_panels()
	if _caller and _caller.has_method("on_challenge_finished"):
		_caller.on_challenge_finished(success)


func _on_give_up() -> void:
	AudioManager.play_sfx("click")
	_done = true
	_finish()
