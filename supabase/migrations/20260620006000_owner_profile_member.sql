create or replace function public.create_fund_for_current_user(fund_name text, display_name text)
returns table(fund_id text)
language plpgsql
security definer
set search_path = public
as $$
declare
  new_fund_id text;
  new_member_id text;
  user_email text;
  member_code text;
begin
  if auth.uid() is null then
    raise exception 'Bạn cần đăng nhập để tạo quỹ.';
  end if;

  user_email := coalesce(auth.jwt() ->> 'email', '');
  new_fund_id := 'fund_' || replace(gen_random_uuid()::text, '-', '');
  new_member_id := 'member_' || replace(gen_random_uuid()::text, '-', '');
  member_code := 'QAC' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10));

  insert into public.funds (id, name)
  values (new_fund_id, fund_name);

  insert into public.fund_members (id, fund_id, name, wallet, code)
  values (new_member_id, new_fund_id, display_name, null, member_code);

  insert into public.profiles (user_id, fund_id, member_id, role, display_name, email)
  values (auth.uid(), new_fund_id, new_member_id, 'admin', display_name, user_email);

  return query select new_fund_id;
end;
$$;

grant execute on function public.create_fund_for_current_user(text, text) to authenticated;

with missing_owner_members as (
  select
    p.user_id,
    p.fund_id,
    p.display_name,
    'member_' || replace(gen_random_uuid()::text, '-', '') as member_id,
    'QAC' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10)) as member_code
  from public.profiles p
  where p.role = 'admin'
    and p.member_id is null
)
insert into public.fund_members (id, fund_id, name, wallet, code)
select member_id, fund_id, display_name, null, member_code
from missing_owner_members;

with created_owner_members as (
  select distinct on (p.user_id, p.fund_id)
    p.user_id,
    p.fund_id,
    fm.id as member_id
  from public.profiles p
  join public.fund_members fm
    on fm.fund_id = p.fund_id
   and fm.name = p.display_name
  where p.role = 'admin'
    and p.member_id is null
  order by p.user_id, p.fund_id, fm.created_at desc
)
update public.profiles p
set member_id = created_owner_members.member_id
from created_owner_members
where p.user_id = created_owner_members.user_id
  and p.fund_id = created_owner_members.fund_id
  and p.role = 'admin'
  and p.member_id is null;
