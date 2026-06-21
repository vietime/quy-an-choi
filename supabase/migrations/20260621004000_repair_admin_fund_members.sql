with admin_profiles as (
  select
    p.user_id,
    p.fund_id,
    p.display_name,
    p.email,
    p.member_id
  from public.profiles p
  where p.role = 'admin'
    and not exists (
      select 1
      from public.fund_members fm
      where fm.id = p.member_id
        and fm.fund_id = p.fund_id
    )
),
new_admin_members as (
  select
    ap.user_id,
    ap.fund_id,
    'member_' || replace(gen_random_uuid()::text, '-', '') as member_id,
    coalesce(nullif(ap.display_name, ''), nullif(split_part(ap.email, '@', 1), ''), 'Admin') as member_name,
    'QAC' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10)) as member_code
  from admin_profiles ap
),
inserted_members as (
  insert into public.fund_members (id, fund_id, name, wallet, code)
  select member_id, fund_id, member_name, null, member_code
  from new_admin_members
  on conflict (id) do nothing
  returning id, fund_id
)
update public.profiles p
set member_id = nam.member_id
from new_admin_members nam
join inserted_members im
  on im.id = nam.member_id
 and im.fund_id = nam.fund_id
where p.user_id = nam.user_id
  and p.fund_id = nam.fund_id
  and p.role = 'admin';
