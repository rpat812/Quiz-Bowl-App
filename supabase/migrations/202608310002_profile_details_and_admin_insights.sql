-- Private profile details, validated self-service updates, and admin reporting.

create table if not exists public.profile_details (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  email text,
  phone text,
  age smallint,
  gender text,
  updated_at timestamptz not null default now(),
  constraint profile_details_email_check check (email is null or email ~* '^[A-Z0-9._%+''-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'),
  constraint profile_details_phone_check check (phone is null or phone ~ '^\+?[0-9][0-9 ()-]{6,19}$'),
  constraint profile_details_age_check check (age is null or age between 13 and 120),
  constraint profile_details_gender_check check (gender is null or gender in ('woman','man','non_binary','prefer_not_to_say'))
);

alter table public.profile_details enable row level security;
drop policy if exists "users read own profile details" on public.profile_details;
create policy "users read own profile details" on public.profile_details for select to authenticated using (auth.uid() = user_id);
revoke all on public.profile_details from anon, authenticated;
grant select on public.profile_details to authenticated;

insert into public.profile_details(user_id,email)
select p.id, nullif(lower(trim(u.email)), '')
from public.profiles p join auth.users u on u.id=p.id
on conflict(user_id) do update set email=coalesce(public.profile_details.email,excluded.email);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path='' as $$
declare requested_username text;
begin
  requested_username:=lower(coalesce(new.raw_user_meta_data->>'username',split_part(new.email,'@',1)));
  requested_username:=regexp_replace(requested_username,'[^a-z0-9_]','','g');
  if char_length(requested_username)<3 then requested_username:='player';end if;
  requested_username:=left(requested_username,24);
  begin
    insert into public.profiles(id,username,display_name) values(new.id,requested_username,left(coalesce(nullif(new.raw_user_meta_data->>'display_name',''),requested_username),40));
  exception when unique_violation then
    requested_username:=left(requested_username,17)||'_'||substr(new.id::text,1,6);
    insert into public.profiles(id,username,display_name) values(new.id,requested_username,left(coalesce(nullif(new.raw_user_meta_data->>'display_name',''),requested_username),40));
  end;
  insert into public.profile_details(user_id,email) values(new.id,nullif(lower(trim(new.email)),'')) on conflict(user_id) do nothing;
  return new;
end $$;

create or replace function public.update_my_profile(
  p_display_name text,p_username text,p_email text,p_phone text,p_age integer,p_gender text
) returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); clean_name text:=trim(p_display_name); clean_username text:=lower(trim(p_username));
 clean_email text:=nullif(lower(trim(coalesce(p_email,''))), ''); clean_phone text:=nullif(trim(coalesce(p_phone,'')), '');
 clean_gender text:=nullif(trim(coalesce(p_gender,'')), '');
begin
 if uid is null then raise exception 'Authentication required';end if;
 if char_length(clean_name) not between 1 and 40 then raise exception 'Display name must be between 1 and 40 characters';end if;
 if clean_username !~ '^[a-z0-9_]{3,24}$' then raise exception 'Username must be 3-24 lowercase letters, numbers, or underscores';end if;
 if clean_email is not null and clean_email !~* '^[A-Z0-9._%+''-]+@[A-Z0-9.-]+\.[A-Z]{2,}$' then raise exception 'Enter a valid email address';end if;
 if clean_phone is not null and clean_phone !~ '^\+?[0-9][0-9 ()-]{6,19}$' then raise exception 'Enter a valid phone number';end if;
 if p_age is not null and p_age not between 13 and 120 then raise exception 'Age must be between 13 and 120';end if;
 if clean_gender is not null and clean_gender not in('woman','man','non_binary','prefer_not_to_say') then raise exception 'Select a valid gender option';end if;
 update public.profiles set display_name=clean_name,username=clean_username,updated_at=now() where id=uid;
 insert into public.profile_details(user_id,email,phone,age,gender,updated_at)
 values(uid,clean_email,clean_phone,p_age,clean_gender,now())
 on conflict(user_id) do update set email=excluded.email,phone=excluded.phone,age=excluded.age,gender=excluded.gender,updated_at=now();
 return jsonb_build_object('username',clean_username,'display_name',clean_name,'email',clean_email,'phone',clean_phone,'age',p_age,'gender',clean_gender);
exception when unique_violation then raise exception 'That username is already in use';
end $$;

create or replace function public.admin_profile_insights()
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare result jsonb;
begin
 if not public.has_admin_capability('overview.view') then raise exception 'Forbidden';end if;
 select jsonb_build_object(
  'completedProfiles',count(*) filter(where p.display_name<>'' and p.username<>'' and d.email is not null and d.phone is not null and d.age is not null and d.gender is not null),
  'incompleteProfiles',count(*) filter(where not(p.display_name<>'' and p.username<>'' and d.email is not null and d.phone is not null and d.age is not null and d.gender is not null)),
  'missingEmail',count(*) filter(where d.email is null),'missingPhone',count(*) filter(where d.phone is null),
  'genderDistribution',coalesce((select jsonb_agg(jsonb_build_object('label',coalesce(x.gender,'Not provided'),'count',x.total) order by x.total desc) from(select d2.gender,count(*) total from public.profiles p2 left join public.profile_details d2 on d2.user_id=p2.id group by d2.gender)x),'[]'::jsonb),
  'ageDistribution',coalesce((select jsonb_agg(jsonb_build_object('label',x.band,'count',x.total) order by x.sort_order) from(select case when d2.age is null then 'Not provided' when d2.age<18 then '13-17' when d2.age<25 then '18-24' when d2.age<35 then '25-34' when d2.age<50 then '35-49' else '50+' end band,case when d2.age is null then 6 when d2.age<18 then 1 when d2.age<25 then 2 when d2.age<35 then 3 when d2.age<50 then 4 else 5 end sort_order,count(*) total from public.profiles p2 left join public.profile_details d2 on d2.user_id=p2.id group by band,sort_order)x),'[]'::jsonb)
 ) into result from public.profiles p left join public.profile_details d on d.user_id=p.id;
 return result;
end $$;

create or replace function public.admin_list_users(
 p_search text default '',p_status text default '',p_active_within integer default null,p_sort text default 'created_at',p_order text default 'desc',p_page integer default 1,p_page_size integer default 25
) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare result jsonb;safe_page integer:=greatest(1,p_page);safe_size integer:=greatest(1,least(p_page_size,100));
begin
 if not public.has_admin_capability('users.view') then raise exception 'Forbidden';end if;
 with filtered as(select p.*,d.email,d.phone,d.age,d.gender,coalesce(st.sessions,0)sessions from public.profiles p left join public.profile_details d on d.user_id=p.id left join lateral(select count(*)sessions from public.practice_sessions s where s.user_id=p.id)st on true where(coalesce(p_search,'')='' or p.username ilike '%'||p_search||'%' or p.display_name ilike '%'||p_search||'%' or p.id::text=p_search or d.email ilike '%'||p_search||'%' or d.phone ilike '%'||p_search||'%')and(coalesce(p_status,'')='' or p.account_status=p_status)and(p_active_within is null or p.last_active_at>=now()-make_interval(days=>p_active_within))),
 ordered as(select *,count(*)over()total_rows from filtered order by case when p_sort='xp'and p_order='asc'then total_xp end asc,case when p_sort='xp'and p_order<>'asc'then total_xp end desc,case when p_sort='accuracy'and p_order='asc'then total_correct::numeric/nullif(total_answered,0)end asc nulls last,case when p_sort='accuracy'and p_order<>'asc'then total_correct::numeric/nullif(total_answered,0)end desc nulls last,case when p_sort='last_active'and p_order='asc'then last_active_at end asc nulls last,case when p_sort='last_active'and p_order<>'asc'then last_active_at end desc nulls last,case when p_sort='created_at'and p_order='asc'then created_at end asc,created_at desc limit safe_size offset(safe_page-1)*safe_size)
 select jsonb_build_object('data',coalesce(jsonb_agg(jsonb_build_object('id',id,'username',username,'displayName',display_name,'email',email,'phone',phone,'age',age,'gender',gender,'joinedAt',created_at,'lastActiveAt',last_active_at,'sessions',sessions,'answered',total_answered,'accuracy',coalesce(round(100.0*total_correct/nullif(total_answered,0),1),0),'xp',total_xp,'streak',current_streak,'status',account_status,'leaderboardEligible',leaderboard_eligible)),'[]'::jsonb),'pagination',jsonb_build_object('page',safe_page,'pageSize',safe_size,'total',coalesce(max(total_rows),0),'totalPages',ceil(coalesce(max(total_rows),0)::numeric/safe_size)))into result from ordered;
 return result;
end $$;

create or replace function public.admin_user_profile(p_user_id uuid)
returns jsonb language sql stable security definer set search_path='' as $$
 select case when public.has_admin_capability('users.view') then jsonb_build_object('email',d.email,'phone',d.phone,'age',d.age,'gender',d.gender,'complete',p.display_name<>''and p.username<>''and d.email is not null and d.phone is not null and d.age is not null and d.gender is not null) else null end from public.profiles p left join public.profile_details d on d.user_id=p.id where p.id=p_user_id
$$;

revoke all on function public.update_my_profile(text,text,text,text,integer,text),public.admin_profile_insights(),public.admin_user_profile(uuid) from public;
grant execute on function public.update_my_profile(text,text,text,text,integer,text) to authenticated;
grant execute on function public.admin_profile_insights(),public.admin_user_profile(uuid) to authenticated;
