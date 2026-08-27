alter table public.profiles add column if not exists account_status text not null default 'active';
alter table public.profiles add column if not exists last_active_at timestamptz;
alter table public.profiles add column if not exists leaderboard_eligible boolean not null default true;
alter table public.questions add column if not exists content_status text not null default 'published';
alter table public.questions add column if not exists created_at timestamptz not null default now();
alter table public.questions add column if not exists updated_at timestamptz not null default now();

do $$ begin
  if not exists (select 1 from pg_constraint where conname = 'profiles_account_status_check') then
    alter table public.profiles add constraint profiles_account_status_check
      check (account_status in ('active', 'suspended'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'questions_content_status_check') then
    alter table public.questions add constraint questions_content_status_check
      check (content_status in ('draft', 'published', 'unpublished', 'archived', 'in_review'));
  end if;
end $$;

update public.questions set content_status = case when published then 'published' else 'unpublished' end;
update public.profiles p set last_active_at = coalesce(
  (select max(s.completed_at) from public.practice_sessions s where s.user_id = p.id),
  p.updated_at,
  p.created_at
) where last_active_at is null;

create table if not exists public.admin_roles (
  id uuid primary key default gen_random_uuid(),
  key text unique not null,
  name text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.admin_role_permissions (
  role_id uuid not null references public.admin_roles(id) on delete cascade,
  capability text not null,
  primary key (role_id, capability)
);

create table if not exists public.admin_user_roles (
  user_id uuid not null references public.profiles(id) on delete cascade,
  role_id uuid not null references public.admin_roles(id) on delete cascade,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  primary key (user_id, role_id)
);

create table if not exists public.admin_audit_logs (
  id bigint generated always as identity primary key,
  admin_user_id uuid not null references public.profiles(id),
  action text not null,
  resource_type text not null,
  resource_id text,
  target_user_id uuid references public.profiles(id),
  before_data jsonb,
  after_data jsonb,
  metadata jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.admin_settings (
  key text primary key,
  value jsonb not null,
  description text not null,
  updated_by uuid references public.profiles(id),
  updated_at timestamptz not null default now()
);

insert into public.admin_roles (key, name) values
  ('super_admin', 'Super Admin'),
  ('content_admin', 'Content Admin'),
  ('support_admin', 'Support Admin')
on conflict (key) do update set name = excluded.name;

insert into public.admin_role_permissions (role_id, capability)
select role.id, capability
from public.admin_roles role
cross join lateral unnest(case role.key
  when 'super_admin' then array[
    'overview.view','users.view','users.email','users.manage','leaderboards.view',
    'questions.view','questions.manage','settings.view','settings.manage','admins.manage','audit.view'
  ]
  when 'content_admin' then array[
    'overview.view','leaderboards.view','questions.view','questions.manage','audit.view'
  ]
  else array['overview.view','users.view','users.email','leaderboards.view']
end) capability
on conflict do nothing;

insert into public.admin_settings (key, value, description) values
  ('leaderboard_enabled', 'true', 'Show public leaderboards'),
  ('daily_question_count', '10', 'Questions in the daily practice set'),
  ('maintenance_banner', '""', 'Optional maintenance message')
on conflict (key) do nothing;

alter table public.admin_roles enable row level security;
alter table public.admin_role_permissions enable row level security;
alter table public.admin_user_roles enable row level security;
alter table public.admin_audit_logs enable row level security;
alter table public.admin_settings enable row level security;

revoke all on public.admin_roles, public.admin_role_permissions, public.admin_user_roles,
  public.admin_audit_logs, public.admin_settings from anon, authenticated;

create index if not exists profiles_admin_created_idx on public.profiles(created_at desc);
create index if not exists profiles_admin_active_idx on public.profiles(last_active_at desc);
create index if not exists profiles_admin_xp_idx on public.profiles(total_xp desc);
create index if not exists practice_sessions_admin_user_idx on public.practice_sessions(user_id, completed_at desc);
create index if not exists session_answers_admin_question_idx on public.session_answers(question_id, is_correct);
create index if not exists admin_audit_created_idx on public.admin_audit_logs(created_at desc);

create or replace function public.has_admin_capability(requested_capability text)
returns boolean language sql stable security definer set search_path = '' as $$
  select auth.uid() is not null and exists (
    select 1
    from public.admin_user_roles assignment
    join public.admin_role_permissions permission on permission.role_id = assignment.role_id
    where assignment.user_id = auth.uid() and permission.capability = requested_capability
  );
$$;

create or replace function public.admin_current_access()
returns jsonb language sql stable security definer set search_path = '' as $$
  select case when auth.uid() is null then null else jsonb_build_object(
    'userId', profile.id,
    'username', profile.username,
    'displayName', profile.display_name,
    'roles', coalesce((select jsonb_agg(distinct role.key) from public.admin_user_roles a join public.admin_roles role on role.id = a.role_id where a.user_id = profile.id), '[]'::jsonb),
    'capabilities', coalesce((select jsonb_agg(distinct permission.capability) from public.admin_user_roles a join public.admin_role_permissions permission on permission.role_id = a.role_id where a.user_id = profile.id), '[]'::jsonb)
  ) end
  from public.profiles profile where profile.id = auth.uid()
    and exists (select 1 from public.admin_user_roles a where a.user_id = profile.id);
$$;

create or replace function public.admin_overview(p_from date default current_date - 29, p_to date default current_date)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare result jsonb;
begin
  if not public.has_admin_capability('overview.view') then raise exception 'Forbidden'; end if;
  select jsonb_build_object(
    'dau', (select count(distinct s.user_id) from public.practice_sessions s where s.completed_at >= current_date),
    'mau', (select count(distinct s.user_id) from public.practice_sessions s where s.completed_at >= now() - interval '30 days'),
    'newUsers', (select count(*) from public.profiles p where p.created_at::date between p_from and p_to),
    'sessions', (select count(*) from public.practice_sessions s where s.completed_at::date between p_from and p_to),
    'questionsAnswered', (select coalesce(sum(s.question_count), 0) from public.practice_sessions s where s.completed_at::date between p_from and p_to),
    'accuracy', (select coalesce(round(100.0 * sum(s.correct_count) / nullif(sum(s.question_count), 0), 1), 0) from public.practice_sessions s where s.completed_at::date between p_from and p_to),
    'completionRate', 100,
    'totalUsers', (select count(*) from public.profiles),
    'publishedQuestions', (select count(*) from public.questions q where q.published),
    'suspendedUsers', (select count(*) from public.profiles p where p.account_status = 'suspended'),
    'trend', coalesce((select jsonb_agg(row_to_json(day_rows) order by day_rows.day) from (
      select days.day::date as day,
        count(distinct s.user_id) as active_users,
        count(s.id) as sessions
      from generate_series(p_from, p_to, interval '1 day') days(day)
      left join public.practice_sessions s on s.completed_at::date = days.day::date
      group by days.day
    ) day_rows), '[]'::jsonb),
    'categories', coalesce((select jsonb_agg(row_to_json(category_rows) order by category_rows.answers desc) from (
      select coalesce(q.category, 'Uncategorized') as category, count(sa.id) as answers,
        round(100.0 * count(*) filter (where sa.is_correct) / nullif(count(sa.id), 0), 1) as accuracy
      from public.session_answers sa join public.questions q on q.id = sa.question_id
      join public.practice_sessions s on s.id = sa.session_id
      where s.completed_at::date between p_from and p_to
      group by q.category limit 8
    ) category_rows), '[]'::jsonb)
  ) into result;
  return result;
end;
$$;

create or replace function public.admin_list_users(
  p_search text default '', p_status text default '', p_active_within integer default null,
  p_sort text default 'created_at', p_order text default 'desc', p_page integer default 1, p_page_size integer default 25
) returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare result jsonb; safe_page integer := greatest(1, p_page); safe_size integer := greatest(1, least(p_page_size, 100));
begin
  if not public.has_admin_capability('users.view') then raise exception 'Forbidden'; end if;
  with filtered as (
    select p.*, u.email, coalesce(session_totals.sessions, 0) sessions
    from public.profiles p
    left join auth.users u on u.id = p.id
    left join lateral (select count(*) sessions from public.practice_sessions s where s.user_id = p.id) session_totals on true
    where (coalesce(p_search, '') = '' or p.username ilike '%' || p_search || '%' or p.display_name ilike '%' || p_search || '%'
      or p.id::text = p_search or (public.has_admin_capability('users.email') and u.email ilike '%' || p_search || '%'))
      and (coalesce(p_status, '') = '' or p.account_status = p_status)
      and (p_active_within is null or p.last_active_at >= now() - make_interval(days => p_active_within))
  ), ordered as (
    select *, count(*) over() total_rows from filtered
    order by
      case when p_sort = 'xp' and p_order = 'asc' then total_xp end asc,
      case when p_sort = 'xp' and p_order <> 'asc' then total_xp end desc,
      case when p_sort = 'accuracy' and p_order = 'asc' then total_correct::numeric / nullif(total_answered,0) end asc nulls last,
      case when p_sort = 'accuracy' and p_order <> 'asc' then total_correct::numeric / nullif(total_answered,0) end desc nulls last,
      case when p_sort = 'last_active' and p_order = 'asc' then last_active_at end asc nulls last,
      case when p_sort = 'last_active' and p_order <> 'asc' then last_active_at end desc nulls last,
      case when p_sort = 'created_at' and p_order = 'asc' then created_at end asc,
      created_at desc
    limit safe_size offset (safe_page - 1) * safe_size
  )
  select jsonb_build_object(
    'data', coalesce(jsonb_agg(jsonb_build_object(
      'id', id, 'username', username, 'displayName', display_name,
      'email', case when public.has_admin_capability('users.email') then email else null end,
      'joinedAt', created_at, 'lastActiveAt', last_active_at, 'sessions', sessions,
      'answered', total_answered, 'accuracy', coalesce(round(100.0 * total_correct / nullif(total_answered,0),1),0),
      'xp', total_xp, 'streak', current_streak, 'status', account_status,
      'leaderboardEligible', leaderboard_eligible
    )), '[]'::jsonb),
    'pagination', jsonb_build_object('page', safe_page, 'pageSize', safe_size,
      'total', coalesce(max(total_rows),0), 'totalPages', ceil(coalesce(max(total_rows),0)::numeric / safe_size))
  ) into result from ordered;
  return result;
end;
$$;

create or replace function public.admin_user_detail(p_user_id uuid)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare result jsonb;
begin
  if not public.has_admin_capability('users.view') then raise exception 'Forbidden'; end if;
  select jsonb_build_object(
    'profile', jsonb_build_object('id', p.id, 'username', p.username, 'displayName', p.display_name,
      'email', case when public.has_admin_capability('users.email') then u.email else null end,
      'joinedAt', p.created_at, 'lastActiveAt', p.last_active_at, 'status', p.account_status,
      'leaderboardEligible', p.leaderboard_eligible, 'xp', p.total_xp, 'streak', p.current_streak,
      'longestStreak', p.longest_streak, 'answered', p.total_answered, 'correct', p.total_correct,
      'accuracy', coalesce(round(100.0 * p.total_correct / nullif(p.total_answered,0),1),0),
      'sessions', (select count(*) from public.practice_sessions s where s.user_id = p.id)),
    'attempts', coalesce((select jsonb_agg(jsonb_build_object('id', s.id, 'completedAt', s.completed_at,
      'type', s.session_type, 'category', s.category, 'questions', s.question_count, 'correct', s.correct_count,
      'accuracy', round(100.0 * s.correct_count / nullif(s.question_count,0),1), 'xp', s.xp_earned) order by s.completed_at desc)
      from (select * from public.practice_sessions where user_id = p.id order by completed_at desc limit 25) s), '[]'::jsonb),
    'categories', coalesce((select jsonb_agg(row_to_json(c) order by c.accuracy asc) from (
      select coalesce(q.category,'Uncategorized') category, count(sa.id) attempts,
        count(*) filter (where sa.is_correct) correct,
        round(100.0 * count(*) filter (where sa.is_correct) / nullif(count(sa.id),0),1) accuracy,
        count(sa.id) >= 10 sufficient_sample
      from public.session_answers sa join public.practice_sessions s on s.id = sa.session_id
      join public.questions q on q.id = sa.question_id where s.user_id = p.id group by q.category
    ) c), '[]'::jsonb),
    'activity', coalesce((select jsonb_agg(jsonb_build_object('at', s.completed_at, 'type', 'session.completed',
      'description', concat('Completed ', s.question_count, ' questions and earned ', s.xp_earned, ' XP')) order by s.completed_at desc)
      from (select * from public.practice_sessions where user_id = p.id order by completed_at desc limit 20) s), '[]'::jsonb)
  ) into result from public.profiles p left join auth.users u on u.id = p.id where p.id = p_user_id;
  return result;
end;
$$;

create or replace function public.admin_leaderboard(
  p_period text default 'weekly', p_category text default '', p_from date default null, p_to date default null,
  p_search text default '', p_page integer default 1, p_page_size integer default 50
) returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare result jsonb; start_at timestamptz; end_at timestamptz := coalesce(p_to::timestamptz + interval '1 day', now() + interval '1 day');
  safe_page integer := greatest(1,p_page); safe_size integer := greatest(1,least(p_page_size,100));
begin
  if not public.has_admin_capability('leaderboards.view') then raise exception 'Forbidden'; end if;
  start_at := case p_period when 'weekly' then date_trunc('week',now()) when 'monthly' then date_trunc('month',now())
    when 'custom' then coalesce(p_from::timestamptz, now() - interval '30 days') else '1970-01-01'::timestamptz end;
  with scores as (
    select p.id, p.username, p.display_name, p.current_streak, p.last_active_at, p.account_status, p.leaderboard_eligible,
      coalesce(sum(s.xp_earned),0)::bigint xp, coalesce(sum(s.question_count),0)::bigint questions,
      coalesce(sum(s.correct_count),0)::bigint correct, count(s.id)::bigint sessions
    from public.profiles p left join public.practice_sessions s on s.user_id = p.id and s.completed_at >= start_at and s.completed_at < end_at
      and (coalesce(p_category,'') = '' or s.category = p_category)
    where coalesce(p_search,'') = '' or p.username ilike '%'||p_search||'%' or p.display_name ilike '%'||p_search||'%'
    group by p.id
  ), ranked as (
    select row_number() over(order by xp desc, correct desc, id) rank, *, count(*) over() total_rows from scores
  ), page_rows as (select * from ranked order by rank limit safe_size offset (safe_page-1)*safe_size)
  select jsonb_build_object('data', coalesce(jsonb_agg(jsonb_build_object('rank',rank,'id',id,'username',username,
    'displayName',display_name,'xp',xp,'questions',questions,'accuracy',coalesce(round(100.0*correct/nullif(questions,0),1),0),
    'sessions',sessions,'streak',current_streak,'lastActiveAt',last_active_at,'status',account_status,
    'eligible',leaderboard_eligible) order by rank),'[]'::jsonb), 'pagination', jsonb_build_object('page',safe_page,
    'pageSize',safe_size,'total',coalesce(max(total_rows),0),'totalPages',ceil(coalesce(max(total_rows),0)::numeric/safe_size)))
  into result from page_rows;
  return result;
end;
$$;

create or replace function public.admin_question_analytics(p_search text default '', p_category text default '', p_sort text default 'missed', p_page integer default 1, p_page_size integer default 50)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare result jsonb; safe_page integer := greatest(1,p_page); safe_size integer := greatest(1,least(p_page_size,100));
begin
  if not public.has_admin_capability('questions.view') then raise exception 'Forbidden'; end if;
  with stats as (
    select q.id, q.question, q.category, q.subcategory, q.difficulty, q.question_type, q.content_status, q.published,
      count(sa.id)::bigint attempts, count(*) filter(where sa.is_correct)::bigint correct,
      count(*) filter(where not sa.is_correct)::bigint incorrect, count(distinct s.user_id)::bigint unique_users,
      max(s.completed_at) last_served_at
    from public.questions q left join public.session_answers sa on sa.question_id=q.id
    left join public.practice_sessions s on s.id=sa.session_id
    where (coalesce(p_search,'')='' or q.id ilike '%'||p_search||'%' or q.question ilike '%'||p_search||'%')
      and (coalesce(p_category,'')='' or q.category=p_category)
    group by q.id
  ), ranked as (
    select *, coalesce(round(100.0*correct/nullif(attempts,0),1),0) accuracy, count(*) over() total_rows from stats
    order by case when p_sort='easiest' then correct::numeric/nullif(attempts,0) end desc nulls last,
      case when p_sort in ('hardest','missed') then correct::numeric/nullif(attempts,0) end asc nulls last,
      attempts desc, id
    limit safe_size offset (safe_page-1)*safe_size
  )
  select jsonb_build_object('data',coalesce(jsonb_agg(jsonb_build_object('id',id,'question',question,'category',category,
    'subcategory',subcategory,'difficulty',difficulty,'type',question_type,'status',content_status,'published',published,
    'acceptedAnswer',(select accepted_answer from public.questions source_question where source_question.id=ranked.id),
    'explanation',(select explanation from public.questions source_question where source_question.id=ranked.id),
    'attempts',attempts,'correct',correct,'incorrect',incorrect,'uniqueUsers',unique_users,'accuracy',accuracy,
    'observedDifficulty',case when attempts<5 then 'insufficient' when accuracy>=75 then 'easy' when accuracy>=45 then 'medium' else 'hard' end,
    'difficultyMismatch',attempts>=10 and ((difficulty='easy' and accuracy<45) or (difficulty='hard' and accuracy>=75)),
    'lastServedAt',last_served_at) order by case when p_sort='easiest' then accuracy end desc nulls last,
      case when p_sort in ('hardest','missed') then accuracy end asc nulls last, attempts desc),'[]'::jsonb),
    'pagination',jsonb_build_object('page',safe_page,'pageSize',safe_size,'total',coalesce(max(total_rows),0),
      'totalPages',ceil(coalesce(max(total_rows),0)::numeric/safe_size)),
    'summary',jsonb_build_object('questions',(select count(*) from public.questions),'published',(select count(*) from public.questions where published),
      'totalAttempts',(select count(*) from public.session_answers),'categories',(select count(distinct category) from public.questions)))
  into result from ranked;
  return result;
end;
$$;

create or replace function public.admin_settings_data()
returns jsonb language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.has_admin_capability('settings.view') then raise exception 'Forbidden'; end if;
  return jsonb_build_object(
    'settings',(select coalesce(jsonb_agg(jsonb_build_object('key',key,'value',value,'description',description,'updatedAt',updated_at) order by key),'[]'::jsonb) from public.admin_settings),
    'admins',(select coalesce(jsonb_agg(jsonb_build_object('userId',p.id,'username',p.username,'displayName',p.display_name,'role',r.key,'assignedAt',a.created_at) order by p.username),'[]'::jsonb)
      from public.admin_user_roles a join public.admin_roles r on r.id=a.role_id join public.profiles p on p.id=a.user_id),
    'roles',(select coalesce(jsonb_agg(jsonb_build_object('key',key,'name',name) order by name),'[]'::jsonb) from public.admin_roles),
    'audit',(select coalesce(jsonb_agg(jsonb_build_object('id',l.id,'admin',p.username,'action',l.action,'resourceType',l.resource_type,
      'resourceId',l.resource_id,'createdAt',l.created_at) order by l.created_at desc),'[]'::jsonb) from (select * from public.admin_audit_logs order by created_at desc limit 50) l join public.profiles p on p.id=l.admin_user_id)
  );
end;
$$;

create or replace function public.admin_audit_data(p_limit integer default 100)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.has_admin_capability('audit.view') then raise exception 'Forbidden'; end if;
  return coalesce((select jsonb_agg(jsonb_build_object('id',l.id,'admin',p.username,'action',l.action,
    'resourceType',l.resource_type,'resourceId',l.resource_id,'createdAt',l.created_at) order by l.created_at desc)
    from (select * from public.admin_audit_logs order by created_at desc limit greatest(1,least(p_limit,500))) l
    join public.profiles p on p.id=l.admin_user_id), '[]'::jsonb);
end;
$$;

create or replace function public.admin_update_user(p_user_id uuid, p_status text, p_eligible boolean, p_reason text)
returns void language plpgsql security definer set search_path = '' as $$
declare before_row jsonb; after_row jsonb;
begin
  if not public.has_admin_capability('users.manage') then raise exception 'Forbidden'; end if;
  if p_status not in ('active','suspended') or char_length(trim(coalesce(p_reason,'')))<3 then raise exception 'A valid status and reason are required'; end if;
  select to_jsonb(p) into before_row from public.profiles p where p.id=p_user_id for update;
  update public.profiles set account_status=p_status, leaderboard_eligible=p_eligible, updated_at=now() where id=p_user_id returning to_jsonb(profiles) into after_row;
  insert into public.admin_audit_logs(admin_user_id,action,resource_type,resource_id,target_user_id,before_data,after_data,metadata)
  values(auth.uid(),case when p_status='suspended' then 'user.suspend' else 'user.reactivate' end,'user',p_user_id::text,p_user_id,before_row,after_row,jsonb_build_object('reason',left(p_reason,500)));
end;
$$;

create or replace function public.admin_set_question_status(p_question_id text, p_status text, p_reason text default '')
returns void language plpgsql security definer set search_path = '' as $$
declare before_row jsonb; after_row jsonb;
begin
  if not public.has_admin_capability('questions.manage') then raise exception 'Forbidden'; end if;
  if p_status not in ('draft','published','unpublished','archived','in_review') then raise exception 'Invalid status'; end if;
  select to_jsonb(q) into before_row from public.questions q where q.id=p_question_id for update;
  update public.questions set content_status=p_status,published=(p_status='published'),updated_at=now() where id=p_question_id returning to_jsonb(questions) into after_row;
  insert into public.admin_audit_logs(admin_user_id,action,resource_type,resource_id,before_data,after_data,metadata)
  values(auth.uid(),'question.'||p_status,'question',p_question_id,before_row,after_row,jsonb_build_object('reason',left(coalesce(p_reason,''),500)));
end;
$$;

create or replace function public.admin_upsert_question(p_id text,p_question text,p_answer text,p_category text,p_subcategory text,p_difficulty text,p_type text,p_explanation text,p_status text)
returns text language plpgsql security definer set search_path = '' as $$
declare question_id text := upper(trim(p_id)); before_row jsonb; after_row jsonb;
begin
  if not public.has_admin_capability('questions.manage') then raise exception 'Forbidden'; end if;
  if question_id !~ '^[A-Z]+-[0-9]{4}$' or char_length(trim(p_question))<10 or char_length(trim(p_answer))<1 then raise exception 'Invalid question fields'; end if;
  if p_difficulty not in ('easy','medium','hard') or p_type not in ('multiple_choice','fill_in_the_blank','true_false','short_answer') then raise exception 'Invalid question configuration'; end if;
  select to_jsonb(q) into before_row from public.questions q where q.id=question_id;
  insert into public.questions(id,accepted_answer,aliases,published,category,subcategory,difficulty,question_type,question,options,correct_answer,explanation,content_status,updated_at)
  values(question_id,trim(p_answer),'{}',p_status='published',trim(p_category),trim(p_subcategory),p_difficulty,p_type,trim(p_question),'[]',to_jsonb(trim(p_answer)),trim(p_explanation),p_status,now())
  on conflict(id) do update set accepted_answer=excluded.accepted_answer,published=excluded.published,category=excluded.category,
    subcategory=excluded.subcategory,difficulty=excluded.difficulty,question_type=excluded.question_type,question=excluded.question,
    correct_answer=excluded.correct_answer,explanation=excluded.explanation,content_status=excluded.content_status,updated_at=now()
  returning to_jsonb(questions) into after_row;
  insert into public.admin_audit_logs(admin_user_id,action,resource_type,resource_id,before_data,after_data)
  values(auth.uid(),case when before_row is null then 'question.create' else 'question.update' end,'question',question_id,before_row,after_row);
  return question_id;
end;
$$;

create or replace function public.admin_assign_role(p_user text,p_role text,p_remove boolean default false)
returns void language plpgsql security definer set search_path = '' as $$
declare target_id uuid; target_role uuid;
begin
  if not public.has_admin_capability('admins.manage') then raise exception 'Forbidden'; end if;
  select id into target_id from public.profiles where id::text=p_user or username=p_user;
  select id into target_role from public.admin_roles where key=p_role;
  if target_id is null or target_role is null then raise exception 'Unknown user or role'; end if;
  if p_remove then delete from public.admin_user_roles where user_id=target_id and role_id=target_role;
  else insert into public.admin_user_roles(user_id,role_id,created_by) values(target_id,target_role,auth.uid()) on conflict do nothing; end if;
  insert into public.admin_audit_logs(admin_user_id,action,resource_type,resource_id,target_user_id,metadata)
  values(auth.uid(),case when p_remove then 'admin_role.revoke' else 'admin_role.assign' end,'admin_role',p_role,target_id,jsonb_build_object('role',p_role));
end;
$$;

create or replace function public.admin_update_setting(p_key text,p_value jsonb)
returns void language plpgsql security definer set search_path = '' as $$
declare before_row jsonb; after_row jsonb;
begin
  if not public.has_admin_capability('settings.manage') then raise exception 'Forbidden'; end if;
  select to_jsonb(s) into before_row from public.admin_settings s where s.key=p_key for update;
  update public.admin_settings set value=p_value,updated_by=auth.uid(),updated_at=now() where key=p_key returning to_jsonb(admin_settings) into after_row;
  if after_row is null then raise exception 'Unknown setting'; end if;
  insert into public.admin_audit_logs(admin_user_id,action,resource_type,resource_id,before_data,after_data)
  values(auth.uid(),'setting.update','setting',p_key,before_row,after_row);
end;
$$;

revoke all on function public.has_admin_capability(text) from public;
revoke all on function public.admin_current_access() from public;
revoke all on function public.admin_overview(date,date) from public;
revoke all on function public.admin_list_users(text,text,integer,text,text,integer,integer) from public;
revoke all on function public.admin_user_detail(uuid) from public;
revoke all on function public.admin_leaderboard(text,text,date,date,text,integer,integer) from public;
revoke all on function public.admin_question_analytics(text,text,text,integer,integer) from public;
revoke all on function public.admin_settings_data() from public;
revoke all on function public.admin_audit_data(integer) from public;
revoke all on function public.admin_update_user(uuid,text,boolean,text) from public;
revoke all on function public.admin_set_question_status(text,text,text) from public;
revoke all on function public.admin_upsert_question(text,text,text,text,text,text,text,text,text) from public;
revoke all on function public.admin_assign_role(text,text,boolean) from public;
revoke all on function public.admin_update_setting(text,jsonb) from public;

grant execute on function public.admin_current_access() to authenticated;
grant execute on function public.admin_overview(date,date) to authenticated;
grant execute on function public.admin_list_users(text,text,integer,text,text,integer,integer) to authenticated;
grant execute on function public.admin_user_detail(uuid) to authenticated;
grant execute on function public.admin_leaderboard(text,text,date,date,text,integer,integer) to authenticated;
grant execute on function public.admin_question_analytics(text,text,text,integer,integer) to authenticated;
grant execute on function public.admin_settings_data() to authenticated;
grant execute on function public.admin_audit_data(integer) to authenticated;
grant execute on function public.admin_update_user(uuid,text,boolean,text) to authenticated;
grant execute on function public.admin_set_question_status(text,text,text) to authenticated;
grant execute on function public.admin_upsert_question(text,text,text,text,text,text,text,text,text) to authenticated;
grant execute on function public.admin_assign_role(text,text,boolean) to authenticated;
grant execute on function public.admin_update_setting(text,jsonb) to authenticated;
