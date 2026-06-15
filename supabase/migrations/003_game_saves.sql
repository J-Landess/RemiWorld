-- 003_game_saves.sql
-- Cloud save blob for story flags, position, settings, and mission status.
-- One row per user; last-write-wins conflict resolution (v1).
-- Economy (tokens/xp/level/inventory/nfts) lives in real tables, NOT here.

create table if not exists public.game_saves (
  user_id      uuid primary key references auth.users on delete cascade,
  save_json    jsonb not null,
  save_version int   not null default 1,
  updated_at   timestamptz not null default now()
);

drop trigger if exists set_game_saves_updated_at on public.game_saves;
create trigger set_game_saves_updated_at
  before update on public.game_saves
  for each row execute function public.set_updated_at();

alter table public.game_saves enable row level security;

create policy "game_saves_select_own"
  on public.game_saves for select
  using (auth.uid() = user_id);

create policy "game_saves_upsert_own"
  on public.game_saves for insert
  with check (auth.uid() = user_id);

create policy "game_saves_update_own"
  on public.game_saves for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
