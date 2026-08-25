create or replace function public.get_leaderboard(
  p_period text default 'weekly',
  p_limit integer default 50
) returns table (
  rank bigint,
  display_name text,
  username text,
  xp bigint,
  is_current_user boolean
)
language plpgsql stable security definer set search_path = '' as $$
declare
  leaderboard_limit integer := greatest(1, least(coalesce(p_limit, 50), 100));
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if p_period not in ('weekly', 'all_time') then raise exception 'Invalid leaderboard period'; end if;

  return query
  with scores as (
    select
      profile.id as profile_id,
      profile.display_name as profile_display_name,
      profile.username as profile_username,
      case
        when p_period = 'all_time' then profile.total_xp::bigint
        else coalesce(sum(practice_session.xp_earned) filter (
          where practice_session.completed_at >= date_trunc('week', now())
        ), 0)::bigint
      end as score
    from public.profiles as profile
    left join public.practice_sessions as practice_session
      on practice_session.user_id = profile.id
    group by profile.id, profile.display_name, profile.username, profile.total_xp
  ), ranked_scores as (
    select
      row_number() over (
        order by scores.score desc, scores.profile_display_name asc, scores.profile_id asc
      ) as position,
      scores.profile_id,
      scores.profile_display_name,
      scores.profile_username,
      scores.score
    from scores
  )
  select
    ranked_scores.position,
    ranked_scores.profile_display_name,
    ranked_scores.profile_username,
    ranked_scores.score,
    ranked_scores.profile_id = auth.uid()
  from ranked_scores
  order by ranked_scores.position
  limit leaderboard_limit;
end;
$$;

revoke all on function public.get_leaderboard(text, integer) from public;
grant execute on function public.get_leaderboard(text, integer) to authenticated;
