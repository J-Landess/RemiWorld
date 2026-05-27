# 🔐 Blockchain Integration — Future Plan (Version 4.0)

> **STATUS: NOT IMPLEMENTED**
> This document is for planning only. No blockchain code exists in the game.
> Version 1.x uses simple in-game values for all "tokens" and "NFTs."

---

## Current State (v1.x)

In the current version:

| Game Feature | Reality |
|-------------|---------|
| "VIBE Tokens" | Integer value in `GameState.vibe_tokens` |
| "NFT Collectibles" | Dictionary in `InventoryManager._nfts` |
| "Backpack" | Local data, saved to JSON file |
| "Blockchain" | Does not exist yet |

---

## Future Vision (v4.0+)

### Architecture

```
┌─────────────────────────────────────────┐
│           GODOT GAME CLIENT              │
│                                          │
│  GameState.vibe_tokens ────────────────►│
│  InventoryManager._nfts ───────────────►│
│                                          │
└──────────────┬──────────────────────────┘
               │ HTTPS REST API (no Web3)
               ▼
┌─────────────────────────────────────────┐
│           BACKEND SERVER                 │
│         (Supabase or FastAPI)            │
│                                          │
│  ┌─────────────────┐                    │
│  │  Player Accounts │                   │
│  │  Reward Queue    │                   │
│  │  Parent Dashboard│                   │
│  └────────┬─────────┘                   │
│           │ (admin only)                 │
└───────────┼─────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────┐
│         BLOCKCHAIN SERVICE               │
│         (Backend microservice)           │
│                                          │
│  ERC-20: VIBE Token (mint/transfer)      │
│  ERC-721/1155: NFT (mint/airdrop)        │
│  Wallet management (parent controlled)   │
└─────────────────────────────────────────┘
```

### Key Rules

1. **Children NEVER interact with blockchain directly**
   - No MetaMask, no wallet connect, no private keys

2. **Parents/guardians control wallets**
   - A parent dashboard approves token withdrawals
   - Parents own the wallet that holds the child's tokens

3. **The game only talks to our backend**
   - Godot calls our REST API (like any normal web request)
   - The backend talks to the blockchain

4. **Everything is earned in-game first**
   - Play → earn VIBE in-game → parent approves → tokens minted on-chain

---

## API Design (Future)

### Game → Backend calls:

```
POST /api/rewards/grant
{
  "player_id": "...",
  "tokens": 10,
  "reason": "mission:pattern_power"
}

GET /api/inventory/{player_id}
→ Returns items, NFTs, token balance

POST /api/nfts/claim
{
  "player_id": "...",
  "nft_id": "pattern_star_nft",
  "mission_id": "pattern_power"
}
```

### Backend → Blockchain calls (admin only):

```
# Parent approves withdrawal in parent dashboard
POST /admin/tokens/mint
{
  "wallet_address": "0x...",
  "amount": 10,
  "currency": "VIBE"
}

POST /admin/nfts/mint
{
  "wallet_address": "0x...",
  "nft_metadata_uri": "ipfs://...",
  "contract": "ERC-721"
}
```

---

## Token Economics (Draft)

| Action | Tokens Earned |
|--------|--------------|
| Complete a mission | 5–25 VIBE |
| Solve a puzzle | 10 VIBE |
| Daily login streak | 5 VIBE |
| Refer a friend | 50 VIBE |

| Action | Tokens Spent |
|--------|-------------|
| Buy avatar item | 5–20 VIBE |
| Unlock new world | 30–50 VIBE |
| Premium avatar | 100 VIBE |

---

## NFT Tiers (Draft)

| Rarity | Drop Rate | Example |
|--------|-----------|---------|
| Common | ~50% | Pattern Star Badge |
| Uncommon | ~25% | Rainbow Crown |
| Rare | ~15% | Coding Wizard Hat |
| Epic | ~7% | Holographic Outfit |
| Legendary | ~2% | Dragon Wings |
| Secret | <1% | Founder's Badge |

---

## Supabase Schema (Future)

```sql
-- Players table
CREATE TABLE players (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_name TEXT NOT NULL,
  parent_email TEXT NOT NULL,
  vibe_balance INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Inventory table
CREATE TABLE inventory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID REFERENCES players(id),
  item_id TEXT NOT NULL,
  item_type TEXT NOT NULL, -- 'item' or 'nft'
  quantity INTEGER DEFAULT 1,
  obtained_at TIMESTAMPTZ DEFAULT NOW()
);

-- Mission completions
CREATE TABLE mission_completions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID REFERENCES players(id),
  mission_id TEXT NOT NULL,
  completed_at TIMESTAMPTZ DEFAULT NOW()
);

-- Pending blockchain transactions (for admin approval)
CREATE TABLE reward_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID REFERENCES players(id),
  reward_type TEXT NOT NULL, -- 'tokens' or 'nft'
  amount INTEGER,
  nft_id TEXT,
  status TEXT DEFAULT 'pending', -- pending/approved/minted/failed
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## Migration Path from v1.x

When v4.0 is built:

1. **Existing save files** are imported as initial blockchain state
2. All current in-game items are "legacy" — parents opt in to on-chain
3. New accounts get a guided setup flow with parent verification
4. The in-game client is updated to make API calls instead of local saves

The code change from local to API-backed is minimal:

```gdscript
# BEFORE (local, v1.x)
func grant_tokens(amount: int) -> void:
    GameState.vibe_tokens += amount

# AFTER (API-backed, v4.0)
func grant_tokens(amount: int) -> void:
    var response = await BackendAPI.post("/rewards/grant", {"tokens": amount})
    GameState.vibe_tokens = response.new_balance
```

---

*Remember: Build Version 1.x first. Make it fun. Blockchain comes later.*
