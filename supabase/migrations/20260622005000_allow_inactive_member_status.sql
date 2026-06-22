alter table public.fund_members
  drop constraint if exists fund_members_status_check;

alter table public.fund_members
  add constraint fund_members_status_check
  check (status in ('active', 'inactive', 'paused', 'left'));
