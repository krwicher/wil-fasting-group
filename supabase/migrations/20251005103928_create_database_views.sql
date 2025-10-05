-- Database views for common queries and leaderboards

-- View: Leaderboard for a specific group fast
create or replace view public.group_fast_leaderboard as
select
  fp.id,
  fp.group_fast_id,
  fp.user_id,
  fp.started_at,
  fp.ended_at,
  fp.target_duration_hours,
  fp.status,
  up.display_name,
  up.avatar_url,
  -- Calculate hours fasted
  case
    when fp.started_at is not null then
      extract(epoch from (coalesce(fp.ended_at, now()) - fp.started_at)) / 3600
    else 0
  end as hours_fasted,
  -- Calculate progress percentage
  case
    when fp.started_at is not null then
      least(
        (extract(epoch from (coalesce(fp.ended_at, now()) - fp.started_at)) / 3600 / fp.target_duration_hours * 100),
        100
      )
    else 0
  end as progress_percentage,
  -- Rank by hours fasted (absolute, not percentage)
  rank() over (
    partition by fp.group_fast_id
    order by
      case when fp.started_at is not null then
        extract(epoch from (coalesce(fp.ended_at, now()) - fp.started_at)) / 3600
      else 0
      end desc
  ) as rank
from public.fast_participants fp
join public.user_profiles up on up.id = fp.user_id
where fp.started_at is not null
order by fp.group_fast_id, hours_fasted desc;

-- View: Global leaderboard (all-time stats)
create or replace view public.global_leaderboard as
select
  up.id as user_id,
  up.display_name,
  up.avatar_url,
  up.total_fasts_completed,
  up.total_hours_fasted,
  up.longest_fast_hours,
  up.current_streak_days,
  -- Rank by total hours fasted
  rank() over (order by up.total_hours_fasted desc) as rank_total_hours,
  -- Rank by longest fast
  rank() over (order by up.longest_fast_hours desc) as rank_longest_fast,
  -- Rank by total fasts completed
  rank() over (order by up.total_fasts_completed desc) as rank_total_fasts,
  -- Rank by current streak
  rank() over (order by up.current_streak_days desc) as rank_streak
from public.user_profiles up
where up.total_fasts_completed > 0
order by up.total_hours_fasted desc;

-- View: Active fasts summary
create or replace view public.active_fasts_summary as
select
  gf.id,
  gf.name,
  gf.description,
  gf.creator_id,
  gf.start_time,
  gf.target_duration_hours,
  gf.status,
  gf.is_public,
  gf.participant_count,
  gf.active_participant_count,
  gf.max_participants,
  gf.allow_late_join,
  gf.chat_enabled,
  gf.created_at,
  -- Creator info
  up.display_name as creator_name,
  up.avatar_url as creator_avatar,
  -- Calculate if fast is full
  (gf.max_participants is not null and gf.participant_count >= gf.max_participants) as is_full,
  -- Calculate if fast has started
  (gf.start_time <= now()) as has_started,
  -- Calculate if late join is allowed
  (gf.allow_late_join or gf.start_time > now()) as can_join
from public.group_fasts gf
join public.user_profiles up on up.id = gf.creator_id
where gf.status in ('upcoming', 'active')
order by gf.start_time;

-- View: User's fast history
create or replace view public.user_fast_history as
select
  'group' as fast_type,
  fp.id,
  fp.user_id,
  gf.name as fast_name,
  fp.started_at,
  fp.ended_at,
  fp.target_duration_hours,
  fp.status,
  case
    when fp.started_at is not null and fp.ended_at is not null then
      extract(epoch from (fp.ended_at - fp.started_at)) / 3600
    else null
  end as hours_fasted,
  fp.created_at
from public.fast_participants fp
join public.group_fasts gf on gf.id = fp.group_fast_id
where fp.started_at is not null

union all

select
  'personal' as fast_type,
  pf.id,
  pf.user_id,
  coalesce(pf.name, 'Personal Fast') as fast_name,
  pf.started_at,
  pf.ended_at,
  pf.target_duration_hours,
  pf.status,
  case
    when pf.ended_at is not null then
      extract(epoch from (pf.ended_at - pf.started_at)) / 3600
    else null
  end as hours_fasted,
  pf.created_at
from public.personal_fasts pf

order by created_at desc;

-- View: Pending user approvals (admin only)
create or replace view public.pending_user_approvals as
select
  u.id,
  u.email,
  u.created_at,
  u.raw_user_meta_data->>'full_name' as full_name,
  u.raw_user_meta_data->>'role' as role,
  u.raw_user_meta_data->>'timezone' as timezone,
  up.display_name,
  up.bio
from auth.users u
left join public.user_profiles up on up.id = u.id
where (u.raw_user_meta_data->>'role')::public.user_role = 'pending'
order by u.created_at;

-- View: Recent activity feed
create or replace view public.recent_activity as
select
  'fast_completed' as activity_type,
  fp.user_id,
  fp.created_at as activity_time,
  jsonb_build_object(
    'fast_name', gf.name,
    'hours_fasted', extract(epoch from (fp.ended_at - fp.started_at)) / 3600,
    'fast_type', 'group'
  ) as activity_data
from public.fast_participants fp
join public.group_fasts gf on gf.id = fp.group_fast_id
where fp.status in ('completed', 'extended')
and fp.ended_at is not null

union all

select
  'fast_completed' as activity_type,
  pf.user_id,
  pf.created_at as activity_time,
  jsonb_build_object(
    'fast_name', coalesce(pf.name, 'Personal Fast'),
    'hours_fasted', extract(epoch from (pf.ended_at - pf.started_at)) / 3600,
    'fast_type', 'personal'
  ) as activity_data
from public.personal_fasts pf
where pf.status in ('completed', 'extended')
and pf.ended_at is not null

union all

select
  'achievement_earned' as activity_type,
  ua.user_id,
  ua.earned_at as activity_time,
  jsonb_build_object(
    'achievement_name', a.name,
    'achievement_icon', a.icon,
    'achievement_tier', a.tier
  ) as activity_data
from public.user_achievements ua
join public.achievements a on a.id = ua.achievement_id
where ua.is_completed = true
and ua.earned_at is not null

union all

select
  'group_fast_created' as activity_type,
  gf.creator_id as user_id,
  gf.created_at as activity_time,
  jsonb_build_object(
    'fast_name', gf.name,
    'start_time', gf.start_time,
    'target_hours', gf.target_duration_hours
  ) as activity_data
from public.group_fasts gf

order by activity_time desc;

-- Grant access to views (same as underlying tables)
grant select on public.group_fast_leaderboard to authenticated;
grant select on public.global_leaderboard to authenticated;
grant select on public.active_fasts_summary to authenticated;
grant select on public.user_fast_history to authenticated;
grant select on public.pending_user_approvals to authenticated;
grant select on public.recent_activity to authenticated;
