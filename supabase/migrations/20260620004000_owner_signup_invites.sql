create extension if not exists pgcrypto;

create table if not exists public.fund_invites (
  id text primary key,
  fund_id text not null references public.funds(id) on delete cascade,
  invite_code text not null unique,
  member_id text references public.fund_members(id) on delete cascade,
  email text,
  status text not null default 'pending' check (status in ('pending', 'used', 'revoked')),
  created_by text,
  expires_at timestamptz,
  used_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  used_at timestamptz
);

create index if not exists fund_invites_fund_id_created_at_idx on public.fund_invites(fund_id, created_at desc);
create index if not exists fund_invites_code_idx on public.fund_invites(invite_code);

alter table public.fund_invites enable row level security;

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
    raise exception 'Bạn cần đăng nhập để tham gia quỹ.';
  end if;

  select *
  into invite_record
  from public.fund_invites
  where invite_code = invite_code_input
    and status = 'pending'
    and (expires_at is null or expires_at > now())
  for update;

  if not found then
    raise exception 'Mã mời không hợp lệ hoặc đã hết hạn.';
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
    update public.fund_members
    set name = coalesce(nullif(display_name, ''), name)
    where id = resolved_member_id;
  end if;

  insert into public.profiles (user_id, fund_id, member_id, role, display_name, email)
  values (auth.uid(), invite_record.fund_id, resolved_member_id, 'member', display_name, user_email);

  update public.fund_invites
  set status = 'used',
      used_by = auth.uid(),
      used_at = now()
  where id = invite_record.id;

  return query select invite_record.fund_id, resolved_member_id;
end;
$$;

grant execute on function public.create_fund_for_current_user(text, text) to authenticated;
grant execute on function public.accept_fund_invite(text, text) to authenticated;
