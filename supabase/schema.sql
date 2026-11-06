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
