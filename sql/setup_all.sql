-- =========================================================
-- Mewati Tune Player — Full Database Setup / Migration
-- Re-runnable: safe to execute multiple times.
-- =========================================================

-- ============ ENABLE ROW LEVEL SECURITY ============
alter table if exists songs enable row level security;
alter table if exists singers enable row level security;
alter table if exists favorites enable row level security;
alter table if exists profiles enable row level security;
alter table if exists likes enable row level security;

-- =========================================================
-- SONGS — public read-only catalog
-- =========================================================
drop policy if exists "songs_select_public" on songs;
create policy "songs_select_public"
  on songs for select
  using (true);

drop policy if exists "songs_no_insert" on songs;
create policy "songs_no_insert"
  on songs for insert
  to anon, authenticated
  with check (false);

drop policy if exists "songs_no_update" on songs;
create policy "songs_no_update"
  on songs for update
  to anon, authenticated
  using (false);

drop policy if exists "songs_no_delete" on songs;
create policy "songs_no_delete"
  on songs for delete
  to anon, authenticated
  using (false);

-- =========================================================
-- SINGERS — public read-only catalog
-- =========================================================
drop policy if exists "singers_select_public" on singers;
create policy "singers_select_public"
  on singers for select
  using (true);

drop policy if exists "singers_no_insert" on singers;
create policy "singers_no_insert"
  on singers for insert
  to anon, authenticated
  with check (false);

drop policy if exists "singers_no_update" on singers;
create policy "singers_no_update"
  on singers for update
  to anon, authenticated
  using (false);

drop policy if exists "singers_no_delete" on singers;
create policy "singers_no_delete"
  on singers for delete
  to anon, authenticated
  using (false);

-- =========================================================
-- FAVORITES — owner-only
-- =========================================================
drop policy if exists "favorites_select_own" on favorites;
create policy "favorites_select_own"
  on favorites for select
  using (auth.uid() = user_id);

drop policy if exists "favorites_insert_own" on favorites;
create policy "favorites_insert_own"
  on favorites for insert
  with check (auth.uid() = user_id);

drop policy if exists "favorites_delete_own" on favorites;
create policy "favorites_delete_own"
  on favorites for delete
  using (auth.uid() = user_id);

-- =========================================================
-- PROFILES — owner-only; subscription_status is client-immutable
-- =========================================================
drop policy if exists "profiles_select_own" on profiles;
create policy "profiles_select_own"
  on profiles for select
  using (auth.uid() = id);

drop policy if exists "profiles_insert_own" on profiles;
create policy "profiles_insert_own"
  on profiles for insert
  with check (auth.uid() = id);

-- Client can update own row, but subscription_status must be unchanged.
-- (Column-level exclusion isn't native to RLS, so we enforce it with a
-- CHECK against the existing row via a trigger-free constraint: the new
-- value must equal the old value unless the caller is service_role.)
drop policy if exists "profiles_update_own" on profiles;
create policy "profiles_update_own"
  on profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

create or replace function public.prevent_subscription_status_change()
returns trigger
language plpgsql
security definer
as $$
begin
  if new.subscription_status is distinct from old.subscription_status
     and auth.role() <> 'service_role' then
    raise exception 'subscription_status can only be changed by an admin process';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_prevent_subscription_status_change on profiles;
create trigger trg_prevent_subscription_status_change
  before update on profiles
  for each row
  execute function public.prevent_subscription_status_change();

-- =========================================================
-- LIKES — owner-only (public like counts come from songs.like_count only)
-- =========================================================
drop policy if exists "Users can view all likes" on likes;

drop policy if exists "likes_select_own" on likes;
create policy "likes_select_own"
  on likes for select
  using (auth.uid() = user_id);

drop policy if exists "likes_insert_own" on likes;
create policy "likes_insert_own"
  on likes for insert
  with check (auth.uid() = user_id);

drop policy if exists "likes_delete_own" on likes;
create policy "likes_delete_own"
  on likes for delete
  using (auth.uid() = user_id);

-- =========================================================
-- FEEDBACK (new table) — F1: Feedback / Suggest a Song
-- =========================================================
create table if not exists feedback (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id),
  category text, -- 'bug' | 'song_suggestion' | 'other'
  message text not null,
  song_id uuid references songs(id), -- nullable
  created_at timestamptz default now()
);

alter table feedback enable row level security;

drop policy if exists "feedback_insert_own" on feedback;
create policy "feedback_insert_own"
  on feedback for insert
  with check (auth.uid() = user_id);

drop policy if exists "feedback_no_select" on feedback;
create policy "feedback_no_select"
  on feedback for select
  to anon, authenticated
  using (false);

drop policy if exists "feedback_no_update" on feedback;
create policy "feedback_no_update"
  on feedback for update
  to anon, authenticated
  using (false);

drop policy if exists "feedback_no_delete" on feedback;
create policy "feedback_no_delete"
  on feedback for delete
  to anon, authenticated
  using (false);

-- =========================================================
-- SCHEMA FIXES
-- =========================================================
alter table songs
  alter column like_count set default 0;

alter table songs
  alter column like_count set not null;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'songs_like_count_nonneg'
  ) then
    alter table songs
      add constraint songs_like_count_nonneg check (like_count >= 0);
  end if;
end $$;

grant select on singers_with_song_count to anon, authenticated;

-- =========================================================
-- INDEXES
-- =========================================================
create index if not exists idx_likes_song_id on likes(song_id);
create index if not exists idx_songs_singer_id on songs(singer_id);
create index if not exists idx_songs_play_count_desc on songs(play_count desc);
create index if not exists idx_favorites_user_id on favorites(user_id);

-- =========================================================
-- RPC: toggle_like(uuid) RETURNS int
-- Single-transaction like/unlike + like_count update. (File 9)
-- =========================================================
create or replace function public.toggle_like(p_song_id uuid)
returns int
language plpgsql
security definer
as $$
declare
  v_uid uuid := auth.uid();
  v_existing uuid;
  v_new_count int;
begin
  if v_uid is null then
    raise exception 'Authentication required';
  end if;

  select id into v_existing
  from likes
  where user_id = v_uid and song_id = p_song_id
  limit 1;

  if v_existing is not null then
    delete from likes where id = v_existing;
    update songs
      set like_count = greatest(0, like_count - 1)
      where id = p_song_id
      returning like_count into v_new_count;
  else
    insert into likes (user_id, song_id) values (v_uid, p_song_id);
    update songs
      set like_count = like_count + 1
      where id = p_song_id
      returning like_count into v_new_count;
  end if;

  return coalesce(v_new_count, 0);
end;
$$;

revoke all on function public.toggle_like(uuid) from public;
grant execute on function public.toggle_like(uuid) to authenticated;

-- Lock down the old raw increment/decrement RPCs if they still exist,
-- so the client can no longer bump like_count directly (File 9/52 test).
revoke all on function if exists increment_like_count(uuid) from public, anon, authenticated;
revoke all on function if exists decrement_like_count(uuid) from public, anon, authenticated;

-- =========================================================
-- RPC: increment_play_count(uuid) — server-side throttled (File 26)
-- =========================================================
create table if not exists play_count_log (
  user_id uuid not null,
  song_id uuid not null,
  played_at timestamptz not null default now(),
  primary key (user_id, song_id, played_at)
);

create or replace function public.increment_play_count(p_song_id uuid)
returns void
language plpgsql
security definer
as $$
declare
  v_uid uuid := auth.uid();
  v_last timestamptz;
begin
  if v_uid is null then
    raise exception 'Authentication required';
  end if;

  select max(played_at) into v_last
  from play_count_log
  where user_id = v_uid and song_id = p_song_id;

  if v_last is not null and now() - v_last < interval '30 seconds' then
    return; -- throttled, silently ignore
  end if;

  insert into play_count_log (user_id, song_id) values (v_uid, p_song_id);

  update songs
    set play_count = coalesce(play_count, 0) + 1
    where id = p_song_id;
end;
$$;

revoke all on function public.increment_play_count(uuid) from public;
grant execute on function public.increment_play_count(uuid) to authenticated;
