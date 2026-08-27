do $$
declare
  target_user_id uuid;
begin
  select id
  into target_user_id
  from auth.users
  where encode(extensions.digest(lower(email), 'sha256'), 'hex') =
    'f87841353636cb568be2b70a3789d6361d93eccc8e6b59483700d894ec119416';

  if target_user_id is null then
    raise exception 'The requested super admin account does not exist';
  end if;

  insert into public.admin_user_roles (user_id, role_id)
  select target_user_id, role.id
  from public.admin_roles role
  where role.key = 'super_admin'
  on conflict (user_id, role_id) do nothing;
end;
$$;
