create or replace function public.ensure_current_profile_member(target_fund_id text)
returns table(fund_id text, member_id text, role text, member_count integer)
language plpgsql
security definer
set search_path = public
as $$
declare
  profile_record public.profiles%rowtype;
  resolved_member_id text;
  resolved_member_name text;
  resolved_member_code text;
begin
  if auth.uid() is null then
    raise exception 'Ban can dang nhap de tai quy.';
  end if;

  select p.*
  into profile_record
  from public.profiles p
  where p.user_id = auth.uid()
    and p.fund_id = target_fund_id
  for update;

  if not found then
    raise exception 'Tai khoan nay chua tham gia quy.';
  end if;

  resolved_member_id := profile_record.member_id;

  if resolved_member_id is null or not exists (
    select 1
    from public.fund_members fm
    where fm.id = resolved_member_id
      and fm.fund_id = target_fund_id
  ) then
    resolved_member_id := 'member_' || replace(gen_random_uuid()::text, '-', '');
    resolved_member_name := coalesce(
      nullif(profile_record.display_name, ''),
      nullif(split_part(profile_record.email, '@', 1), ''),
      case when profile_record.role = 'admin' then 'Admin' else 'Thanh vien' end
    );
    resolved_member_code := 'QAC' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10));

    insert into public.fund_members (id, fund_id, name, wallet, code)
    values (resolved_member_id, target_fund_id, resolved_member_name, null, resolved_member_code);

    update public.profiles p
    set member_id = resolved_member_id
    where p.user_id = auth.uid()
      and p.fund_id = target_fund_id;
  end if;

  return query
  select
    target_fund_id,
    resolved_member_id,
    profile_record.role,
    (
      select count(*)::integer
      from public.fund_members fm
      where fm.fund_id = target_fund_id
    );
end;
$$;

grant execute on function public.ensure_current_profile_member(text) to authenticated;
