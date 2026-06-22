create or replace function public.is_current_event_participant(target_event_id text, target_fund_id text)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.event_participants ep
    where ep.event_id = target_event_id
      and ep.member_id = public.current_profile_member_id(target_fund_id)
  )
$$;

create or replace function public.can_read_event_participant(target_event_id text, target_member_id text)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.events e
    where e.id = target_event_id
      and (
        public.is_fund_admin(e.fund_id)
        or target_member_id = public.current_profile_member_id(e.fund_id)
      )
  )
$$;

create or replace function public.can_admin_event_participant(target_event_id text)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.events e
    where e.id = target_event_id
      and public.is_fund_admin(e.fund_id)
  )
$$;

drop policy if exists "events_select_admin_or_participant" on public.events;
drop policy if exists "participants_select_admin_or_self" on public.event_participants;
drop policy if exists "participants_admin_write" on public.event_participants;

create policy "events_select_admin_or_participant"
on public.events
for select
using (
  public.is_fund_admin(fund_id)
  or public.is_current_event_participant(id, fund_id)
);

create policy "participants_select_admin_or_self"
on public.event_participants
for select
using (public.can_read_event_participant(event_id, member_id));

create policy "participants_admin_write"
on public.event_participants
for all
using (public.can_admin_event_participant(event_id))
with check (public.can_admin_event_participant(event_id));

grant execute on function public.is_current_event_participant(text, text) to authenticated;
grant execute on function public.can_read_event_participant(text, text) to authenticated;
grant execute on function public.can_admin_event_participant(text) to authenticated;
