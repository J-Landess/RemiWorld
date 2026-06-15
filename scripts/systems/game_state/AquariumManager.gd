## AquariumManager.gd
## =============================================================
## Manages the City Aquarium level:
##   1. Entry — ticket booth with fee + optional VIP upgrade
##   2. Animal selection — player chooses which animal to rescue
##   3. Riddler quiz — RiddlerNPC handles the trivia challenge
##   4. Sneak phase — disguise animal then sneak past the guard
##   5. Success / failure — rewards + exit to Start Area
##
## Attached to: scenes/levels/v1_aquarium/Aquarium.tscn (root)
## =============================================================
extends Node2D

# ── Scene references ──────────────────────────────────────────────────────────
const PlayerScene   := preload("res://scenes/player/Player.tscn")
const HUDScene      := preload("res://scenes/ui/HUD.tscn")
const RiddlerScene  := preload("res://scenes/npcs/RiddlerNPC.tscn")

# ── Entry fee constants ───────────────────────────────────────────────────────
const ENTRY_FEE_REGULAR: int = 10
const ENTRY_FEE_VIP:     int = 25

# ── Internal state ────────────────────────────────────────────────────────────
var _player: Node = null
var _hud: Node = null
var _phase: String = "entry"   # "entry" | "selection" | "quiz" | "sneak" | "done"

var _chosen_animal_id: String = ""
var _chosen_mission_id: String = ""
var _riddler_node: Node = null

# Guard sneak phase
var _guard_node: Node = null
var _guard_patrol_dir: float = 1.0
var _guard_hint_label: Label = null
var _exit_zone: Area2D = null
var _near_exit: bool = false
var _disguise_zone: Area2D = null
var _disguised: bool = false
var _near_disguise: bool = false

# Ticket booth
var _near_booth: bool = false
var _booth_hint_label: Label = null

# Back-door exit (handled in _process, not coroutine)
var _near_back_door: bool = false

# Selection zones
var _animal_zones: Dictionary = {}   # animal_id → Area2D
var _near_animal: String = ""


# ── Regular animals ───────────────────────────────────────────────────────────
const REGULAR_ANIMALS: Array[Dictionary] = [
	{"id": "bear",   "emoji": "🐻", "mission": "aquarium_rescue_bear",   "pos": Vector2(-240, -60)},
	{"id": "dog",    "emoji": "🐶", "mission": "aquarium_rescue_dog",    "pos": Vector2(0,    -60)},
	{"id": "cat",    "emoji": "🐱", "mission": "aquarium_rescue_cat",    "pos": Vector2(240,  -60)},
]
const VIP_ANIMALS: Array[Dictionary] = [
	{"id": "dolphin",    "emoji": "🐬",   "mission": "aquarium_rescue_dolphin",    "pos": Vector2(-240, -220)},
	{"id": "hellokitty", "emoji": "🐱✨", "mission": "aquarium_rescue_hellokitty", "pos": Vector2(0,    -220)},
	{"id": "goldenbear", "emoji": "🐻‍⭐", "mission": "aquarium_rescue_goldenbear",  "pos": Vector2(240,  -220)},
]


# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	add_to_group("aquarium_manager")
	print("[Aquarium] Loading City Aquarium...")
	GameState.current_scene = "res://scenes/levels/v1_aquarium/Aquarium.tscn"

	_spawn_hud()
	_spawn_player()
	_setup_ticket_booth()
	_setup_animal_cages()
	_setup_exit_zone()
	AudioManager.play_music("start_area")
	print("[Aquarium] Aquarium ready!")


func _process(delta: float) -> void:
	match _phase:
		"entry":
			if _near_booth and Input.is_action_just_pressed("interact"):
				_open_ticket_booth()
			elif _near_back_door and Input.is_action_just_pressed("interact"):
				_leave_aquarium()
		"selection":
			if _near_animal != "" and Input.is_action_just_pressed("interact"):
				_choose_animal(_near_animal)
		"sneak":
			if _near_disguise and not _disguised and Input.is_action_just_pressed("interact"):
				_apply_disguise()
			if _near_exit and _disguised and Input.is_action_just_pressed("interact"):
				_attempt_exit()
			_update_guard(delta)


# ─────────────────────────────────────────────────────────────────────────────
# SPAWN
# ─────────────────────────────────────────────────────────────────────────────
func _spawn_hud() -> void:
	_hud = HUDScene.instantiate()
	add_child(_hud)


func _spawn_player() -> void:
	_player = PlayerScene.instantiate()
	var sort_layer := get_node_or_null("SortLayer")
	if sort_layer:
		sort_layer.add_child(_player)
	else:
		add_child(_player)
	var spawn := get_node_or_null("PlayerSpawn")
	_player.global_position = spawn.global_position if spawn else Vector2(0, 280)
	CheckpointManager.save_checkpoint(_player.global_position)


# ─────────────────────────────────────────────────────────────────────────────
# TICKET BOOTH
# ─────────────────────────────────────────────────────────────────────────────
func _setup_ticket_booth() -> void:
	var zone := Area2D.new()
	zone.collision_layer = 4
	zone.collision_mask = 2
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 55.0
	col.shape = shape
	zone.add_child(col)
	zone.global_position = Vector2(0, 200)
	add_child(zone)
	zone.body_entered.connect(func(b): if b.is_in_group("player"): _near_booth = true; _booth_hint_label.visible = true)
	zone.body_exited.connect(func(b): if b.is_in_group("player"): _near_booth = false; _booth_hint_label.visible = false)

	_booth_hint_label = Label.new()
	_booth_hint_label.text = "[E] Ticket Booth"
	_booth_hint_label.position = Vector2(-50, -70)
	_booth_hint_label.add_theme_font_size_override("font_size", 12)
	_booth_hint_label.modulate = Color(1, 1, 0.4, 1)
	_booth_hint_label.visible = false
	zone.add_child(_booth_hint_label)


func _open_ticket_booth() -> void:
	var dialogue_box := _hud.get_node_or_null("DialogueBox")
	if not dialogue_box:
		return

	if GameState.aquarium_entry_paid:
		# Already paid — just remind them of VIP status
		var welcome_lines: Array = [
			"[Ticket Booth] Welcome back! You're all set to explore. 🎟️",
		]
		if GameState.is_vip:
			welcome_lines.append("[Ticket Booth] VIP access: ✅ You can challenge the Riddler for any animal!")
		else:
			welcome_lines.append("[Ticket Booth] VIP upgrade still available — 15 more VIBE for dolphin, Hello Kitty & Golden Bear!")
		dialogue_box.show_dialogue("Ticket Booth", welcome_lines, self)
		_phase = "selection"
		return

	# First visit — offer regular or VIP
	var can_vip: bool = GameState.vibe_tokens >= ENTRY_FEE_VIP
	var can_regular: bool = GameState.vibe_tokens >= ENTRY_FEE_REGULAR

	var lines: Array = [
		"[Ticket Booth] Welcome to the City Aquarium! 🐠🌊",
		"[Ticket Booth] Animals here need rescuing — but the Riddler won't give them up without a fight.",
		"[Ticket Booth] Regular Entry: %d VIBE — unlocks Bear 🐻, Dog 🐶, Cat 🐱" % ENTRY_FEE_REGULAR,
		"[Ticket Booth] VIP Entry: %d VIBE — also unlocks Dolphin 🐬, Hello Kitty 🐱✨, Golden Bear 🐻‍⭐!" % ENTRY_FEE_VIP,
	]

	if can_vip:
		lines.append({
			"type": "question",
			"text": "You have %d VIBE. Which entry?" % GameState.vibe_tokens,
			"choices": ["VIP Entry (%d VIBE)" % ENTRY_FEE_VIP, "Regular Entry (%d VIBE)" % ENTRY_FEE_REGULAR, "Not today"],
			"responses": [
				[{"type": "action", "action": "buy_vip"}],
				[{"type": "action", "action": "buy_regular"}],
				["[Ticket Booth] Come back when you're ready! The animals will wait."],
			],
		})
	elif can_regular:
		lines.append({
			"type": "question",
			"text": "You have %d VIBE. Regular Entry (%d VIBE)?" % [GameState.vibe_tokens, ENTRY_FEE_REGULAR],
			"choices": ["Pay %d VIBE & Enter" % ENTRY_FEE_REGULAR, "Not today"],
			"responses": [
				[{"type": "action", "action": "buy_regular"}],
				["[Ticket Booth] Come back when you're ready!"],
			],
		})
	else:
		lines.append("[Ticket Booth] You need at least %d VIBE to enter. Earn more VIBE and come back!" % ENTRY_FEE_REGULAR)

	dialogue_box.show_dialogue("Ticket Booth", lines, self)


func on_dialogue_action(action: String) -> void:
	match action:
		"buy_vip":
			if GameState.spend_tokens(ENTRY_FEE_VIP):
				GameState.aquarium_entry_paid = true
				GameState.is_vip = true
				SaveManager.save_game()
				if _hud:
					_hud.show_notification("🌟 VIP Access granted! All animals unlocked!")
				_phase = "selection"
		"buy_regular":
			if GameState.spend_tokens(ENTRY_FEE_REGULAR):
				GameState.aquarium_entry_paid = true
				SaveManager.save_game()
				if _hud:
					_hud.show_notification("🎟️ Entry paid! Choose an animal to rescue.")
				_phase = "selection"


# ─────────────────────────────────────────────────────────────────────────────
# ANIMAL CAGES
# ─────────────────────────────────────────────────────────────────────────────
func _setup_animal_cages() -> void:
	var all_animals: Array = REGULAR_ANIMALS + VIP_ANIMALS
	for animal in all_animals:
		_make_cage_zone(animal)


func _make_cage_zone(animal: Dictionary) -> void:
	var zone := Area2D.new()
	zone.collision_layer = 4
	zone.collision_mask = 2
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 52.0
	col.shape = shape
	zone.add_child(col)
	zone.global_position = animal.get("pos", Vector2.ZERO)
	add_child(zone)

	var animal_id: String = animal.get("id", "")
	_animal_zones[animal_id] = zone

	# Label showing the animal
	var already_freed: bool = GameState.aquarium_animals_freed.has(animal_id)
	var is_vip_animal: bool = VIP_ANIMALS.any(func(a): return a.get("id") == animal_id)
	var lbl := Label.new()
	lbl.text = "%s%s" % [animal.get("emoji", "?"), "  [FREED]" if already_freed else ("  [VIP]" if is_vip_animal else "")]
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.position = Vector2(-24, -60)
	lbl.modulate = Color(1.0, 0.90, 0.20, 1) if not already_freed else Color(0.5, 0.9, 0.5, 1)
	zone.add_child(lbl)

	var hint := Label.new()
	hint.text = "[E] Choose this animal"
	hint.add_theme_font_size_override("font_size", 11)
	hint.position = Vector2(-56, -80)
	hint.modulate = Color(1, 1, 0.4, 1)
	hint.visible = false
	zone.add_child(hint)

	zone.body_entered.connect(func(b: Node) -> void:
		if b.is_in_group("player") and _phase == "selection":
			_near_animal = animal_id
			hint.visible = true
	)
	zone.body_exited.connect(func(b: Node) -> void:
		if b.is_in_group("player"):
			if _near_animal == animal_id:
				_near_animal = ""
			hint.visible = false
	)


func _choose_animal(animal_id: String) -> void:
	if GameState.aquarium_animals_freed.has(animal_id):
		if _hud:
			_hud.show_notification("You've already freed that animal! Choose another.")
		return

	# Check VIP requirement
	var is_vip_animal: bool = VIP_ANIMALS.any(func(a): return a.get("id") == animal_id)
	if is_vip_animal and not GameState.is_vip:
		if _hud:
			_hud.show_notification("🔒 VIP access required for this animal!")
		return

	# Find the mission ID for this animal
	var all_animals: Array = REGULAR_ANIMALS + VIP_ANIMALS
	_chosen_animal_id = animal_id
	for a in all_animals:
		if a.get("id") == animal_id:
			_chosen_mission_id = a.get("mission", "")
			break

	if _chosen_mission_id.is_empty():
		return

	_phase = "quiz"
	_spawn_riddler_for_animal(animal_id)


func _spawn_riddler_for_animal(animal_id: String) -> void:
	# Remove any existing Riddler
	if is_instance_valid(_riddler_node):
		_riddler_node.queue_free()

	_riddler_node = RiddlerScene.instantiate()
	var sort_layer := get_node_or_null("SortLayer")
	if sort_layer:
		sort_layer.add_child(_riddler_node)
	else:
		add_child(_riddler_node)

	# Position in front of the chosen cage
	var all_animals: Array = REGULAR_ANIMALS + VIP_ANIMALS
	for a in all_animals:
		if a.get("id") == animal_id:
			_riddler_node.global_position = a.get("pos", Vector2.ZERO) + Vector2(0, 50)
			break

	_riddler_node.setup(_chosen_mission_id, animal_id, _hud)


# ─────────────────────────────────────────────────────────────────────────────
# CALLED BY RiddlerNPC AFTER QUIZ PASSES
# ─────────────────────────────────────────────────────────────────────────────
func on_riddler_passed(animal_id: String, mission_id: String) -> void:
	_chosen_animal_id = animal_id
	_chosen_mission_id = mission_id
	_phase = "sneak"
	_disguised = false

	# Remove riddler
	if is_instance_valid(_riddler_node):
		_riddler_node.queue_free()

	_setup_disguise_zone(animal_id)
	_setup_guard()

	if _hud:
		_hud.show_notification("🎭 Cage open! Disguise the animal [E], then SNEAK (Shift) past the guard to the exit!")


# ─────────────────────────────────────────────────────────────────────────────
# SNEAK PHASE
# ─────────────────────────────────────────────────────────────────────────────
func _setup_disguise_zone(animal_id: String) -> void:
	_disguise_zone = Area2D.new()
	_disguise_zone.collision_layer = 4
	_disguise_zone.collision_mask = 2
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 50.0
	col.shape = shape
	_disguise_zone.add_child(col)

	# Place disguise zone at the open cage
	var all_animals: Array = REGULAR_ANIMALS + VIP_ANIMALS
	var cage_pos: Vector2 = Vector2.ZERO
	for a in all_animals:
		if a.get("id") == animal_id:
			cage_pos = a.get("pos", Vector2.ZERO)
			break
	_disguise_zone.global_position = cage_pos
	add_child(_disguise_zone)

	var hint := Label.new()
	hint.text = "[E] Disguise the animal!"
	hint.add_theme_font_size_override("font_size", 13)
	hint.position = Vector2(-60, -70)
	hint.modulate = Color(0.4, 1.0, 0.4, 1)
	_disguise_zone.add_child(hint)

	_disguise_zone.body_entered.connect(func(b): if b.is_in_group("player"): _near_disguise = true)
	_disguise_zone.body_exited.connect(func(b): if b.is_in_group("player"): _near_disguise = false)


func _apply_disguise() -> void:
	_disguised = true
	if is_instance_valid(_disguise_zone):
		_disguise_zone.queue_free()

	var dialogue_box := _hud.get_node_or_null("DialogueBox") if _hud else null
	var animal_data := _get_animal_data(_chosen_animal_id)
	var emoji: String = animal_data.get("emoji", "🐾")
	var lines: Array = [
		"[You] You slap a tourist hat and sunglasses onto the %s %s." % [emoji, _chosen_animal_id],
		"[You] Not exactly convincing... but it might just work!",
		"[You] Now — SNEAK (hold Shift) to the exit at the top. Don't let the guard see you walking normally!",
	]
	if dialogue_box:
		dialogue_box.show_dialogue("You", lines, self)
	elif _hud:
		_hud.show_notification("Disguise applied! Hold Shift and sneak to the 🚪 exit!")


func _setup_guard() -> void:
	_guard_node = Node2D.new()
	_guard_node.name = "AquariumGuard"
	add_child(_guard_node)

	# Drawn as a simple guard figure
	var figure := _GuardFigure.new()
	_guard_node.add_child(figure)

	_guard_node.global_position = Vector2(150, 80)

	var name_lbl := Label.new()
	name_lbl.text = "🔒 Guard"
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.position = Vector2(-22, -60)
	name_lbl.modulate = Color(0.9, 0.4, 0.2, 1)
	_guard_node.add_child(name_lbl)

	# Detection zone
	var detect := Area2D.new()
	detect.collision_layer = 4
	detect.collision_mask = 2
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 80.0
	col.shape = shape
	detect.add_child(col)
	_guard_node.add_child(detect)

	detect.body_entered.connect(func(body: Node) -> void:
		if body.is_in_group("player") and _phase == "sneak":
			_check_guard_detection(body)
	)


func _update_guard(delta: float) -> void:
	if not is_instance_valid(_guard_node):
		return
	# Simple left-right patrol near exit
	_guard_node.global_position.x += _guard_patrol_dir * 60.0 * delta
	if _guard_node.global_position.x > 300:
		_guard_patrol_dir = -1.0
	elif _guard_node.global_position.x < -300:
		_guard_patrol_dir = 1.0


func _check_guard_detection(player: Node) -> void:
	# If player is sneaking, guard doesn't notice
	if player.has_method("is_player_sneaking") and player.is_player_sneaking():
		return
	# Caught! Reset sneak phase
	if _hud:
		_hud.show_notification("🔒 The guard spotted you! Head back and try again. Hold Shift to sneak!")
	# Reset disguise so player must try again
	_disguised = false
	# Send player back to the cage area
	if _player:
		_player.global_position = Vector2(0, 100)
	_setup_disguise_zone(_chosen_animal_id)


func _setup_exit_zone() -> void:
	_exit_zone = Area2D.new()
	_exit_zone.collision_layer = 4
	_exit_zone.collision_mask = 2
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 55.0
	col.shape = shape
	_exit_zone.add_child(col)
	_exit_zone.global_position = Vector2(0, -360)
	add_child(_exit_zone)

	var hint := Label.new()
	hint.text = "[E] 🚪 EXIT"
	hint.add_theme_font_size_override("font_size", 14)
	hint.position = Vector2(-28, -50)
	hint.modulate = Color(1, 1, 0.4, 1)
	hint.visible = false
	_exit_zone.add_child(hint)

	_exit_zone.body_entered.connect(func(b: Node) -> void:
		if b.is_in_group("player"):
			_near_exit = true
			hint.visible = true
	)
	_exit_zone.body_exited.connect(func(b: Node) -> void:
		if b.is_in_group("player"):
			_near_exit = false
			hint.visible = false
	)

	# Also set up an "exit to start area" zone separate from the sneak exit
	var back_zone := Area2D.new()
	back_zone.collision_layer = 4
	back_zone.collision_mask = 2
	var bcol := CollisionShape2D.new()
	var bshape := CircleShape2D.new()
	bshape.radius = 50.0
	bcol.shape = bshape
	back_zone.add_child(bcol)
	back_zone.global_position = Vector2(0, 370)
	add_child(back_zone)

	var back_hint := Label.new()
	back_hint.text = "[E] Leave Aquarium"
	back_hint.add_theme_font_size_override("font_size", 12)
	back_hint.position = Vector2(-56, -46)
	back_hint.modulate = Color(1, 1, 0.4, 1)
	back_hint.visible = false
	back_zone.add_child(back_hint)

	back_zone.body_entered.connect(func(b: Node) -> void:
		if b.is_in_group("player"):
			_near_back_door = true
			back_hint.visible = true
	)
	back_zone.body_exited.connect(func(b: Node) -> void:
		if b.is_in_group("player"):
			_near_back_door = false
			back_hint.visible = false
	)



func _attempt_exit() -> void:
	if not _disguised:
		if _hud:
			_hud.show_notification("Disguise the animal first! Press [E] at the open cage.")
		return
	_complete_rescue()


func _complete_rescue() -> void:
	_phase = "done"

	# Grant reward
	var mission_data := MissionDatabase.get_mission(_chosen_mission_id)
	var rewards: Dictionary = mission_data.get("rewards", {})
	RewardManager.grant_reward(rewards)
	MissionManager.complete_mission(_chosen_mission_id)

	# Mark animal as freed
	if not GameState.aquarium_animals_freed.has(_chosen_animal_id):
		GameState.aquarium_animals_freed.append(_chosen_animal_id)
	SaveManager.save_game()

	# Victory dialogue then exit
	var dialogue_box := _hud.get_node_or_null("DialogueBox") if _hud else null
	var animal_data := _get_animal_data(_chosen_animal_id)
	var lines: Array = [
		"[You] You slip out the exit with the %s %s in disguise!" % [animal_data.get("emoji", "🐾"), _chosen_animal_id],
		"[You] Once outside, you release them into the wild. FREEDOM! 🎉",
		"[You] The %s gives you a grateful look before disappearing." % _chosen_animal_id,
	]
	if dialogue_box:
		dialogue_box.show_dialogue("You", lines, self)
	# Return to Start Area after a beat
	await get_tree().create_timer(4.0).timeout
	_leave_aquarium()


func _leave_aquarium() -> void:
	if _player:
		GameState.player_position = Vector2(-200, -220)
	if is_inside_tree():
		get_tree().change_scene_to_file("res://scenes/levels/v1_start_area/StartArea.tscn")


func _get_animal_data(animal_id: String) -> Dictionary:
	var all_animals: Array = REGULAR_ANIMALS + VIP_ANIMALS
	for a in all_animals:
		if a.get("id") == animal_id:
			return a
	return {}


func _notification(what: int) -> void:
	if what == NOTIFICATION_EXIT_TREE:
		if _player:
			GameState.player_position = _player.global_position
		SaveManager.save_game()


# ── Inner class: guard figure ─────────────────────────────────────────────────
class _GuardFigure extends Node2D:
	func _ready() -> void:
		queue_redraw()

	func _draw() -> void:
		draw_colored_polygon(
			_ellipse_pts(Vector2(0, 6), 14, 5),
			Color(0.05, 0.05, 0.10, 0.28),
		)
		# Body — navy uniform
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(-11, 0), Vector2(11, 0),
				Vector2(9, -34), Vector2(-9, -34),
			]),
			Color(0.12, 0.18, 0.42),
		)
		draw_circle(Vector2(0, -44), 11.0, Color(0.82, 0.68, 0.50))
		# Hat
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(-12, -54), Vector2(12, -54),
				Vector2(10, -68), Vector2(-10, -68),
			]),
			Color(0.10, 0.14, 0.36),
		)
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(-16, -54), Vector2(16, -54),
				Vector2(14, -57), Vector2(-14, -57),
			]),
			Color(0.10, 0.14, 0.36),
		)
		draw_circle(Vector2(-3, -46), 2.0, Color(0.15, 0.10, 0.25))
		draw_circle(Vector2(3, -46), 2.0, Color(0.15, 0.10, 0.25))
		# Badge
		draw_circle(Vector2(-2, -20), 4.0, Color(0.88, 0.80, 0.10, 0.90))

	func _ellipse_pts(center: Vector2, rx: float, ry: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		const SEG := 16
		for i in SEG:
			var a := TAU * float(i) / float(SEG)
			pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
		return pts
