-- 005_leaderboard.sql
-- Public leaderboard RPC — returns top-N players ranked by VIBE tokens,
-- then by player level as a tiebreaker.
--
-- Only safe, non-identifying fields are returned (no email, no UUID).
-- Callable by anon and authenticated users alike.

create or replace function public.get_leaderboard(top_n int default 20)
returns table (
  rank         bigint,
  player_name  text,
  player_level int,
  vibe_tokens  int
)
language sql
security definer
stable
set search_path = public
as $$
  select
    row_number() over (
      order by vibe_tokens desc, player_level desc
    )::bigint                       as rank,
    coalesce(nullif(trim(player_name), ''), 'Explorer') as player_name,
    player_level,
    vibe_tokens
  from public.profiles
  where vibe_tokens > 0 or player_level > 1
  order by vibe_tokens desc, player_level desc
  limit greatest(1, least(top_n, 100));
$$;

-- Allow the anon key to call this function (no auth required to view leaderboard)
grant execute on function public.get_leaderboard(int) to anon, authenticated;
