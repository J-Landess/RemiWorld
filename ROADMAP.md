# 🗺️ Remi's World — Version Roadmap

---

## Version 0.1 — Project Scaffold ✅ DONE
- Godot 4 project created
- Folder structure established
- All 6 autoload singletons registered
- README and documentation written

---

## Version 1.0 — Main Menu + Welcome Flow ✅ DONE

**Scenes:**
- `MainMenu.tscn` — Start New, Load, Settings, Exit
- `WelcomeScreen.tscn` — Name entry, welcome message
- `SettingsScreen.tscn` — Volume, text speed, accessibility

**Features:**
- Load game checks for save file
- Friendly message if no save exists
- Settings persist to GameState

---

## Version 1.1 — Player + First 2D Area ✅ DONE

**Scenes:**
- `Player.tscn` — CharacterBody2D with camera
- `StartArea.tscn` — First playable level

**Features:**
- WASD + Arrow key movement
- Camera follows player with smoothing
- Collision boundaries (player can't leave the area)
- Interact zone (press E near NPCs)
- Backpack hotkey (press B)

---

## Version 1.2 — Avatar System ✅ DONE

**Scripts:**
- `AvatarManager.gd` — Stores avatar config, equip/unequip logic
- `AvatarCloset.gd` — UI for customizing the avatar

**Features:**
- Skin tone selector (7 options)
- Hairstyle, outfit, shoes, accessory slots
- Avatar preview (2D placeholder)
- Equipping saves to file
- Designed to map to 3D avatar in v3.0

---

## Version 1.3 — Backpack / Inventory System ✅ DONE

**Scripts:**
- `InventoryManager.gd` — Manages all items and NFTs
- `BackpackUI.gd` — UI tabs for all item categories

**Features:**
- Press B to open/close backpack
- Tabs: Tokens, NFTs, Clothes, Accessories, Quest Items, Badges
- Rarity-colored item cards
- Equip button for wearable items
- NFT collectibles shown with metadata

---

## Version 1.4 — First NPC + Logic Puzzle ✅ DONE

**NPCs:**
- Coding Bot (`CodingBot.gd`) — pattern puzzle giver

**Puzzle:**
- "Pattern Power" — Red, Blue, Red, Blue, ___?
- Multiple choice answer
- Correct answer: Red

**Rewards:**
- 10 VIBE Tokens
- 25 XP
- NFT: Pattern Star Badge

**Features:**
- Dialogue box with typewriter effect
- Mission cannot be repeated (configurable)
- Progress saved after completion

---

## Version 1.5 — Storefront ✅ DONE

**NPCs:**
- Shopkeeper Rose (`ShopkeeperRose.gd`) — opens the store

**Store Items:**
| Item | Price |
|------|-------|
| Pink Sneakers | 5 VIBE |
| Star Hair Clip | 8 VIBE |
| Sparkle Shirt | 10 VIBE |
| Rainbow Backpack | 15 VIBE |

**Features:**
- Shows player's VIBE balance
- Blocks purchase if insufficient funds
- Purchased items go to Backpack
- Can open Avatar Closet from store
- Purchases saved automatically

---

## Version 1.6 — Save / Load ✅ DONE (built into v1.0-1.5)

**Save file:** `user://remiworld_save.json`

**Saved data:**
- Player name, level, XP
- VIBE token balance
- All inventory items and NFTs
- Avatar config
- Completed missions
- Settings

---

## Version 1.7 — Playground Challenges + SFX ✅ DONE

A new Playground/Park scene is reachable from the Start Area, packed with
four themed challenges plus a sound-effects system.

**New scene:**
- `scenes/levels/v1_playground/Playground.tscn` — park with 4 activity zones,
  a central bench, flower patches, trees, and an exit back to the Start Area.

**New NPCs (all use `SoftNpcFigure` for placeholder visuals):**
- **Chess Tutor** — wise owl scholar who runs the "Knight's Jump" puzzle
- **Coach Kick** — soccer coach with whistle and ball, runs "Goal Kicker"
- **Artist Pip** — painter in a beret, runs "Rainbow Maker"

**New mini-games (`scenes/ui/challenges/`):**
- **Knight's Jump** (chess) — a 4×4 board mini-game where the player picks
  the legal knight move that lands on the treasure. 3 rounds, 2 to win.
- **Goal Kicker** (soccer) — oscillating POWER and AIM bars, ball tweens
  toward a goalkeeper-guarded net. 3 shots, 2 goals to win.
- **Rainbow Maker** (art) — match a named target color by sliding R/G/B
  sliders within tolerance. 3 rounds, 2 to win.
- **Daisy's Fetch Game** (Daisy) — throw 3 sticks for Daisy to fetch.
  Only playable once Daisy is your companion.

**New rewards:** 4 new badge NFTs (`knight_star`, `golden_cleats`,
`palette_badge`, `best_friend`).

**Audio system:**
- `AudioManager` autoload (sits on its own audio pool, routed to the SFX bus)
- New `default_bus_layout.tres` with Master / Music / SFX buses
- Volume sliders in [SettingsScreen.gd](scripts/ui/SettingsScreen.gd) now actually
  set bus volume in dB
- SFX hooks added to: button presses, puzzle correct/wrong, dialogue advance,
  reward popup, player footstep, Daisy bark
- Drops in CC0 audio from Kenney's free packs — see [CREDITS.md](CREDITS.md)
  and [assets/audio/sfx/README.md](assets/audio/sfx/README.md)

---

## Version 2.0 — Expanded Game Loop 🔜 PLANNED

**New Worlds:**
- School World
- Daycare Escape
- Nail Salon
- Restaurant
- Coding Lab

**New Features:**
- More NPCs with unique personalities
- More logic/math/spelling puzzles
- Quest tracker UI
- Reward popup animation (polish)
- Background music and sound effects
- More store items and avatar options
- Achievement system

---

## Version 3.0 — 3D Avatar Customization Room 🔮 FUTURE

> Only after Version 1.x is complete and stable.

**Goal:** Create a 3D preview room for the player's avatar.

**Features:**
- Basic 3D character model
- Swappable clothing meshes
- Material/color customization
- Rotate avatar to preview
- Syncs with existing `AvatarConfig` data structure

**Notes:**
- The main game stays 2D
- Only the avatar closet switches to 3D preview
- See `docs/3d_avatar_roadmap.md` for technical plan

---

## Version 4.0 — Backend / Blockchain Integration 🔐 FAR FUTURE

> NOT implemented yet. Documentation only.

**Architecture:**
```
Game (Godot)
    │
    └── REST API calls to Backend Server
              │
              ├── Supabase / FastAPI
              │     ├── User accounts
              │     ├── Parent dashboard
              │     └── Reward approval system
              │
              └── Blockchain Service (admin-only)
                    ├── ERC-20: VIBE token minting
                    ├── ERC-721/ERC-1155: NFT minting
                    └── Wallet management (parents, not children)
```

**Important Rules:**
- Children NEVER connect wallets directly
- Parents/admins approve blockchain transactions
- Game uses normal API calls, not Web3 libraries
- NFT metadata served through standard APIs

**VIBE Token mapping:**
- In-game VIBE → future ERC-20 token
- Earned through gameplay → approved by parent → minted on chain

**NFT mapping:**
- In-game collectibles → future ERC-721 NFTs
- Rare items → limited edition mints
- Metadata stored off-chain (IPFS or Supabase)

---

*Last updated: v1.7 — Playground Challenges + SFX*
