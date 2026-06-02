## AudioManager.gd
## =============================================================
## Tiny sound effect manager. Plays short SFX clips on a small
## pool of AudioStreamPlayer nodes, routed to the "SFX" bus.
##
## Usage (from anywhere in the game):
##   AudioManager.play_sfx("click")
##   AudioManager.play_sfx("correct", 0.1)   # ±10% pitch variance
##
## How it loads sounds:
##   On _ready(), AudioManager scans `res://assets/audio/sfx/` for
##   every .wav / .ogg / .mp3 file and registers it by its base
##   filename (e.g. "click.ogg" → key "click").
##
## If a sound isn't found, play_sfx fail-silently. This means the
## game still works without any audio assets installed.
## =============================================================
extends Node

# ─────────────────────────────────────────────────────────────
# CONSTANTS
# ─────────────────────────────────────────────────────────────
const SFX_FOLDER: String = "res://assets/audio/sfx/"
const POOL_SIZE: int = 6   # Max simultaneous SFX
const MUSIC_BUS_NAME: String = "Music"
const SFX_BUS_NAME: String = "SFX"

# ─────────────────────────────────────────────────────────────
# INTERNAL STATE
# ─────────────────────────────────────────────────────────────
var _sounds: Dictionary = {}          # name → AudioStream
var _pool: Array[AudioStreamPlayer] = []
var _next_player: int = 0


# ─────────────────────────────────────────────────────────────
# READY
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	# Keep playing during pause (UI clicks happen in paused menus)
	process_mode = Node.PROCESS_MODE_ALWAYS

	_build_player_pool()
	_load_all_sfx()
	apply_volume_settings()

	print("[AudioManager] Ready. Loaded %d sound(s) from %s." % [_sounds.size(), SFX_FOLDER])


# ─────────────────────────────────────────────────────────────
# BUILD THE AUDIO STREAM PLAYER POOL
# ─────────────────────────────────────────────────────────────
func _build_player_pool() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = SFX_BUS_NAME if AudioServer.get_bus_index(SFX_BUS_NAME) != -1 else "Master"
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_pool.append(p)


# ─────────────────────────────────────────────────────────────
# LOAD ALL SFX FILES IN THE SFX FOLDER
# ─────────────────────────────────────────────────────────────
func _load_all_sfx() -> void:
	var dir := DirAccess.open(SFX_FOLDER)
	if dir == null:
		return  # Folder doesn't exist yet — fail-silent

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and not file_name.begins_with("."):
			# Godot exports rename .ogg/.wav to .import-tracked but ResourceLoader
			# only sees stripped names. Skip metadata files here.
			if file_name.ends_with(".import"):
				file_name = dir.get_next()
				continue
			var lower := file_name.to_lower()
			if lower.ends_with(".ogg") or lower.ends_with(".wav") or lower.ends_with(".mp3"):
				var key := file_name.get_basename()
				var stream: AudioStream = load(SFX_FOLDER + file_name)
				if stream:
					_sounds[key] = stream
		file_name = dir.get_next()
	dir.list_dir_end()


# ─────────────────────────────────────────────────────────────
# PLAY A SOUND BY NAME
# ─────────────────────────────────────────────────────────────
func play_sfx(sound_name: String, pitch_variance: float = 0.0) -> void:
	if not _sounds.has(sound_name):
		return  # Fail-silent

	var player: AudioStreamPlayer = _pool[_next_player]
	_next_player = (_next_player + 1) % _pool.size()

	player.stream = _sounds[sound_name]
	player.pitch_scale = 1.0
	if pitch_variance > 0.0:
		player.pitch_scale = 1.0 + randf_range(-pitch_variance, pitch_variance)
	player.play()


# ─────────────────────────────────────────────────────────────
# APPLY VOLUME SETTINGS FROM GameState
# Called by SettingsScreen when sliders change.
# ─────────────────────────────────────────────────────────────
func apply_volume_settings() -> void:
	_set_bus_volume(MUSIC_BUS_NAME, GameState.music_volume)
	_set_bus_volume(SFX_BUS_NAME, GameState.sfx_volume)


func _set_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	# Mute when slider is at 0; otherwise convert linear 0–1 to dB
	if linear <= 0.0:
		AudioServer.set_bus_mute(idx, true)
	else:
		AudioServer.set_bus_mute(idx, false)
		AudioServer.set_bus_volume_db(idx, linear_to_db(linear))


# ─────────────────────────────────────────────────────────────
# HELPER: check whether a sound is available (for callers that
# want to fall back to a different effect if missing).
# ─────────────────────────────────────────────────────────────
func has_sfx(sound_name: String) -> bool:
	return _sounds.has(sound_name)
