# Sound Effects Folder

Drop short `.ogg` / `.wav` / `.mp3` files in here.

`AudioManager` (autoload) auto-loads every file at startup and registers it
under its base filename. For example, `click.ogg` becomes the sound that
plays when something calls:

```gdscript
AudioManager.play_sfx("click")
```

If a file is missing, the call is silently ignored — the game keeps working.

## Background music

Zone music uses `res://assets/audio/music/` first, then loops some SFX here at low volume
(see `assets/audio/music/README.md`). `paint_brush`, `dog_pant`, and `step` work well as placeholders.

## Filenames the game looks for

### Core UI / Game Feel
- `click.ogg`           — Button presses
- `correct.ogg`         — Correct puzzle answer
- `wrong.ogg`           — Wrong puzzle answer
- `reward.ogg`          — Reward popup (token / XP / NFT earned)
- `dialogue_blip.ogg`   — Quiet tick when dialogue advances
- `step.ogg`            — Player footstep (throttled)
- `bark.ogg`            — Daisy bark

### Chess Challenge
- `chess_move.ogg`      — Piece slides into place

### Soccer Challenge
- `whistle.ogg`         — Coach blows the whistle
- `kick.ogg`            — Ball is kicked
- `goal_cheer.ogg`      — Goal scored
- `goal_miss.ogg`       — Missed shot

### Art Challenge
- `paint_brush.ogg`     — Painting / mixing color
- `slider_tick.ogg`     — Slider value changes

### Daisy Fetch
- `dog_pant.ogg`        — Daisy panting while fetching

## Where to get free sounds

Kenney releases everything CC0 (zero-attribution required, attribution
welcome). Recommended packs:

- https://kenney.nl/assets/ui-audio
- https://kenney.nl/assets/interface-sounds
- https://kenney.nl/assets/digital-audio

Then add credits to [../../../CREDITS.md](../../../CREDITS.md).
