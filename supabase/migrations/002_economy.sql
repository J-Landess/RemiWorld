-- 002_economy.sql
-- Server-authoritative economy: inventory items, NFTs, reward definitions,
-- and the two validated RPC functions that are the ONLY paths to changing
-- a player's token balance or granting items/NFTs.

-- ─────────────────────────────────────────────────────────────
-- INVENTORY ITEMS
-- ─────────────────────────────────────────────────────────────
create table if not exists public.inventory_items (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users on delete cascade,
  item_id     text not null,
  name        text not null,
  category    text not null,
  rarity      text not null default 'common',
  quantity    int  not null default 1,
  equipped    bool not null default false,
  metadata    jsonb,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (user_id, item_id)
);

drop trigger if exists set_inventory_items_updated_at on public.inventory_items;
create trigger set_inventory_items_updated_at
  before update on public.inventory_items
  for each row execute function public.set_updated_at();

alter table public.inventory_items enable row level security;

create policy "inventory_select_own"
  on public.inventory_items for select
  using (auth.uid() = user_id);

-- Insert allowed for equip-toggle etc, but quantity/economy changes
-- must go through RPCs. Direct INSERT is blocked at the application layer;
-- grant_for_source is SECURITY DEFINER and bypasses RLS when inserting.
create policy "inventory_update_own_equip"
  on public.inventory_items for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ─────────────────────────────────────────────────────────────
-- NFT COLLECTIBLES  (unique per user)
-- ─────────────────────────────────────────────────────────────
create table if not exists public.nfts (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references auth.users on delete cascade,
  nft_id          text not null,
  name            text not null,
  rarity          text not null default 'common',
  discovered_from text,
  tradeable       bool not null default false,
  equipped        bool not null default false,
  token_value     int  not null default 0,
  metadata        jsonb,
  created_at      timestamptz not null default now(),
  unique (user_id, nft_id)
);

alter table public.nfts enable row level security;

create policy "nfts_select_own"
  on public.nfts for select
  using (auth.uid() = user_id);

create policy "nfts_update_own_equip"
  on public.nfts for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ─────────────────────────────────────────────────────────────
-- REWARD DEFINITIONS
-- The server controls what each mission source pays out.
-- Seeded from MissionDatabase.gd in 004_seed_rewards.sql.
-- ─────────────────────────────────────────────────────────────
create table if not exists public.reward_definitions (
  source_id   text primary key,  -- matches mission_id in MissionDatabase.gd
  tokens      int  not null default 0,
  xp          int  not null default 0,
  item        jsonb,             -- single item dict (optional)
  nft         jsonb,             -- single nft dict (optional)
  repeatable  bool not null default false
);

-- Reward definitions are public-readable so the game can display
-- expected rewards before a mission, but not writable by any client.
alter table public.reward_definitions enable row level security;

create policy "reward_definitions_select_all"
  on public.reward_definitions for select
  using (true);

-- ─────────────────────────────────────────────────────────────
-- RPC: grant_for_source
-- Called after the player wins a challenge.
-- Validates the reward server-side, prevents replay of one-time rewards,
-- and grants tokens/xp/item/nft atomically.
-- Returns the granted reward summary, or raises an exception on error.
-- ─────────────────────────────────────────────────────────────
create or replace function public.grant_for_source(p_source_id text)
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare
  v_user_id   uuid := auth.uid();
  v_reward    reward_definitions%rowtype;
  v_already   bool := false;
  v_summary   jsonb := '{}'::jsonb;
  v_nft       jsonb;
  v_item      jsonb;
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  -- Fetch reward definition (raises implicit error if not found).
  select * into strict v_reward
  from public.reward_definitions
  where source_id = p_source_id;

  -- Idempotency: for non-repeatable rewards, check if already claimed.
  if not v_reward.repeatable then
    -- We use the nft as the canonical "already claimed" marker when present.
    if v_reward.nft is not null then
      select exists(
        select 1 from public.nfts
        where user_id = v_user_id and nft_id = (v_reward.nft->>'nft_id')
      ) into v_already;
    end if;

    if v_already then
      raise exception 'Reward already claimed for source: %', p_source_id;
    end if;
  end if;

  -- Grant tokens + XP on the profile row.
  if v_reward.tokens > 0 or v_reward.xp > 0 then
    update public.profiles
    set
      vibe_tokens  = vibe_tokens + v_reward.tokens,
      player_xp    = player_xp   + v_reward.xp,
      -- Level up if xp threshold crossed (100 xp per level, matches game constant).
      player_level = player_level + floor((player_xp + v_reward.xp) / 100)::int
                                  - floor(player_xp / 100)::int,
      player_xp    = (player_xp + v_reward.xp) % 100
    where id = v_user_id;
    v_summary := v_summary || jsonb_build_object('tokens', v_reward.tokens, 'xp', v_reward.xp);
  end if;

  -- Grant NFT (insert-or-ignore).
  v_nft := v_reward.nft;
  if v_nft is not null then
    insert into public.nfts (user_id, nft_id, name, rarity, discovered_from, tradeable, token_value, metadata)
    values (
      v_user_id,
      v_nft->>'nft_id',
      v_nft->>'name',
      coalesce(v_nft->>'rarity', 'common'),
      v_nft->>'discovered_from',
      coalesce((v_nft->>'tradeable')::bool, false),
      coalesce((v_nft->>'token_value')::int, 0),
      v_nft
    )
    on conflict (user_id, nft_id) do nothing;
    v_summary := v_summary || jsonb_build_object('nft', v_nft->>'name');
  end if;

  -- Grant item (upsert quantity).
  v_item := v_reward.item;
  if v_item is not null then
    insert into public.inventory_items
      (user_id, item_id, name, category, rarity, quantity, metadata)
    values (
      v_user_id,
      v_item->>'item_id',
      v_item->>'name',
      coalesce(v_item->>'category', 'Quest Items'),
      coalesce(v_item->>'rarity', 'common'),
      coalesce((v_item->>'quantity')::int, 1),
      v_item
    )
    on conflict (user_id, item_id)
    do update set quantity = inventory_items.quantity + excluded.quantity;
    v_summary := v_summary || jsonb_build_object('item', v_item->>'name');
  end if;

  return v_summary;
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- RPC: spend_tokens
-- Atomic balance check + decrement. Raises an error if insufficient.
-- ─────────────────────────────────────────────────────────────
create or replace function public.spend_tokens(p_amount int)
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare
  v_user_id   uuid := auth.uid();
  v_balance   int;
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if p_amount <= 0 then
    raise exception 'Amount must be positive';
  end if;

  select vibe_tokens into v_balance
  from public.profiles
  where id = v_user_id
  for update;  -- lock the row to prevent race conditions

  if v_balance < p_amount then
    raise exception 'Insufficient tokens: have %, need %', v_balance, p_amount;
  end if;

  update public.profiles
  set vibe_tokens = vibe_tokens - p_amount
  where id = v_user_id;

  return jsonb_build_object('spent', p_amount, 'balance', v_balance - p_amount);
end;
$$;

-- Grant execute to authenticated users (not anon — must be logged in).
grant execute on function public.grant_for_source(text) to authenticated;
grant execute on function public.spend_tokens(int) to authenticated;
