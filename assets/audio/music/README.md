# Background Music

Looping `.ogg` files loaded by `AudioManager.play_music()`.

| Zone            | File               |
|-----------------|--------------------|
| start_area      | start_area.ogg     |
| playground      | playground.ogg     |
| dog_pit         | dog_pit.ogg        |
| road_to_boston  | road_run.ogg       |
| school          | (falls back to sfx/step.ogg) |

If a music file is missing, the game loops a soft SFX from `assets/audio/sfx/` instead.
