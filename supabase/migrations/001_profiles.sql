-- 001_profiles.sql
-- Player identity and progression.
-- vibe_tokens / player_xp / player_level live here so they are
-- server-owned and cannot be edited by the client directly.

create table if not exists public.profiles (
  id              uuid primary key references auth.users on delete cascade,
  display_name    text,
  player_name     text not null default 'Remi',
  player_age      int  not null default 0,
  player_sex      text not null default '',
  player_level    int  not null default 1,
  player_xp       int  not null default 0,
  vibe_tokens     int  not null default 0,
  avatar          jsonb,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

-- Auto-create a profile row the moment a new auth user is created.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Updated-at maintenance.
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- RLS: a user may only see and update their own profile row.
-- Economy columns (vibe_tokens, player_xp, player_level) are excluded
-- from the client-writable column list; only SECURITY DEFINER RPCs touch them.
alter table public.profiles enable row level security;

create policy "profiles_select_own"
  on public.profiles for select
  using (auth.uid() = id);

create policy "profiles_update_own_safe_columns"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);
