# 🌟 Remi's World

A kid-friendly 2D adventure game where learning meets play!

Solve logic puzzles, collect VIBE tokens, customize your avatar, and explore a colorful world full of friendly characters.

---

## 🚀 How to Run

### Requirements
- [Godot 4.2+](https://godotengine.org/download) (free, open source)

### Steps
1. Open Godot 4
2. Click **"Import"** and navigate to this folder (`RemiWorld/`)
3. Select `project.godot` and click **"Import & Edit"**
4. Press **F5** (or the ▶ Play button) to run the game
5. The game starts at the **Main Menu**

---

## 🎮 Controls

| Action          | Keys             |
|-----------------|------------------|
| Move            | WASD or Arrow Keys |
| Interact / Talk | E                |
| Open Backpack   | B                |
| Pause / Settings| Escape           |

---

## 📁 Project Structure

```
RemiWorld/
├── project.godot          ← Godot project config (open this in Godot!)
├── README.md              ← You are here
├── ROADMAP.md             ← Version roadmap
├── CREDITS.md             ← Asset credits
│
├── autoload/              ← Always-on singletons (game brain)
│   ├── GameState.gd       ← Player data: tokens, XP, level, settings
│   ├── SaveManager.gd     ← Save/load game to JSON file
│   ├── InventoryManager.gd← Backpack: items, NFTs, collectibles
│   ├── MissionManager.gd  ← Mission tracking (available/complete)
│   ├── RewardManager.gd   ← Giving tokens, XP, items as rewards
│   └── AvatarManager.gd   ← Avatar customization config
│
├── scenes/                ← Godot scenes (.tscn files)
│   ├── main_menu/         ← Main menu screen
│   ├── welcome/           ← Welcome screen (after New Game)
│   ├── player/            ← Player character
│   ├── ui/                ← All UI panels (HUD, Backpack, Store, etc.)
│   ├── npcs/              ← NPC characters
│   └── levels/
│       └── v1_start_area/ ← First playable area
│
├── scripts/               ← GDScript files
│   ├── player/            ← Player movement, interaction
│   ├── systems/           ← Core game systems
│   ├── ui/                ← UI logic scripts
│   ├── npcs/              ← NPC behavior scripts
│   └── data/              ← Item and mission databases
│
├── resources/             ← Godot resource files (.tres)
│   ├── items/
│   ├── missions/
│   ├── npcs/
│   └── avatars/
│
└── assets/                ← Art, audio, fonts
    ├── sprites/
    ├── icons/
    ├── ui/
    ├── audio/
    ├── fonts/
    └── open_source/       ← Third-party open source assets
```

---

## 🎯 Current Version: 0.1 (Scaffold + v1.0–1.5 Vertical Slice)

### What's implemented:
- ✅ **Main Menu** — Start New Game, Load Game, Settings, Exit
- ✅ **Welcome Screen** — Name entry, tips, fade-in animation
- ✅ **Settings Screen** — Music/SFX volume, text speed, accessibility
- ✅ **Start Area** — 2D playable level with placeholder art
- ✅ **Player** — WASD/arrow movement, camera follow, interact system
- ✅ **Coding Bot NPC** — First logic puzzle: "Pattern Power"
- ✅ **Pattern Puzzle** — Multiple choice question with feedback
- ✅ **Reward System** — Earn VIBE tokens + XP + NFT collectibles
- ✅ **Backpack UI** — Shows items, NFTs, tokens (press B)
- ✅ **Shopkeeper Rose NPC** — Opens the store
- ✅ **Store UI** — Buy avatar items with VIBE tokens
- ✅ **Avatar Closet** — Equip purchased items, change skin tone
- ✅ **Save/Load** — JSON save file persists all progress
- ✅ **Pause Menu** — Resume, save, main menu, settings

### What uses placeholder art:
- Player character (solid colored rectangle)
- NPC characters (solid colored rectangles)
- Item icons (colored rectangles)
- Level background (colored rectangles + emoji decorations)

> 📌 Replace placeholders with real sprites from Kenney.nl or OpenGameArt.org!

---

## 🧠 How the Systems Connect

```
GameState  ←──── stores player data (tokens, XP, name)
    │
    ├── SaveManager   ←── reads/writes all managers to JSON
    ├── InventoryManager ←── manages items and NFT collectibles
    ├── MissionManager   ←── tracks mission status
    ├── RewardManager    ←── grants tokens/XP/items to player
    └── AvatarManager    ←── stores avatar customization config

Player → presses E near NPC → NPC.on_player_interact()
       → MissionManager.start_mission()
       → PuzzlePanel.show_puzzle()
       → Player answers → RewardManager.grant_reward()
       → InventoryManager.add_item() + add_nft()
       → SaveManager.save_game()
```

---

## 📚 Beginner Godot Concepts Used

| Concept | Where |
|---------|-------|
| `extends Node` | All scripts inherit from a Godot Node type |
| `@onready var` | Gets a reference to a child node when scene loads |
| `signal` | Custom events that other scripts can listen to |
| `.connect()` | Subscribe to a signal |
| `emit_signal()` | Fire a signal |
| `CharacterBody2D` | Player physics + `move_and_slide()` |
| `StaticBody2D` | NPCs and walls that block movement |
| `Area2D` | Detect when the player gets close |
| `CanvasLayer` | HUD that floats above the game world |
| `autoload` | Scripts that load once and stay available everywhere |
| `get_tree().change_scene_to_file()` | Switch scenes |
| `JSON.stringify()` / `JSON.parse()` | Save/load data |

---

## 🔮 Future Roadmap

See [ROADMAP.md](ROADMAP.md) for the full version plan.

- **v2.0** — More NPCs, missions, puzzles, sound
- **v3.0** — 3D avatar customization room
- **v4.0** — Backend/blockchain integration (parent dashboard)

---

## 📜 Credits

See [CREDITS.md](CREDITS.md) for asset licenses.

---

*Built with ❤️ and Godot 4*
