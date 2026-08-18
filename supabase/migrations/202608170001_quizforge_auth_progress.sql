create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique check (username ~ '^[a-z0-9_]{3,24}$'),
  display_name text not null check (char_length(display_name) between 1 and 40),
  total_xp integer not null default 0 check (total_xp >= 0),
  current_streak integer not null default 0 check (current_streak >= 0),
  longest_streak integer not null default 0 check (longest_streak >= 0),
  total_answered integer not null default 0 check (total_answered >= 0),
  total_correct integer not null default 0 check (total_correct between 0 and total_answered),
  last_daily_completed_on date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.questions (
  id text primary key,
  accepted_answer text not null,
  aliases text[] not null default '{}',
  published boolean not null default true
);

create table if not exists public.practice_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  session_type text not null check (session_type in ('daily', 'category')),
  category text,
  question_count integer not null check (question_count between 1 and 20),
  correct_count integer not null check (correct_count between 0 and question_count),
  xp_earned integer not null check (xp_earned >= 0),
  completed_at timestamptz not null default now()
);

create table if not exists public.session_answers (
  id bigint generated always as identity primary key,
  session_id uuid not null references public.practice_sessions(id) on delete cascade,
  question_id text not null references public.questions(id),
  submitted_answer text not null,
  is_correct boolean not null
);

create table if not exists public.daily_progress (
  user_id uuid not null references public.profiles(id) on delete cascade,
  practice_date date not null,
  session_id uuid not null references public.practice_sessions(id) on delete cascade,
  completed_at timestamptz not null default now(),
  primary key (user_id, practice_date)
);

alter table public.profiles enable row level security;
alter table public.questions enable row level security;
alter table public.practice_sessions enable row level security;
alter table public.session_answers enable row level security;
alter table public.daily_progress enable row level security;

revoke update on public.profiles from authenticated;
grant update (username, display_name) on public.profiles to authenticated;

create policy "profiles are visible to signed-in users" on public.profiles for select to authenticated using (true);
create policy "users update their public identity" on public.profiles for update to authenticated
  using (auth.uid() = id) with check (auth.uid() = id);
create policy "published question ids are readable" on public.questions for select to authenticated using (published);
create policy "users read own sessions" on public.practice_sessions for select to authenticated using (auth.uid() = user_id);
create policy "users read own answers" on public.session_answers for select to authenticated
  using (exists (select 1 from public.practice_sessions s where s.id = session_id and s.user_id = auth.uid()));
create policy "users read own daily progress" on public.daily_progress for select to authenticated using (auth.uid() = user_id);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  requested_username text;
begin
  requested_username := lower(coalesce(new.raw_user_meta_data ->> 'username', split_part(new.email, '@', 1)));
  requested_username := regexp_replace(requested_username, '[^a-z0-9_]', '', 'g');
  if char_length(requested_username) < 3 then requested_username := 'player'; end if;
  requested_username := left(requested_username, 24);

  begin
    insert into public.profiles (id, username, display_name)
    values (new.id, requested_username, left(coalesce(nullif(new.raw_user_meta_data ->> 'display_name', ''), requested_username), 40));
  exception when unique_violation then
    requested_username := left(requested_username, 17) || '_' || substr(new.id::text, 1, 6);
    insert into public.profiles (id, username, display_name)
    values (new.id, requested_username, left(coalesce(nullif(new.raw_user_meta_data ->> 'display_name', ''), requested_username), 40));
  end;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();

insert into public.profiles (id, username, display_name)
select id, 'player_' || substr(id::text, 1, 8), coalesce(nullif(raw_user_meta_data ->> 'display_name', ''), 'QuizForge Player')
from auth.users
on conflict (id) do nothing;

insert into public.questions (id, accepted_answer, aliases) values
  ('q1', 'U.S. Constitution', array['constitution','the constitution','united states constitution']),
  ('q2', 'Oxygen', array['oxygen','o']),
  ('q3', '1984', array['1984','nineteen eighty four']),
  ('q4', 'Vincent van Gogh', array['van gogh','vincent van gogh']),
  ('q5', 'Canberra', array['canberra']),
  ('q6', 'Marbury v. Madison', array['marbury v madison','marbury versus madison','marbury']),
  ('q7', 'Poseidon', array['poseidon']),
  ('q8', 'Pythagorean theorem', array['pythagorean theorem','pythagoras theorem']),
  ('q9', 'Mitochondrion', array['mitochondria','mitochondrion']),
  ('q10', 'Ottoman Empire', array['ottomans','ottoman empire'])
on conflict (id) do update set accepted_answer = excluded.accepted_answer, aliases = excluded.aliases;

create or replace function public.normalize_quiz_answer(value text)
returns text language sql immutable parallel safe set search_path = '' as $$
  select trim(regexp_replace(regexp_replace(lower(coalesce(value, '')), '[^a-z0-9 ]', '', 'g'), '\s+', ' ', 'g'));
$$;

create or replace function public.complete_practice_session(
  p_session_type text,
  p_category text,
  p_answers jsonb,
  p_timezone text default 'UTC'
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  uid uuid := auth.uid();
  item jsonb;
  question public.questions%rowtype;
  session_id uuid := gen_random_uuid();
  answer_count integer := jsonb_array_length(p_answers);
  correct_count integer := 0;
  earned_xp integer;
  daily_bonus integer := 0;
  practice_day date;
  first_daily boolean := false;
  inserted_daily_count integer := 0;
  profile public.profiles%rowtype;
  submitted text;
begin
  if uid is null then raise exception 'Authentication required'; end if;
  if p_session_type not in ('daily', 'category') then raise exception 'Invalid session type'; end if;
  if jsonb_typeof(p_answers) <> 'array' or answer_count < 1 or answer_count > 20 then raise exception 'A session must contain 1-20 answers'; end if;
  begin
    practice_day := (now() at time zone p_timezone)::date;
  exception when invalid_parameter_value then
    raise exception 'Invalid timezone';
  end;

  for item in select value from jsonb_array_elements(p_answers)
  loop
    select * into question from public.questions where id = item ->> 'questionId' and published;
    if not found then raise exception 'Unknown question'; end if;
    submitted := left(coalesce(item ->> 'submitted', ''), 200);
    if public.normalize_quiz_answer(submitted) = any(
      array(select public.normalize_quiz_answer(v) from unnest(array_prepend(question.accepted_answer, question.aliases)) v)
    ) then correct_count := correct_count + 1; end if;
  end loop;

  earned_xp := correct_count * 10;
  insert into public.practice_sessions (id, user_id, session_type, category, question_count, correct_count, xp_earned)
  values (session_id, uid, p_session_type, nullif(left(p_category, 50), ''), answer_count, correct_count, 0);

  for item in select value from jsonb_array_elements(p_answers)
  loop
    select * into question from public.questions where id = item ->> 'questionId';
    submitted := left(coalesce(item ->> 'submitted', ''), 200);
    insert into public.session_answers (session_id, question_id, submitted_answer, is_correct)
    values (session_id, question.id, submitted,
      public.normalize_quiz_answer(submitted) = any(array(select public.normalize_quiz_answer(v) from unnest(array_prepend(question.accepted_answer, question.aliases)) v)));
  end loop;

  if p_session_type = 'daily' then
    insert into public.daily_progress (user_id, practice_date, session_id) values (uid, practice_day, session_id)
    on conflict do nothing;
    get diagnostics inserted_daily_count = row_count;
    first_daily := inserted_daily_count = 1;
    if first_daily then
      daily_bonus := 20 + case when correct_count = answer_count then 25 else 0 end;
    end if;
  end if;
  earned_xp := earned_xp + daily_bonus;
  update public.practice_sessions set xp_earned = earned_xp where id = session_id;

  select * into profile from public.profiles where id = uid for update;
  if first_daily then
    profile.current_streak := case when profile.last_daily_completed_on = practice_day - 1 then profile.current_streak + 1 else 1 end;
    profile.longest_streak := greatest(profile.longest_streak, profile.current_streak);
    profile.last_daily_completed_on := practice_day;
  end if;
  update public.profiles set
    total_xp = total_xp + earned_xp,
    total_answered = total_answered + answer_count,
    total_correct = total_correct + correct_count,
    current_streak = profile.current_streak,
    longest_streak = profile.longest_streak,
    last_daily_completed_on = profile.last_daily_completed_on,
    updated_at = now()
  where id = uid returning * into profile;

  return jsonb_build_object(
    'sessionId', session_id, 'xpEarned', earned_xp, 'correctCount', correct_count,
    'profile', jsonb_build_object('xp', profile.total_xp, 'streak', profile.current_streak, 'longest', profile.longest_streak,
      'answered', profile.total_answered, 'correct', profile.total_correct, 'done', profile.last_daily_completed_on)
  );
end;
$$;

revoke all on function public.complete_practice_session(text, text, jsonb, text) from public;
grant execute on function public.complete_practice_session(text, text, jsonb, text) to authenticated;
