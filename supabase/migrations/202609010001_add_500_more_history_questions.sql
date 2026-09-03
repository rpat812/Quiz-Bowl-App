-- Add a third 500-question History batch. This migration builds five new
-- clue formulations from each of the 100 audited milestones in batch 2.

with milestone_sources as (
  select
    row_number() over(order by id)::integer as milestone_no,
    subcategory,
    difficulty,
    region,
    time_period,
    tags[1] as event_name,
    tags[2] as figure,
    tags[3] as place,
    accepted_answer as event_year,
    explanation
  from public.questions
  where id between 'HIST-0101' and 'HIST-0600'
    and (substring(id from 6)::integer - 101) % 5 = 0
), angles(angle_no) as (
  select generate_series(1, 5)
), generated as (
  select
    'HIST-' || lpad((600 + (m.milestone_no - 1) * 5 + a.angle_no)::text, 4, '0') as id,
    m.*,
    a.angle_no,
    case a.angle_no
      when 1 then format('Place %s on a timeline. In what year did it occur?', m.event_name)
      when 2 then format('Name the location where %s took place.', m.event_name)
      when 3 then format('Which historical figure or group is linked to %s at %s?', m.event_name, m.place)
      when 4 then format('What event is associated with %s in %s during %s?', m.figure, m.place, m.event_year)
      else format('Complete the historical statement: In %s, %s was connected to %s at ____.', m.event_year, m.figure, m.event_name)
    end as question,
    case a.angle_no
      when 1 then m.event_year
      when 2 then m.place
      when 3 then m.figure
      when 4 then m.event_name
      else m.place
    end as answer
  from milestone_sources m cross join angles a
)
insert into public.questions (
  id, accepted_answer, aliases, published, category, subcategory, difficulty,
  question_type, region, time_period, tags, question, options,
  correct_answer, explanation, content_status
)
select
  id,
  answer,
  '{}',
  true,
  'History',
  subcategory,
  difficulty,
  'short_answer',
  region,
  time_period,
  array[event_name, figure, place],
  question,
  '[]'::jsonb,
  to_jsonb(answer),
  explanation,
  'published'
from generated
on conflict (id) do update set
  accepted_answer = excluded.accepted_answer,
  aliases = excluded.aliases,
  published = excluded.published,
  category = excluded.category,
  subcategory = excluded.subcategory,
  difficulty = excluded.difficulty,
  question_type = excluded.question_type,
  region = excluded.region,
  time_period = excluded.time_period,
  tags = excluded.tags,
  question = excluded.question,
  options = excluded.options,
  correct_answer = excluded.correct_answer,
  explanation = excluded.explanation,
  content_status = excluded.content_status,
  updated_at = now();

do $$
begin
  if (select count(*) from public.questions where id between 'HIST-0601' and 'HIST-1100') <> 500 then
    raise exception 'Expected exactly 500 questions in history batch 3; apply batch 2 first';
  end if;
end;
$$;
