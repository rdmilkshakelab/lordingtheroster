-- Lording the Roster: shared community suggestions and one-vote-per-browser voting.
-- Run this in Supabase SQL Editor. Use only the anon/publishable key in the site.
create table if not exists public.suggestions (
  id uuid primary key default gen_random_uuid(),
  hero text not null,
  display_name text not null default 'Anonymous',
  reason text not null default '',
  status text not null default 'approved' check (status in ('pending','approved','rejected','completed')),
  votes integer not null default 0 check (votes >= 0),
  created_at timestamptz not null default now()
);
alter table public.suggestions enable row level security;
grant select, insert on public.suggestions to anon, authenticated;
drop policy if exists "Anyone can read approved suggestions" on public.suggestions;
create policy "Anyone can read approved suggestions"
on public.suggestions for select to anon, authenticated
using (status in ('approved','completed'));
drop policy if exists "Anyone can submit a suggestion" on public.suggestions;
create policy "Anyone can submit a suggestion"
on public.suggestions for insert to anon, authenticated
with check (
  status = 'approved'
  and length(hero) between 1 and 80
  and length(display_name) <= 32
  and length(reason) <= 240
);
-- Store vote identities separately. The unique constraint prevents the same
-- browser identity from voting twice for the same suggestion.
create table if not exists public.suggestion_votes (
  suggestion_id uuid not null references public.suggestions(id) on delete cascade,
  voter_id uuid not null,
  created_at timestamptz not null default now(),
  primary key (suggestion_id, voter_id)
);
alter table public.suggestion_votes enable row level security;
revoke all on public.suggestion_votes from anon, authenticated;
create or replace function public.cast_suggestion_vote(p_suggestion_id uuid, p_voter_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare inserted_count integer;
begin
  if not exists (select 1 from public.suggestions where id = p_suggestion_id and status = 'approved') then
    return false;
  end if;
  insert into public.suggestion_votes(suggestion_id, voter_id)
  values (p_suggestion_id, p_voter_id)
  on conflict do nothing;
  get diagnostics inserted_count = row_count;
  if inserted_count = 0 then return false; end if;
  update public.suggestions set votes = votes + 1 where id = p_suggestion_id;
  return true;
end;
$$;
revoke all on function public.cast_suggestion_vote(uuid, uuid) from public;
grant execute on function public.cast_suggestion_vote(uuid, uuid) to anon, authenticated;

-- Admin accounts and shared hero progress.
-- After creating your Supabase Auth user, copy that user's UUID from
-- Authentication -> Users, then run:
-- insert into public.ltr_admins(user_id) values ('YOUR-AUTH-USER-UUID');
-- Only add your own trusted account. Do not expose the service-role key.
create table if not exists public.ltr_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.ltr_admins enable row level security;
revoke all on public.ltr_admins from anon, authenticated;
create or replace function public.ltr_is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists(select 1 from public.ltr_admins where user_id = auth.uid());
$$;
revoke all on function public.ltr_is_admin() from public;
grant execute on function public.ltr_is_admin() to authenticated;

create table if not exists public.hero_progress (
  hero text primary key,
  status text not null default 'Not started' check (status in ('Not started','In Progress','Lord')),
  level integer not null default 0 check (level >= 0 and level <= 100),
  episode text not null default '',
  video_url text not null default '',
  notes text not null default '',
  updated_at timestamptz not null default now()
);
alter table public.hero_progress enable row level security;
grant select on public.hero_progress to anon, authenticated;
grant insert, update on public.hero_progress to authenticated;
drop policy if exists "Anyone can read hero progress" on public.hero_progress;
create policy "Anyone can read hero progress"
on public.hero_progress for select to anon, authenticated using (true);
drop policy if exists "Admins with MFA can insert hero progress" on public.hero_progress;
create policy "Admins with MFA can insert hero progress"
on public.hero_progress for insert to authenticated
with check (public.ltr_is_admin() and (auth.jwt() ->> 'aal') = 'aal2');
drop policy if exists "Admins with MFA can update hero progress" on public.hero_progress;
create policy "Admins with MFA can update hero progress"
on public.hero_progress for update to authenticated
using (public.ltr_is_admin() and (auth.jwt() ->> 'aal') = 'aal2')
with check (public.ltr_is_admin() and (auth.jwt() ->> 'aal') = 'aal2');


-- Site-wide admin permissions, moderation and current challenge.
-- Lording the Roster: secure site-wide administration upgrade.
-- Run this once in the Supabase SQL Editor after the original schema.sql.
-- All destructive and moderation actions require an allow-listed admin at MFA aal2.

create table if not exists public.site_settings (
  id boolean primary key default true check (id = true),
  current_hero text not null default 'Psylocke',
  updated_at timestamptz not null default now()
);
insert into public.site_settings(id,current_hero)
values (true,'Psylocke')
on conflict (id) do nothing;
alter table public.site_settings enable row level security;
grant select on public.site_settings to anon, authenticated;
grant insert, update, delete on public.site_settings to authenticated;
drop policy if exists "Anyone can read site settings" on public.site_settings;
create policy "Anyone can read site settings"
on public.site_settings for select to anon, authenticated using (true);
drop policy if exists "Admins with MFA can manage site settings" on public.site_settings;
create policy "Admins with MFA can manage site settings"
on public.site_settings for all to authenticated
using (public.ltr_is_admin() and (auth.jwt() ->> 'aal') = 'aal2')
with check (public.ltr_is_admin() and (auth.jwt() ->> 'aal') = 'aal2');

-- Admins can inspect and moderate every suggestion, including pending/rejected items.
grant update, delete on public.suggestions to authenticated;
drop policy if exists "Admins with MFA can read all suggestions" on public.suggestions;
create policy "Admins with MFA can read all suggestions"
on public.suggestions for select to authenticated
using (public.ltr_is_admin() and (auth.jwt() ->> 'aal') = 'aal2');
drop policy if exists "Admins with MFA can update suggestions" on public.suggestions;
create policy "Admins with MFA can update suggestions"
on public.suggestions for update to authenticated
using (public.ltr_is_admin() and (auth.jwt() ->> 'aal') = 'aal2')
with check (public.ltr_is_admin() and (auth.jwt() ->> 'aal') = 'aal2');
drop policy if exists "Admins with MFA can delete suggestions" on public.suggestions;
create policy "Admins with MFA can delete suggestions"
on public.suggestions for delete to authenticated
using (public.ltr_is_admin() and (auth.jwt() ->> 'aal') = 'aal2');

-- Votes are private to administrators; admins may inspect and delete individual votes.
grant select, delete on public.suggestion_votes to authenticated;
drop policy if exists "Admins with MFA can read votes" on public.suggestion_votes;
create policy "Admins with MFA can read votes"
on public.suggestion_votes for select to authenticated
using (public.ltr_is_admin() and (auth.jwt() ->> 'aal') = 'aal2');
drop policy if exists "Admins with MFA can delete votes" on public.suggestion_votes;
create policy "Admins with MFA can delete votes"
on public.suggestion_votes for delete to authenticated
using (public.ltr_is_admin() and (auth.jwt() ->> 'aal') = 'aal2');

-- Keep the public vote counter correct when an admin removes a vote.
create or replace function public.ltr_decrement_vote_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.suggestions
  set votes = greatest(votes - 1, 0)
  where id = old.suggestion_id;
  return old;
end;
$$;
drop trigger if exists ltr_vote_delete_counter on public.suggestion_votes;
create trigger ltr_vote_delete_counter
after delete on public.suggestion_votes
for each row execute function public.ltr_decrement_vote_count();

-- Admins can also remove a corrupted hero-progress record or reset all shared progress.
grant delete on public.hero_progress to authenticated;
drop policy if exists "Admins with MFA can delete hero progress" on public.hero_progress;
create policy "Admins with MFA can delete hero progress"
on public.hero_progress for delete to authenticated
using (public.ltr_is_admin() and (auth.jwt() ->> 'aal') = 'aal2');
