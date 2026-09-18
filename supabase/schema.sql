-- CAB GCU Storage Room — Supabase schema
-- Run this once in the Supabase SQL editor (Project > SQL Editor > New query).

create table if not exists public.items (
  id text primary key,
  name text not null,
  cat integer,
  unit text,
  shelf integer,
  team text,
  notes text,
  contents text,
  emoji text,
  "out" jsonb,
  flag jsonb,
  log jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

-- keep updated_at current on every write
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists items_set_updated_at on public.items;
create trigger items_set_updated_at
  before update on public.items
  for each row execute function public.set_updated_at();

-- Row Level Security
-- The app has no real accounts (sign-in is just picking your name from the
-- roster), so access control mirrors that: anyone with the anon/public key
-- can read and write the shared inventory. Don't put secrets in this table.
alter table public.items enable row level security;

drop policy if exists "public read" on public.items;
create policy "public read" on public.items for select using (true);

drop policy if exists "public insert" on public.items;
create policy "public insert" on public.items for insert with check (true);

drop policy if exists "public update" on public.items;
create policy "public update" on public.items for update using (true);

drop policy if exists "public delete" on public.items;
create policy "public delete" on public.items for delete using (true);

-- Realtime: broadcast inserts/updates/deletes so every open tab stays in sync
alter publication supabase_realtime add table public.items;

-- App configuration (shelving units, shelf count, custom shelf names,
-- categories, issue-flag types) — admins edit this from the "Manage" page
-- and it syncs live to everyone, the same way items do. A single row
-- (id = 'app') holds the whole config blob.
create table if not exists public.config (
  id text primary key,
  value jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

drop trigger if exists config_set_updated_at on public.config;
create trigger config_set_updated_at
  before update on public.config
  for each row execute function public.set_updated_at();

alter table public.config enable row level security;

drop policy if exists "public read" on public.config;
create policy "public read" on public.config for select using (true);

drop policy if exists "public insert" on public.config;
create policy "public insert" on public.config for insert with check (true);

drop policy if exists "public update" on public.config;
create policy "public update" on public.config for update using (true);

drop policy if exists "public delete" on public.config;
create policy "public delete" on public.config for delete using (true);

alter publication supabase_realtime add table public.config;
