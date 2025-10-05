-- Create user_achievements table for tracking earned achievements
create table public.user_achievements (
  id uuid primary key default gen_random_uuid(),

  -- References
  user_id uuid references auth.users(id) on delete cascade not null,
  achievement_id uuid references public.achievements(id) on delete cascade not null,

  -- Progress tracking (for multi-step achievements)
  progress numeric(10, 2) not null default 0,
  is_completed boolean not null default false,

  -- Timestamps
  earned_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  -- Constraints
  unique(user_id, achievement_id), -- User can earn each achievement only once
  check (is_completed = false or earned_at is not null)
);

-- Enable RLS
alter table public.user_achievements enable row level security;

-- RLS Policies

-- Users can view their own achievements
create policy "Users can view own achievements"
  on public.user_achievements for select
  to authenticated
  using (user_id = (select auth.uid()));

-- Users can view other users' completed achievements (for profile viewing)
create policy "Anyone can view completed achievements"
  on public.user_achievements for select
  to authenticated
  using (is_completed = true);

-- System can create/update achievements (via triggers)
create policy "System can manage achievements"
  on public.user_achievements for all
  to authenticated
  using (true)
  with check (true);

-- Admins can view all achievements
create policy "Admins can view all achievements"
  on public.user_achievements for select
  to authenticated
  using (public.is_user_admin((select auth.uid())));

-- Indexes
create index user_achievements_user_id_idx on public.user_achievements(user_id);
create index user_achievements_achievement_id_idx on public.user_achievements(achievement_id);
create index user_achievements_is_completed_idx on public.user_achievements(is_completed);
create index user_achievements_earned_at_idx on public.user_achievements(earned_at desc);

-- Trigger for updated_at
create trigger update_user_achievements_updated_at
  before update on public.user_achievements
  for each row
  execute function public.update_updated_at_column();

-- Function to check and award achievements
create or replace function public.check_and_award_achievements(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_achievement record;
  v_user_profile record;
  v_requirement_met boolean;
  v_current_value numeric(10, 2);
begin
  -- Get user profile stats
  select * into v_user_profile
  from public.user_profiles
  where id = p_user_id;

  if not found then
    return;
  end if;

  -- Loop through all achievements
  for v_achievement in
    select * from public.achievements
  loop
    -- Skip if user already completed this achievement
    if exists (
      select 1 from public.user_achievements
      where user_id = p_user_id
      and achievement_id = v_achievement.id
      and is_completed = true
    ) then
      continue;
    end if;

    -- Check if requirement is met based on type
    v_requirement_met := false;
    v_current_value := 0;

    case v_achievement.requirement_type
      when 'total_hours_fasted' then
        v_current_value := v_user_profile.total_hours_fasted;
        v_requirement_met := v_current_value >= v_achievement.requirement_value;

      when 'total_fasts_completed' then
        v_current_value := v_user_profile.total_fasts_completed;
        v_requirement_met := v_current_value >= v_achievement.requirement_value;

      when 'longest_fast_hours' then
        v_current_value := v_user_profile.longest_fast_hours;
        v_requirement_met := v_current_value >= v_achievement.requirement_value;

      when 'consecutive_days_active' then
        v_current_value := v_user_profile.current_streak_days;
        v_requirement_met := v_current_value >= v_achievement.requirement_value;

      when 'group_fasts_joined' then
        select count(*) into v_current_value
        from public.fast_participants
        where user_id = p_user_id;
        v_requirement_met := v_current_value >= v_achievement.requirement_value;

      when 'group_fasts_created' then
        select count(*) into v_current_value
        from public.group_fasts
        where creator_id = p_user_id;
        v_requirement_met := v_current_value >= v_achievement.requirement_value;

      when 'chat_messages_sent' then
        select count(*) into v_current_value
        from public.chat_messages
        where user_id = p_user_id
        and is_deleted = false;
        v_requirement_met := v_current_value >= v_achievement.requirement_value;

      else
        -- Custom achievements handled separately
        continue;
    end case;

    -- Insert or update user achievement
    insert into public.user_achievements (
      user_id,
      achievement_id,
      progress,
      is_completed,
      earned_at
    )
    values (
      p_user_id,
      v_achievement.id,
      v_current_value,
      v_requirement_met,
      case when v_requirement_met then now() else null end
    )
    on conflict (user_id, achievement_id)
    do update set
      progress = v_current_value,
      is_completed = v_requirement_met,
      earned_at = case when v_requirement_met then now() else user_achievements.earned_at end,
      updated_at = now();

    -- If achievement was just earned, create notification
    if v_requirement_met and not exists (
      select 1 from public.user_achievements
      where user_id = p_user_id
      and achievement_id = v_achievement.id
      and is_completed = true
    ) then
      insert into public.notifications (
        user_id,
        type,
        title,
        message,
        related_entity_type,
        related_entity_id
      )
      values (
        p_user_id,
        'achievement_earned',
        'Achievement Unlocked!',
        'You earned: ' || v_achievement.name,
        'achievement',
        v_achievement.id
      );
    end if;
  end loop;
end;
$$;

-- Trigger to check achievements when user profile is updated
create or replace function public.check_achievements_on_profile_update()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  -- Check achievements asynchronously (in reality, would use a background job)
  perform public.check_and_award_achievements(new.id);
  return new;
end;
$$;

create trigger check_achievements_after_profile_update
  after update on public.user_profiles
  for each row
  when (
    old.total_fasts_completed != new.total_fasts_completed
    or old.total_hours_fasted != new.total_hours_fasted
    or old.longest_fast_hours != new.longest_fast_hours
    or old.current_streak_days != new.current_streak_days
  )
  execute function public.check_achievements_on_profile_update();
