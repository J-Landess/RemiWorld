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
under `scripts/levels/visuals/`. Replace these with licensed sprite/tile packs when ready.

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

No audio is currently implemented (planned for v2.0).

**Free audio sources for future use:**
- Freesound: https://freesound.org (Creative Commons)
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

*Last updated: v0.1.0*
