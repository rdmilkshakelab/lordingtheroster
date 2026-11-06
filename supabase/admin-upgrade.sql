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
