## DifficultyManager.gd
## =============================================================
## Shared difficulty scaling for all challenge panels.
##
## Tier is auto-selected from the player's level, but any challenge
## can override it by placing "difficulty": "easy"|"normal"|"hard"
## inside its MissionDatabase "challenge" block.
##
## Usage in any challenge panel's show_challenge():
##   var cfg := DifficultyManager.scale(mission_data.get("challenge", {}))
##   _time_window = cfg.get("time_window",     1.8)
##   _required    = cfg.get("required",          3)
##   _question_time  = cfg.get("question_time", 15.0)
##   _required_correct = cfg.get("required_correct", 8)
## =============================================================
extends Node

## Difficulty tiers (also used as index into TIER_CONFIG)
enum Tier { EASY, NORMAL, HARD }

## Player-level thresholds for automatic tier selection
const LEVEL_FOR_NORMAL: int = 5
const LEVEL_FOR_HARD:   int = 15

## Per-tier scale factors applied to default param values.
## Explicit values set in MissionDatabase challenge blocks are never scaled.
const TIER_CONFIG: Array = [
	# EASY — more time, larger tolerance, fewer required wins
	{
		"time_scale":          1.40,
		"tolerance_scale":     1.60,
		"required_scale":      0.70,
		"question_time_scale": 1.35,
		"speed_scale":         0.80,
	},
	# NORMAL — baseline
	{
		"time_scale":          1.00,
		"tolerance_scale":     1.00,
		"required_scale":      1.00,
		"question_time_scale": 1.00,
		"speed_scale":         1.00,
	},
	# HARD — less time, tighter tolerance, more required wins
	{
		"time_scale":          0.75,
		"tolerance_scale":     0.65,
		"required_scale":      1.20,
		"question_time_scale": 0.75,
		"speed_scale":         1.30,
	},
]


## Returns the active Tier for a challenge config.
## The challenge block may set "difficulty": "easy"|"normal"|"hard" to
## force a specific tier; otherwise the player's level decides.
func current_tier(challenge_cfg: Dictionary = {}) -> Tier:
	var override: String = challenge_cfg.get("difficulty", "").to_lower()
	match override:
		"easy":   return Tier.EASY
		"normal": return Tier.NORMAL
		"hard":   return Tier.HARD

	var lvl: int = GameState.player_level
	if lvl >= LEVEL_FOR_HARD:   return Tier.HARD
	if lvl >= LEVEL_FOR_NORMAL: return Tier.NORMAL
	return Tier.EASY


## Returns a copy of challenge_cfg with difficulty-scaled default values
## injected for any key that is NOT already explicitly present.
## Panels read from the returned dict; explicit MissionDatabase values win.
func scale(challenge_cfg: Dictionary) -> Dictionary:
	var tier_idx: int = int(current_tier(challenge_cfg))
	var tc: Dictionary = TIER_CONFIG[tier_idx]
	var out := challenge_cfg.duplicate()

	# Obstacle course / generic timing
	if not out.has("time_window"):
		out["time_window"] = _sf(1.8, tc["time_scale"])
	if not out.has("required"):
		out["required"] = _si(3, tc["required_scale"])

	# Riddler quiz
	if not out.has("question_time"):
		out["question_time"] = _sf(15.0, tc["question_time_scale"])
	if not out.has("questions"):
		out["questions"] = 10  # total questions — pool size, not scaled
	if not out.has("required_correct"):
		out["required_correct"] = _si(8, tc["required_scale"])

	# Art palette tolerance (smaller = harder)
	if not out.has("tolerance"):
		out["tolerance"] = _sf(0.12, tc["tolerance_scale"])

	# Soccer
	if not out.has("shots"):
		out["shots"] = 3
	if not out.has("required_goals"):
		out["required_goals"] = _si(2, tc["required_scale"])
	if not out.has("power_speed"):
		out["power_speed"] = _sf(1.4, tc["speed_scale"])
	if not out.has("aim_speed"):
		out["aim_speed"] = _sf(1.2, tc["speed_scale"])

	# Generic rounds
	if not out.has("rounds"):
		out["rounds"] = 3
	if not out.has("rounds_required"):
		out["rounds_required"] = _si(2, tc["required_scale"])

	return out


## Readable label for the current tier (useful for debug HUD / UI).
func tier_label(challenge_cfg: Dictionary = {}) -> String:
	match current_tier(challenge_cfg):
		Tier.EASY: return "Easy"
		Tier.HARD: return "Hard"
		_:         return "Normal"


# ── Helpers ────────────────────────────────────────────────────────────────
func _sf(base: float, factor: float) -> float:
	return base * factor


func _si(base: int, factor: float) -> int:
	return maxi(1, roundi(float(base) * factor))
