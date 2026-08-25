create extension if not exists fuzzystrmatch with schema extensions;

create or replace function public.normalize_quiz_answer(value text)
returns text language sql immutable parallel safe set search_path = '' as $$
  select regexp_replace(
    trim(regexp_replace(regexp_replace(lower(coalesce(value, '')), '[^a-z0-9[:space:]]', ' ', 'g'), '\s+', ' ', 'g')),
    '^(the|a|an)\s+',
    ''
  );
$$;

create or replace function public.quiz_answers_match(submitted text, accepted text)
returns boolean language sql immutable parallel safe set search_path = '' as $$
  with normalized as (
    select
      public.normalize_quiz_answer(submitted) as submitted,
      public.normalize_quiz_answer(accepted) as accepted
  ), measured as (
    select *, greatest(char_length(submitted), char_length(accepted)) as answer_length
    from normalized
  )
  select submitted = accepted or (
    answer_length >= 5
    and extensions.levenshtein(submitted, accepted) <= case when answer_length >= 10 then 2 else 1 end
    and extensions.levenshtein(submitted, accepted)::numeric / answer_length <= 0.15
  )
  from measured;
$$;

create or replace function public.check_practice_answer(
  p_question_id text,
  p_submitted text
) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  quiz_question public.questions%rowtype;
  is_correct boolean;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if char_length(coalesce(p_submitted, '')) > 200 then raise exception 'Answer is too long'; end if;

  select * into quiz_question
  from public.questions
  where id = p_question_id and published and question is not null;
  if not found then raise exception 'Unknown question'; end if;

  is_correct := exists(
    select 1
    from unnest(array_prepend(quiz_question.accepted_answer, quiz_question.aliases)) value
    where public.quiz_answers_match(p_submitted, value)
  );

  return jsonb_build_object(
    'correct', is_correct,
    'correctAnswer', quiz_question.correct_answer,
    'explanation', quiz_question.explanation
  );
end;
$$;

create or replace function public.complete_practice_session(
  p_session_type text, p_category text, p_answers jsonb, p_timezone text default 'UTC'
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  uid uuid := auth.uid();
  item jsonb;
  quiz_question public.questions%rowtype;
  session_id uuid := gen_random_uuid();
  answer_count integer;
  correct_count integer := 0;
  earned_xp integer;
  daily_bonus integer := 0;
  practice_day date;
  first_daily boolean := false;
  inserted_daily_count integer := 0;
  profile public.profiles%rowtype;
  submitted text;
  is_correct boolean;
begin
  if uid is null then raise exception 'Authentication required'; end if;
  if p_session_type not in ('daily', 'category') then raise exception 'Invalid session type'; end if;
  if jsonb_typeof(p_answers) <> 'array' then raise exception 'Answers must be an array'; end if;
  answer_count := jsonb_array_length(p_answers);
  if answer_count < 1 or answer_count > 20 then raise exception 'A session must contain 1-20 answers'; end if;
  if (select count(distinct value ->> 'questionId') from jsonb_array_elements(p_answers)) <> answer_count then
    raise exception 'A question can only be answered once per session';
  end if;

  begin
    practice_day := (now() at time zone p_timezone)::date;
  exception when invalid_parameter_value then
    raise exception 'Invalid timezone';
  end;

  for item in select value from jsonb_array_elements(p_answers)
  loop
    select * into quiz_question from public.questions
    where id = item ->> 'questionId' and published;
    if not found then raise exception 'Unknown question'; end if;
    submitted := left(coalesce(item ->> 'submitted', ''), 200);
    is_correct := exists(
      select 1 from unnest(array_prepend(quiz_question.accepted_answer, quiz_question.aliases)) value
      where public.quiz_answers_match(submitted, value)
    );
    if is_correct then correct_count := correct_count + 1; end if;
  end loop;

  earned_xp := correct_count * 10;
  insert into public.practice_sessions (
    id, user_id, session_type, category, question_count, correct_count, xp_earned
  ) values (
    session_id, uid, p_session_type, nullif(left(p_category, 50), ''),
    answer_count, correct_count, 0
  );

  for item in select value from jsonb_array_elements(p_answers)
  loop
    select * into quiz_question from public.questions where id = item ->> 'questionId';
    submitted := left(coalesce(item ->> 'submitted', ''), 200);
    is_correct := exists(
      select 1 from unnest(array_prepend(quiz_question.accepted_answer, quiz_question.aliases)) value
      where public.quiz_answers_match(submitted, value)
    );
    insert into public.session_answers (session_id, question_id, submitted_answer, is_correct)
    values (session_id, quiz_question.id, submitted, is_correct);
  end loop;

  if p_session_type = 'daily' then
    insert into public.daily_progress (user_id, practice_date, session_id)
    values (uid, practice_day, session_id) on conflict do nothing;
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
    profile.current_streak := case
      when profile.last_daily_completed_on = practice_day - 1 then profile.current_streak + 1
      else 1
    end;
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
    'profile', jsonb_build_object(
      'xp', profile.total_xp, 'streak', profile.current_streak,
      'longest', profile.longest_streak, 'answered', profile.total_answered,
      'correct', profile.total_correct, 'done', profile.last_daily_completed_on
    )
  );
end;
$$;

revoke all on function public.quiz_answers_match(text, text) from public;
