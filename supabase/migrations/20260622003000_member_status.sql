alter table public.fund_members
  add column if not exists status text not null default 'active'
  check (status in ('active', 'inactive'));

create index if not exists fund_members_fund_status_idx
on public.fund_members(fund_id, status);

update public.fund_members
set status = 'active'
where status is null;
