# Background Music

Drop looping `.ogg` files here. `AudioManager.play_music()` loads them by name.

If a file is missing, the game loops a soft track from `assets/audio/sfx/` instead:

| Zone        | Fallback SFX    |
|-------------|-----------------|
| start_area  | paint_brush     |
| playground  | paint_brush     |
| dog_pit     | dog_pant        |
| school      | step            |

Example: add `paint_brush.ogg` here to override the SFX fallback for outdoor areas.
