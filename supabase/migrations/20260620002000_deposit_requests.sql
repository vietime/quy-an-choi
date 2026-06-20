create table if not exists public.deposit_requests (
  id text primary key,
  fund_id text not null references public.funds(id) on delete cascade,
  member_id text not null references public.fund_members(id) on delete cascade,
  amount bigint not null check (amount > 0),
  note text,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  reviewed_by text,
  ledger_entry_id text references public.ledger_entries(id) on delete set null,
  created_at timestamptz not null default now(),
  reviewed_at timestamptz
);

create index if not exists deposit_requests_fund_id_created_at_idx on public.deposit_requests(fund_id, created_at desc);
create index if not exists deposit_requests_member_id_idx on public.deposit_requests(member_id);

alter table public.deposit_requests enable row level security;
