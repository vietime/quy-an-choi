create table if not exists public.funds (
  id text primary key,
  name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.fund_members (
  id text primary key,
  fund_id text not null references public.funds(id) on delete cascade,
  name text not null,
  wallet text,
  code text not null unique,
  status text not null default 'active' check (status in ('active', 'paused', 'left')),
  created_at timestamptz not null default now()
);

create table if not exists public.ledger_entries (
  id text primary key,
  fund_id text not null references public.funds(id) on delete cascade,
  member_id text references public.fund_members(id) on delete set null,
  type text not null check (type in ('deposit', 'event-share', 'pending')),
  amount bigint not null check (amount >= 0),
  note text,
  event_id text,
  event_name text,
  created_at timestamptz not null default now()
);

create table if not exists public.events (
  id text primary key,
  fund_id text not null references public.funds(id) on delete cascade,
  name text not null,
  total_amount bigint not null check (total_amount >= 0),
  guest_amount bigint not null default 0 check (guest_amount >= 0),
  guest_owner_member_id text references public.fund_members(id) on delete set null,
  split_mode text not null check (split_mode in ('equal', 'owner-pays-guest')),
  created_by text,
  created_at timestamptz not null default now()
);

alter table public.ledger_entries
  add column if not exists event_id text;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'ledger_entries_event_id_fkey'
  ) then
    alter table public.ledger_entries
      add constraint ledger_entries_event_id_fkey
      foreign key (event_id) references public.events(id) on delete set null;
  end if;
end $$;

create table if not exists public.event_participants (
  event_id text not null references public.events(id) on delete cascade,
  member_id text not null references public.fund_members(id) on delete cascade,
  charged_amount bigint not null check (charged_amount >= 0),
  note text,
  primary key (event_id, member_id)
);

create index if not exists fund_members_fund_id_idx on public.fund_members(fund_id);
create index if not exists ledger_entries_fund_id_created_at_idx on public.ledger_entries(fund_id, created_at desc);
create index if not exists ledger_entries_member_id_idx on public.ledger_entries(member_id);
create index if not exists events_fund_id_created_at_idx on public.events(fund_id, created_at desc);

alter table public.funds enable row level security;
alter table public.fund_members enable row level security;
alter table public.ledger_entries enable row level security;
alter table public.events enable row level security;
alter table public.event_participants enable row level security;

-- Prototype policy: cho phép anon key đọc/ghi để GitHub Pages demo hoạt động ngay.
-- Bản thật phải thay bằng Supabase Auth + policy theo vai trò admin/member.
drop policy if exists "prototype_read_funds" on public.funds;
drop policy if exists "prototype_write_funds" on public.funds;
drop policy if exists "prototype_read_members" on public.fund_members;
drop policy if exists "prototype_write_members" on public.fund_members;
drop policy if exists "prototype_read_ledger" on public.ledger_entries;
drop policy if exists "prototype_write_ledger" on public.ledger_entries;
drop policy if exists "prototype_read_events" on public.events;
drop policy if exists "prototype_write_events" on public.events;
drop policy if exists "prototype_read_event_participants" on public.event_participants;
drop policy if exists "prototype_write_event_participants" on public.event_participants;

create policy "prototype_read_funds" on public.funds for select using (true);
create policy "prototype_write_funds" on public.funds for all using (true) with check (true);

create policy "prototype_read_members" on public.fund_members for select using (true);
create policy "prototype_write_members" on public.fund_members for all using (true) with check (true);

create policy "prototype_read_ledger" on public.ledger_entries for select using (true);
create policy "prototype_write_ledger" on public.ledger_entries for all using (true) with check (true);

create policy "prototype_read_events" on public.events for select using (true);
create policy "prototype_write_events" on public.events for all using (true) with check (true);

create policy "prototype_read_event_participants" on public.event_participants for select using (true);
create policy "prototype_write_event_participants" on public.event_participants for all using (true) with check (true);
