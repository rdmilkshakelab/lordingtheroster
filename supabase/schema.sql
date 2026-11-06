-- Lording the Roster: shared community suggestions.
-- Run this in Supabase SQL Editor. The public anon key is safe to use in the
-- static website only after these RLS policies are enabled.
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
create policy "Anyone can read approved suggestions"
on public.suggestions for select to anon, authenticated
using (status in ('approved','completed'));
create policy "Anyone can submit a suggestion"
on public.suggestions for insert to anon, authenticated
with check (
  status = 'approved'
  and length(hero) between 1 and 80
  and length(display_name) <= 32
  and length(reason) <= 240
);
-- NOTE: this first public board supports submissions and reading. Public voting
-- is intentionally not enabled by incrementing votes directly, because that
-- would let visitors manipulate totals. A secure vote RPC / rate-limit layer
-- will be added before enabling shared voting.
