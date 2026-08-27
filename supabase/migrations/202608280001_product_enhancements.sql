-- QuizForge product enhancements MVP. The existing session_answers table remains
-- the authoritative question-attempt ledger.

alter table public.practice_sessions add column if not exists started_at timestamptz not null default now();
alter table public.session_answers add column if not exists started_at timestamptz;
alter table public.session_answers add column if not exists submitted_at timestamptz;
alter table public.session_answers add column if not exists time_limit_ms integer not null default 15000;
alter table public.session_answers add column if not exists response_time_ms integer;
alter table public.session_answers add column if not exists timed_out boolean not null default false;
alter table public.session_answers add column if not exists attempt_status text not null default 'incorrect';

create table if not exists public.xp_events (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  amount integer not null,
  event_type text not null,
  source_id text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique(user_id, event_type, source_id)
);

create table if not exists public.notification_preferences (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  daily_practice_email_enabled boolean not null default false,
  daily_practice_email_time time not null default '18:00',
  timezone text not null default 'UTC',
  streak_warning_email_enabled boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.notification_deliveries (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  notification_type text not null,
  channel text not null,
  local_date date not null,
  scheduled_for timestamptz,
  sent_at timestamptz,
  status text not null check(status in ('scheduled','sent','failed','skipped')),
  provider_message_id text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique(user_id, notification_type, channel, local_date)
);

create table if not exists public.referral_codes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique not null references public.profiles(id) on delete cascade,
  code text unique not null,
  created_at timestamptz not null default now(),
  is_active boolean not null default true
);

create table if not exists public.referrals (
  id uuid primary key default gen_random_uuid(),
  referrer_user_id uuid not null references public.profiles(id) on delete cascade,
  referred_user_id uuid unique not null references public.profiles(id) on delete cascade,
  referral_code_id uuid not null references public.referral_codes(id),
  status text not null default 'signed_up' check(status in ('pending','signed_up','qualified','rewarded','invalid')),
  signed_up_at timestamptz default now(), qualified_at timestamptz, rewarded_at timestamptz,
  created_at timestamptz not null default now(),
  check(referrer_user_id <> referred_user_id)
);

create table if not exists public.badges (
  id uuid primary key default gen_random_uuid(), key text unique not null, name text not null,
  description text not null, badge_type text not null, icon_key text not null,
  requirement jsonb not null, sort_order integer not null default 0,
  is_active boolean not null default true, created_at timestamptz not null default now()
);

create table if not exists public.user_badges (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
  badge_id uuid not null references public.badges(id) on delete cascade, earned_at timestamptz not null default now(),
  source_metadata jsonb not null default '{}'::jsonb, unique(user_id,badge_id)
);

create table if not exists public.friend_requests (
  id uuid primary key default gen_random_uuid(), sender_user_id uuid not null references public.profiles(id) on delete cascade,
  receiver_user_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending' check(status in ('pending','accepted','declined','cancelled')),
  created_at timestamptz not null default now(), responded_at timestamptz,
  check(sender_user_id <> receiver_user_id)
);

create unique index if not exists friend_requests_pending_pair_idx on public.friend_requests(
  least(sender_user_id,receiver_user_id), greatest(sender_user_id,receiver_user_id)
) where status='pending';

create table if not exists public.friendships (
  id uuid primary key default gen_random_uuid(), user_a_id uuid not null references public.profiles(id) on delete cascade,
  user_b_id uuid not null references public.profiles(id) on delete cascade, created_at timestamptz not null default now(),
  check(user_a_id < user_b_id), unique(user_a_id,user_b_id)
);

create table if not exists public.product_events (
  id bigint generated always as identity primary key, user_id uuid references public.profiles(id) on delete set null,
  event_name text not null, metadata jsonb not null default '{}'::jsonb, created_at timestamptz not null default now()
);

create index if not exists session_answers_user_timing_idx on public.session_answers(session_id,timed_out,response_time_ms);
create index if not exists xp_events_user_created_idx on public.xp_events(user_id,created_at desc);
create index if not exists user_badges_user_idx on public.user_badges(user_id,earned_at desc);
create index if not exists friend_requests_receiver_idx on public.friend_requests(receiver_user_id,status);

insert into public.referral_codes(user_id,code)
select p.id, upper(left(regexp_replace(p.username,'[^a-z0-9]','','g'),6)||substr(replace(p.id::text,'-',''),1,4))
from public.profiles p on conflict(user_id) do nothing;

insert into public.notification_preferences(user_id)
select id from public.profiles on conflict(user_id) do nothing;

insert into public.badges(key,name,description,badge_type,icon_key,requirement,sort_order) values
('streak_3','Getting Started','Maintain a 3-day practice streak.','streak','flame','{"metric":"streak","value":3}',10),
('streak_7','On Fire','Maintain a 7-day practice streak.','streak','flame','{"metric":"streak","value":7}',11),
('streak_14','Dedicated','Maintain a 14-day practice streak.','streak','flame','{"metric":"streak","value":14}',12),
('streak_30','Consistent','Maintain a 30-day practice streak.','streak','flame','{"metric":"streak","value":30}',13),
('streak_60','Relentless','Maintain a 60-day practice streak.','streak','flame','{"metric":"streak","value":60}',14),
('streak_100','QuizForge Veteran','Maintain a 100-day practice streak.','streak','flame','{"metric":"streak","value":100}',15),
('quiz_1','First Set','Complete your first practice set.','quiz','trophy','{"metric":"quizzes","value":1}',20),
('quiz_10','Practice Regular','Complete 10 practice sets.','quiz','trophy','{"metric":"quizzes","value":10}',21),
('quiz_50','Quiz Grinder','Complete 50 practice sets.','quiz','trophy','{"metric":"quizzes","value":50}',22),
('quiz_100','Century Club','Complete 100 practice sets.','quiz','trophy','{"metric":"quizzes","value":100}',23),
('quiz_250','Marathon Scholar','Complete 250 practice sets.','quiz','trophy','{"metric":"quizzes","value":250}',24),
('quiz_500','Quiz Machine','Complete 500 practice sets.','quiz','trophy','{"metric":"quizzes","value":500}',25),
('correct_100','Knowledge Builder','Answer 100 questions correctly.','correct','book','{"metric":"correct","value":100}',30),
('correct_500','Scholar','Answer 500 questions correctly.','correct','book','{"metric":"correct","value":500}',31),
('correct_1000','Quiz Bowl Expert','Answer 1,000 questions correctly.','correct','book','{"metric":"correct","value":1000}',32),
('referral_1','Recruiter','Qualify your first referral.','referral','users','{"metric":"referrals","value":1}',40),
('referral_5','Connector','Qualify five referrals.','referral','users','{"metric":"referrals","value":5}',41),
('referral_10','QuizForge Ambassador','Qualify ten referrals.','referral','users','{"metric":"referrals","value":10}',42),
('referral_25','Community Builder','Qualify 25 referrals.','referral','users','{"metric":"referrals","value":25}',43)
on conflict(key) do update set name=excluded.name,description=excluded.description,requirement=excluded.requirement;

insert into public.badges(key,name,description,badge_type,icon_key,requirement,sort_order)
select 'master_'||lower(replace(category,' ', '_')), category||' Master',
  'Reach 85% accuracy across at least 100 '||category||' questions.', 'mastery','award',
  jsonb_build_object('metric','category_mastery','category',category,'attempts',100,'accuracy',85), 100
from (select distinct category from public.questions where category is not null) c on conflict(key) do nothing;

alter table public.xp_events enable row level security;
alter table public.notification_preferences enable row level security;
alter table public.notification_deliveries enable row level security;
alter table public.referral_codes enable row level security;
alter table public.referrals enable row level security;
alter table public.badges enable row level security;
alter table public.user_badges enable row level security;
alter table public.friend_requests enable row level security;
alter table public.friendships enable row level security;
alter table public.product_events enable row level security;

create policy "users read own xp events" on public.xp_events for select to authenticated using(user_id=auth.uid());
create policy "users manage notification preferences" on public.notification_preferences for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "users read own deliveries" on public.notification_deliveries for select to authenticated using(user_id=auth.uid());
create policy "active referral codes visible" on public.referral_codes for select to authenticated using(is_active);
create policy "users read involved referrals" on public.referrals for select to authenticated using(auth.uid() in (referrer_user_id,referred_user_id));
create policy "badges are public" on public.badges for select using(is_active);
create policy "earned badges are public" on public.user_badges for select using(true);
create policy "users read involved requests" on public.friend_requests for select to authenticated using(auth.uid() in(sender_user_id,receiver_user_id));
create policy "users read own friendships" on public.friendships for select to authenticated using(auth.uid() in(user_a_id,user_b_id));
create policy "users insert own product events" on public.product_events for insert to authenticated with check(user_id=auth.uid());

create or replace function public.ensure_user_enhancements(p_user_id uuid, p_referral_code text default null)
returns void language plpgsql security definer set search_path='' as $$
declare code_row public.referral_codes%rowtype;
begin
  insert into public.notification_preferences(user_id) values(p_user_id) on conflict do nothing;
  insert into public.referral_codes(user_id,code)
  select p.id,upper(left(regexp_replace(p.username,'[^a-z0-9]','','g'),6)||substr(replace(p.id::text,'-',''),1,4))
  from public.profiles p where p.id=p_user_id on conflict(user_id) do nothing;
  if nullif(trim(p_referral_code),'') is not null then
    select * into code_row from public.referral_codes where code=upper(trim(p_referral_code)) and is_active;
    if found and code_row.user_id<>p_user_id then
      insert into public.referrals(referrer_user_id,referred_user_id,referral_code_id)
      values(code_row.user_id,p_user_id,code_row.id) on conflict(referred_user_id) do nothing;
    end if;
  end if;
end $$;

create or replace function public.evaluate_user_badges(p_user_id uuid)
returns integer language plpgsql security definer set search_path='' as $$
declare awarded integer:=0;
begin
  insert into public.user_badges(user_id,badge_id,source_metadata)
  select p_user_id,b.id,jsonb_build_object('evaluatedAt',now()) from public.badges b
  join public.profiles p on p.id=p_user_id
  where b.is_active and (
    (b.requirement->>'metric'='streak' and p.longest_streak >= (b.requirement->>'value')::int) or
    (b.requirement->>'metric'='correct' and p.total_correct >= (b.requirement->>'value')::int) or
    (b.requirement->>'metric'='quizzes' and (select count(*) from public.practice_sessions s where s.user_id=p_user_id) >= (b.requirement->>'value')::int) or
    (b.requirement->>'metric'='referrals' and (select count(*) from public.referrals r where r.referrer_user_id=p_user_id and r.status='rewarded') >= (b.requirement->>'value')::int) or
    (b.requirement->>'metric'='category_mastery' and exists(select 1 from public.session_answers sa join public.practice_sessions s on s.id=sa.session_id join public.questions q on q.id=sa.question_id where s.user_id=p_user_id and q.category=b.requirement->>'category' group by q.category having count(*) >= (b.requirement->>'attempts')::int and 100.0*count(*) filter(where sa.is_correct)/count(*) >= (b.requirement->>'accuracy')::numeric))
  ) on conflict(user_id,badge_id) do nothing;
  get diagnostics awarded=row_count;
  return awarded;
end $$;

create or replace function public.qualify_user_referral(p_user_id uuid)
returns void language plpgsql security definer set search_path='' as $$
declare referral public.referrals%rowtype;
begin
  select * into referral from public.referrals where referred_user_id=p_user_id and status in('signed_up','qualified') for update;
  if not found then return; end if;
  update public.referrals set status='rewarded',qualified_at=coalesce(qualified_at,now()),rewarded_at=now() where id=referral.id;
  insert into public.xp_events(user_id,amount,event_type,source_id) values(referral.referrer_user_id,100,'referral_reward',referral.id::text) on conflict do nothing;
  if found then update public.profiles set total_xp=total_xp+100,updated_at=now() where id=referral.referrer_user_id; end if;
  perform public.evaluate_user_badges(referral.referrer_user_id);
end $$;

create or replace function public.get_my_product_data(p_days integer default 30)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare uid uuid:=auth.uid(); result jsonb; cutoff timestamptz:=case when p_days=0 then '1970-01-01'::timestamptz else now()-make_interval(days=>greatest(1,least(p_days,3650))) end;
begin
  if uid is null then raise exception 'Authentication required'; end if;
  select jsonb_build_object(
    'overall',jsonb_build_object('attempted',p.total_answered,'correct',p.total_correct,'incorrect',p.total_answered-p.total_correct,'accuracy',case when p.total_answered=0 then null else round(100.0*p.total_correct/p.total_answered,1) end,'xp',p.total_xp,'streak',p.current_streak,'longestStreak',p.longest_streak,'quizzesCompleted',(select count(*) from public.practice_sessions s where s.user_id=uid),'averageResponseMs',(select round(avg(sa.response_time_ms)) from public.session_answers sa join public.practice_sessions s on s.id=sa.session_id where s.user_id=uid and sa.response_time_ms is not null),'timedOut',(select count(*) from public.session_answers sa join public.practice_sessions s on s.id=sa.session_id where s.user_id=uid and sa.timed_out)),
    'timeline',coalesce((select jsonb_agg(jsonb_build_object('day',t.stat_day,'attempted',t.attempted,'correct',t.correct,'xp',t.xp,'quizzes',t.quizzes) order by t.stat_day) from(select date_trunc('week',s.completed_at)::date as stat_day,sum(s.question_count) as attempted,sum(s.correct_count) as correct,sum(s.xp_earned) as xp,count(*) as quizzes from public.practice_sessions s where s.user_id=uid and s.completed_at>=cutoff group by 1)t),'[]'::jsonb),
    'categories',coalesce((select jsonb_agg(row_to_json(c) order by c.category) from(select q.category,count(sa.id) attempts,count(sa.id) filter(where sa.is_correct) correct,case when count(sa.id)=0 then null else round(100.0*count(sa.id) filter(where sa.is_correct)/count(sa.id),1) end accuracy,round(avg(sa.response_time_ms)) average_response_ms,max(s.completed_at) last_practiced_at,case when count(sa.id)<10 then 'Unrated' when 100.0*count(sa.id) filter(where sa.is_correct)/count(sa.id)<60 then 'Beginner' when 100.0*count(sa.id) filter(where sa.is_correct)/count(sa.id)<75 then 'Developing' when count(sa.id)>=100 and 100.0*count(sa.id) filter(where sa.is_correct)/count(sa.id)>=85 then 'Mastered' else 'Proficient' end mastery from public.questions q left join public.session_answers sa on sa.question_id=q.id left join public.practice_sessions s on s.id=sa.session_id and s.user_id=uid where q.published and (sa.id is null or s.id is not null) group by q.category)c),'[]'::jsonb),
    'badges',coalesce((select jsonb_agg(jsonb_build_object('key',b.key,'name',b.name,'description',b.description,'type',b.badge_type,'icon',b.icon_key,'earnedAt',ub.earned_at) order by b.sort_order) from public.user_badges ub join public.badges b on b.id=ub.badge_id where ub.user_id=uid),'[]'::jsonb),
    'referral',coalesce((select jsonb_build_object('code',rc.code,'qualified',(select count(*) from public.referrals r where r.referrer_user_id=uid and r.status='rewarded')) from public.referral_codes rc where rc.user_id=uid),'{}'::jsonb),
    'notifications',(select jsonb_build_object('enabled',daily_practice_email_enabled,'time',daily_practice_email_time,'timezone',timezone) from public.notification_preferences where user_id=uid),
    'recentActivity',coalesce((select jsonb_agg(jsonb_build_object('at',s.completed_at,'label','Completed '||coalesce(s.category,'mixed')||' practice','detail',s.correct_count||'/'||s.question_count||' correct · +'||s.xp_earned||' XP') order by s.completed_at desc) from(select * from public.practice_sessions where user_id=uid order by completed_at desc limit 8)s),'[]'::jsonb)
  ) into result from public.profiles p where p.id=uid;
  return result;
end $$;

create or replace function public.search_users_for_friends(p_search text)
returns jsonb language sql stable security definer set search_path='' as $$
select coalesce(jsonb_agg(jsonb_build_object('id',p.id,'username',p.username,'displayName',p.display_name,'xp',p.total_xp,'streak',p.current_streak)),'[]'::jsonb)
from(select * from public.profiles where id<>auth.uid() and (username ilike '%'||left(p_search,40)||'%' or display_name ilike '%'||left(p_search,40)||'%') order by username limit 12)p where auth.uid() is not null;
$$;

create or replace function public.get_friends_data()
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare uid uuid:=auth.uid();
begin if uid is null then raise exception 'Authentication required'; end if;
return jsonb_build_object(
 'friends',coalesce((select jsonb_agg(jsonb_build_object('id',p.id,'username',p.username,'displayName',p.display_name,'xp',p.total_xp,'streak',p.current_streak,'accuracy',case when p.total_answered=0 then null else round(100.0*p.total_correct/p.total_answered,1) end,'weeklyXp',(select coalesce(sum(s.xp_earned),0) from public.practice_sessions s where s.user_id=p.id and s.completed_at>=date_trunc('week',now())))) from public.friendships f join public.profiles p on p.id=case when f.user_a_id=uid then f.user_b_id else f.user_a_id end where uid in(f.user_a_id,f.user_b_id)),'[]'::jsonb),
 'incoming',coalesce((select jsonb_agg(jsonb_build_object('id',r.id,'userId',p.id,'username',p.username,'displayName',p.display_name,'createdAt',r.created_at)) from public.friend_requests r join public.profiles p on p.id=r.sender_user_id where r.receiver_user_id=uid and r.status='pending'),'[]'::jsonb),
 'outgoing',coalesce((select jsonb_agg(jsonb_build_object('id',r.id,'userId',p.id,'username',p.username,'displayName',p.display_name,'createdAt',r.created_at)) from public.friend_requests r join public.profiles p on p.id=r.receiver_user_id where r.sender_user_id=uid and r.status='pending'),'[]'::jsonb)); end $$;

create or replace function public.manage_friend(p_action text,p_target uuid)
returns void language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); req public.friend_requests%rowtype; a uuid; b uuid;
begin if uid is null or uid=p_target then raise exception 'Invalid friend action'; end if;
if p_action='send' then
 if exists(select 1 from public.friendships where user_a_id=least(uid,p_target) and user_b_id=greatest(uid,p_target)) then raise exception 'Already friends'; end if;
 insert into public.friend_requests(sender_user_id,receiver_user_id) values(uid,p_target);
elsif p_action in('accept','decline') then
 select * into req from public.friend_requests where id=p_target and receiver_user_id=uid and status='pending' for update;
 if not found then raise exception 'Friend request not found'; end if;
 update public.friend_requests set status=case when p_action='accept' then 'accepted' else 'declined' end,responded_at=now() where id=req.id;
 if p_action='accept' then a:=least(uid,req.sender_user_id);b:=greatest(uid,req.sender_user_id);insert into public.friendships(user_a_id,user_b_id) values(a,b) on conflict do nothing; end if;
elsif p_action='remove' then delete from public.friendships where user_a_id=least(uid,p_target) and user_b_id=greatest(uid,p_target);
else raise exception 'Invalid friend action'; end if; end $$;

create or replace function public.get_friends_leaderboard()
returns jsonb language sql stable security definer set search_path='' as $$
with ids as(select auth.uid() id union select case when f.user_a_id=auth.uid() then f.user_b_id else f.user_a_id end from public.friendships f where auth.uid() in(f.user_a_id,f.user_b_id)),scores as(select p.id,p.username,p.display_name,p.current_streak,coalesce(sum(s.xp_earned),0) xp,coalesce(sum(s.question_count),0) questions,coalesce(sum(s.correct_count),0) correct,count(s.id) quizzes from ids join public.profiles p using(id) left join public.practice_sessions s on s.user_id=p.id and s.completed_at>=date_trunc('week',now()) group by p.id),ranked as(select row_number()over(order by xp desc,correct desc,id)rank,* from scores)
select coalesce(jsonb_agg(jsonb_build_object('rank',rank,'id',id,'username',username,'displayName',display_name,'xp',xp,'accuracy',case when questions=0 then null else round(100.0*correct/questions,1)end,'quizzes',quizzes,'streak',current_streak,'isCurrentUser',id=auth.uid()) order by rank),'[]'::jsonb) from ranked;
$$;

create or replace function public.save_notification_preferences(p_enabled boolean,p_time time,p_timezone text)
returns void language plpgsql security definer set search_path='' as $$
begin if auth.uid() is null then raise exception 'Authentication required';end if;
perform now() at time zone p_timezone;
insert into public.notification_preferences(user_id,daily_practice_email_enabled,daily_practice_email_time,timezone) values(auth.uid(),p_enabled,p_time,p_timezone) on conflict(user_id) do update set daily_practice_email_enabled=excluded.daily_practice_email_enabled,daily_practice_email_time=excluded.daily_practice_email_time,timezone=excluded.timezone,updated_at=now();
insert into public.product_events(user_id,event_name) values(auth.uid(),case when p_enabled then 'daily_reminder_enabled' else 'daily_reminder_disabled' end); end $$;

create or replace function public.get_public_profile(p_username text)
returns jsonb language sql stable security definer set search_path='' as $$
select jsonb_build_object('username',p.username,'displayName',p.display_name,'joinedAt',p.created_at,'totalXp',p.total_xp,'currentStreak',p.current_streak,'quizzesCompleted',(select count(*) from public.practice_sessions s where s.user_id=p.id),'correctAnswers',p.total_correct,'accuracy',case when p.total_answered=0 then null else round(100.0*p.total_correct/p.total_answered,1) end,'badges',coalesce((select jsonb_agg(jsonb_build_object('name',b.name,'description',b.description,'earnedAt',ub.earned_at)) from public.user_badges ub join public.badges b on b.id=ub.badge_id where ub.user_id=p.id),'[]'::jsonb),'strongestCategories',coalesce((select jsonb_agg(row_to_json(c)) from(select q.category,round(100.0*count(*)filter(where sa.is_correct)/count(*),1)accuracy from public.session_answers sa join public.practice_sessions s on s.id=sa.session_id join public.questions q on q.id=sa.question_id where s.user_id=p.id group by q.category having count(*)>=10 order by accuracy desc limit 3)c),'[]'::jsonb)) from public.profiles p where p.username=p_username;
$$;

revoke all on function public.ensure_user_enhancements(uuid,text),public.evaluate_user_badges(uuid),public.qualify_user_referral(uuid),public.get_my_product_data(integer),public.search_users_for_friends(text),public.get_friends_data(),public.manage_friend(text,uuid),public.get_friends_leaderboard(),public.save_notification_preferences(boolean,time,text),public.get_public_profile(text) from public;
grant execute on function public.get_my_product_data(integer),public.search_users_for_friends(text),public.get_friends_data(),public.manage_friend(text,uuid),public.get_friends_leaderboard(),public.save_notification_preferences(boolean,time,text),public.get_public_profile(text) to authenticated;

create or replace function public.complete_practice_session(
  p_session_type text,p_category text,p_answers jsonb,p_timezone text default 'UTC'
) returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); item jsonb; q public.questions%rowtype; session_id uuid:=gen_random_uuid();
 answer_count integer; v_correct_count integer:=0; earned_xp integer; daily_bonus integer:=0; practice_day date;
 inserted_daily integer:=0; first_daily boolean:=false; p public.profiles%rowtype; submitted text;
 correct boolean; timed_out boolean; response_ms integer; began timestamptz; submitted_at timestamptz;
begin
 if uid is null then raise exception 'Authentication required';end if;
 if p_session_type not in('daily','category') or jsonb_typeof(p_answers)<>'array' then raise exception 'Invalid session';end if;
 answer_count:=jsonb_array_length(p_answers);
 if answer_count<1 or answer_count>20 then raise exception 'A session must contain 1-20 answers';end if;
 if(select count(distinct value->>'questionId')from jsonb_array_elements(p_answers))<>answer_count then raise exception 'Duplicate question';end if;
 begin practice_day:=(now() at time zone p_timezone)::date;exception when invalid_parameter_value then raise exception 'Invalid timezone';end;
 insert into public.practice_sessions(id,user_id,session_type,category,question_count,correct_count,xp_earned,started_at)
 values(session_id,uid,p_session_type,nullif(left(p_category,50),''),answer_count,0,0,coalesce((p_answers->0->>'startedAt')::timestamptz,now()));
 for item in select value from jsonb_array_elements(p_answers) loop
  select * into q from public.questions where id=item->>'questionId' and published;
  if not found then raise exception 'Unknown question';end if;
  submitted:=left(coalesce(item->>'submitted',''),200); timed_out:=coalesce((item->>'timedOut')::boolean,false);
  response_ms:=greatest(0,least(coalesce((item->>'responseTimeMs')::integer,15000),3600000));
  began:=coalesce((item->>'startedAt')::timestamptz,now()-make_interval(secs=>response_ms/1000.0));
  submitted_at:=coalesce((item->>'submittedAt')::timestamptz,began+make_interval(secs=>response_ms/1000.0));
  if began>now()+interval '1 minute' or submitted_at<began then raise exception 'Invalid attempt timing';end if;
  timed_out:=timed_out or response_ms>17000;
  correct:=not timed_out and exists(select 1 from unnest(array_prepend(q.accepted_answer,q.aliases))v where public.quiz_answers_match(submitted,v));
  if correct then v_correct_count:=v_correct_count+1;end if;
  insert into public.session_answers(session_id,question_id,submitted_answer,is_correct,started_at,submitted_at,time_limit_ms,response_time_ms,timed_out,attempt_status)
  values(session_id,q.id,submitted,correct,began,submitted_at,15000,response_ms,timed_out,case when timed_out then 'timed_out' when correct then 'correct' else 'incorrect' end);
 end loop;
 earned_xp:=v_correct_count*10;
 if p_session_type='daily' then
  insert into public.daily_progress(user_id,practice_date,session_id)values(uid,practice_day,session_id)on conflict do nothing;
  get diagnostics inserted_daily=row_count;first_daily:=inserted_daily=1;
  if first_daily then daily_bonus:=20+case when v_correct_count=answer_count then 25 else 0 end;end if;
 end if;
 earned_xp:=earned_xp+daily_bonus;
 update public.practice_sessions set correct_count=v_correct_count,xp_earned=earned_xp where id=session_id;
 select * into p from public.profiles where id=uid for update;
 if first_daily then p.current_streak:=case when p.last_daily_completed_on=practice_day-1 then p.current_streak+1 else 1 end;p.longest_streak:=greatest(p.longest_streak,p.current_streak);p.last_daily_completed_on:=practice_day;end if;
 update public.profiles set total_xp=total_xp+earned_xp,total_answered=total_answered+answer_count,total_correct=total_correct+v_correct_count,current_streak=p.current_streak,longest_streak=p.longest_streak,last_daily_completed_on=p.last_daily_completed_on,last_active_at=now(),updated_at=now() where id=uid returning * into p;
 insert into public.xp_events(user_id,amount,event_type,source_id,metadata)values(uid,earned_xp,'practice_session',session_id::text,jsonb_build_object('correct',v_correct_count,'questions',answer_count))on conflict do nothing;
 perform public.qualify_user_referral(uid);perform public.evaluate_user_badges(uid);
 insert into public.product_events(user_id,event_name,metadata)values(uid,'practice_session_completed',jsonb_build_object('sessionId',session_id));
 return jsonb_build_object('sessionId',session_id,'xpEarned',earned_xp,'correctCount',v_correct_count,'profile',jsonb_build_object('xp',p.total_xp,'streak',p.current_streak,'longest',p.longest_streak,'answered',p.total_answered,'correct',p.total_correct,'done',p.last_daily_completed_on));
end $$;

revoke all on function public.complete_practice_session(text,text,jsonb,text) from public;
grant execute on function public.complete_practice_session(text,text,jsonb,text) to authenticated;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path='' as $$
declare requested_username text;
begin
 requested_username:=lower(coalesce(new.raw_user_meta_data->>'username',split_part(new.email,'@',1)));
 requested_username:=regexp_replace(requested_username,'[^a-z0-9_]','','g');
 if char_length(requested_username)<3 then requested_username:='player';end if;
 requested_username:=left(requested_username,24);
 begin
  insert into public.profiles(id,username,display_name)values(new.id,requested_username,left(coalesce(nullif(new.raw_user_meta_data->>'display_name',''),requested_username),40));
 exception when unique_violation then
  requested_username:=left(requested_username,17)||'_'||substr(new.id::text,1,6);
  insert into public.profiles(id,username,display_name)values(new.id,requested_username,left(coalesce(nullif(new.raw_user_meta_data->>'display_name',''),requested_username),40));
 end;
 perform public.ensure_user_enhancements(new.id,new.raw_user_meta_data->>'referral_code');
 return new;
end $$;
