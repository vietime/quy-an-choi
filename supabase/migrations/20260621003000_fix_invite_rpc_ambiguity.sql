create or replace function public.accept_fund_invite(invite_code_input text, display_name text)
returns table(fund_id text, member_id text)
language plpgsql
security definer
set search_path = public
as $$
declare
  invite_record public.fund_invites%rowtype;
  resolved_member_id text;
  user_email text;
begin
  if auth.uid() is null then
    raise exception 'Ban can dang nhap de tham gia quy.';
  end if;

  select fi.*
  into invite_record
  from public.fund_invites fi
  where fi.invite_code = invite_code_input
    and fi.status = 'pending'
    and (fi.expires_at is null or fi.expires_at > now())
  for update;

  if not found then
    raise exception 'Ma moi khong hop le hoac da het han.';
  end if;

  if exists (
    select 1
    from public.profiles p
    where p.user_id = auth.uid()
      and p.fund_id = invite_record.fund_id
  ) then
    raise exception 'Tai khoan nay da tham gia quy nay.';
  end if;

  user_email := coalesce(auth.jwt() ->> 'email', '');
  resolved_member_id := invite_record.member_id;

  if resolved_member_id is null then
    resolved_member_id := 'member_' || replace(gen_random_uuid()::text, '-', '');
    insert into public.fund_members (id, fund_id, name, wallet, code)
    values (
      resolved_member_id,
      invite_record.fund_id,
      display_name,
      null,
      'QAC' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10))
    );
  else
    update public.fund_members fm
    set name = coalesce(nullif(display_name, ''), fm.name)
    where fm.id = resolved_member_id;
  end if;

  insert into public.profiles (user_id, fund_id, member_id, role, display_name, email)
  values (auth.uid(), invite_record.fund_id, resolved_member_id, 'member', display_name, user_email);

  update public.fund_invites fi
  set status = 'used',
      used_by = auth.uid(),
      used_at = now()
  where fi.id = invite_record.id;

  return query select invite_record.fund_id, resolved_member_id;
end;
$$;

grant execute on function public.accept_fund_invite(text, text) to authenticated;
