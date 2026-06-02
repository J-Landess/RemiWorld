# 📜 Credits & Licenses

## Remi's World

---

## Engine

**Godot Engine 4**
- Website: https://godotengine.org
- License: MIT License
- Copyright (c) 2014-present Godot Engine contributors

---

## Placeholder Assets

Most gameplay visuals in Version 0.1–1.5+ are **placeholder art** generated programmatically
using Godot's `_draw()` API (soft ¾-view props, parallax sky/hills, character shadows).

The **Start Area** (v2 visuals) uses `SoftViewGround`, `SoftViewProp`, and `SoftViewParallaxLayer`
under `scripts/levels/visuals/`. NPCs use `SoftNpcFigure` and `NpcOverheadBadge` under `scripts/npcs/visuals/`.
Replace these with licensed sprite/tile packs when ready.

**No external image assets are currently included** (except `assets/ui/icon.svg`).

---

## Recommended Free Asset Sources

When you're ready to replace placeholders with real art, these sources offer
free, open-source game assets:

### Kenney (kenney.nl)
- Website: https://kenney.nl/assets
- License: Creative Commons Zero (CC0) — completely free, no attribution required
- Recommended packs:
  - Kenney Tiny Town
  - Kenney RPG Urban Pack
  - Kenney UI Pack
  - Kenney Game Icons

### OpenGameArt (opengameart.org)
- Website: https://opengameart.org
- Licenses vary by asset (CC0, CC-BY, CC-BY-SA, GPL)
- Always check the license before using!

### Quaternius (quaternius.com)
- Website: https://quaternius.com
- License: CC0 — free for commercial and personal use
- Recommended: Poly Folks (3D characters for v3.0 avatar)

### itch.io Free Assets
- Website: https://itch.io/game-assets/free
- Many free 2D tilesets, sprites, and UI packs

---

## Audio

A small SFX system was added in v1.7 (Playground Challenges + SFX). At the
moment no audio files ship with the repo — `AudioManager` (autoload) loads
every `.ogg` / `.wav` it finds in `assets/audio/sfx/` and ignores any sound
that's missing, so the game still works in silence.

To enable real sound, drop the files listed in
[assets/audio/sfx/README.md](assets/audio/sfx/README.md) into that folder.

**Recommended free packs (all CC0):**
- Kenney UI Audio — https://kenney.nl/assets/ui-audio
- Kenney Interface Sounds — https://kenney.nl/assets/interface-sounds
- Kenney Digital Audio — https://kenney.nl/assets/digital-audio
- Kenney Casino Audio — https://kenney.nl/assets/casino-audio (bonus FX)

The following Kenney packs are included under CC0 (no attribution required,
credited here as a courtesy):

**Kenney UI Audio** (kenney_ui-audio)
- Source: https://kenney.nl/assets/ui-audio
- License: Creative Commons Zero v1.0 (CC0)
- Files used (renamed): `click.ogg`, `chess_move.ogg`, `paint_brush.ogg`,
  `slider_tick.ogg`, `step.ogg`

**Kenney Digital Audio** (kenney_digital-audio)
- Source: https://kenney.nl/assets/digital-audio
- License: Creative Commons Zero v1.0 (CC0)
- Files used (renamed): `correct.ogg`, `wrong.ogg`, `reward.ogg`,
  `dialogue_blip.ogg`, `bark.ogg`, `whistle.ogg`, `kick.ogg`,
  `goal_cheer.ogg`, `goal_miss.ogg`, `dog_pant.ogg`

> Sound effects by Kenney (kenney.nl) — released under CC0.

**Other free audio sources:**
- Freesound: https://freesound.org (Creative Commons — check per-clip licence)
- OpenGameArt Music: https://opengameart.org/?field_art_type_tid=12
- Pixabay Music: https://pixabay.com/music/

---

## Fonts

No custom fonts are currently implemented (uses Godot's default font).

**Free font sources for future use:**
- Google Fonts: https://fonts.google.com (SIL Open Font License)
  - Suggested: "Nunito" (friendly, rounded, great for kids)
  - Suggested: "Fredoka One" (playful display font)
- DaFont: https://www.dafont.com (check license per font)

---

## Adding New Assets

When adding new assets to this project:

1. Place the asset in the appropriate `assets/` subfolder:
   - Art sprites → `assets/sprites/`
   - Item icons → `assets/icons/`
   - UI elements → `assets/ui/`
   - Audio → `assets/audio/`
   - Fonts → `assets/fonts/`
   - Third-party → `assets/open_source/`

2. Add an entry here in CREDITS.md with:
   - Asset name
   - Author/creator
   - Source URL
   - License

3. For CC-BY licenses, add attribution in this file.

---

## Code

All game code in this project is original and written specifically for Remi's World.

**License:** To be determined (private project — not yet open source)

---

*Last updated: v1.7 (Playground Challenges + SFX)*
