alter table public.ledger_entries
  drop constraint if exists ledger_entries_type_check;

alter table public.ledger_entries
  add constraint ledger_entries_type_check
  check (type in ('deposit', 'event-share', 'pending', 'balance-donation'));

drop function if exists public.get_fund_summary(text);

create function public.get_fund_summary(target_fund_id text)
returns table(
  summary_fund_id text,
  member_count integer,
  total_deposited numeric,
  total_spent numeric,
  total_balance numeric,
  donated_balance numeric,
  my_member_id text,
  my_deposited numeric,
  my_spent numeric,
  my_balance numeric,
  pending_count integer
)
language plpgsql
security definer
set search_path = public
stable
as $$
declare
  current_member_id text;
  current_is_admin boolean;
begin
  if auth.uid() is null then
    raise exception 'Ban can dang nhap de xem tong quan quy.';
  end if;

  if not public.is_fund_member(target_fund_id) then
    raise exception 'Tai khoan nay chua tham gia quy.';
  end if;

  current_member_id := public.current_profile_member_id(target_fund_id);
  current_is_admin := public.is_fund_admin(target_fund_id);

  return query
  with ledger_totals as (
    select
      coalesce(sum(le.amount) filter (where le.type = 'deposit'), 0)::numeric as deposited,
      coalesce(sum(le.amount) filter (where le.type = 'event-share'), 0)::numeric as spent,
      coalesce(sum(le.amount) filter (where le.type = 'balance-donation'), 0)::numeric as donated
    from public.ledger_entries le
    where le.fund_id = target_fund_id
  ),
  my_totals as (
    select
      coalesce(sum(le.amount) filter (where le.type = 'deposit'), 0)::numeric as deposited,
      coalesce(sum(le.amount) filter (where le.type in ('event-share', 'balance-donation')), 0)::numeric as spent
    from public.ledger_entries le
    where le.fund_id = target_fund_id
      and le.member_id = current_member_id
  )
  select
    target_fund_id,
    (
      select count(*)::integer
      from public.fund_members fm
      where fm.fund_id = target_fund_id
        and coalesce(fm.status, 'active') = 'active'
    ),
    ledger_totals.deposited,
    ledger_totals.spent,
    ledger_totals.deposited - ledger_totals.spent,
    ledger_totals.donated,
    current_member_id,
    my_totals.deposited,
    my_totals.spent,
    my_totals.deposited - my_totals.spent,
    (
      select count(*)::integer
      from public.deposit_requests dr
      where dr.fund_id = target_fund_id
        and dr.status = 'pending'
        and (current_is_admin or dr.member_id = current_member_id)
    )
  from ledger_totals, my_totals;
end;
$$;

grant execute on function public.get_fund_summary(text) to authenticated;
