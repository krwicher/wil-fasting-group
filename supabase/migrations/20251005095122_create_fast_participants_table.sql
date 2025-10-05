-- Create fast_participants table for tracking user participation in group fasts
create table public.fast_participants (
  id uuid primary key default gen_random_uuid(),

  -- References
  group_fast_id uuid references public.group_fasts(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade not null,

  -- Target and progress
  target_duration_hours integer not null check (target_duration_hours > 0),

  -- Timing
  joined_at timestamptz not null default now(),
  started_at timestamptz, -- When user actually started their timer
  ended_at timestamptz,   -- When user ended their fast

  -- Status
  status public.participation_status not null default 'active',

  -- Notes and tracking
  notes text,
  quit_reason text,

  -- Timestamps
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  -- Constraints
  unique(group_fast_id, user_id), -- User can only join a group fast once
  check (ended_at is null or ended_at >= started_at),
  check (started_at is null or started_at >= joined_at)
);

-- Enable RLS
alter table public.fast_participants enable row level security;

-- RLS Policies

-- Participants can view others in the same fast
create policy "Participants can view same fast participants"
  on public.fast_participants for select
  to authenticated
  using (
    exists (
      select 1 from public.group_fasts
      where id = group_fast_id
      and (is_public = true or creator_id = auth.uid())
    )
    or user_id = auth.uid()
  );

-- Approved users can join group fasts
create policy "Approved users can join fasts"
  on public.fast_participants for insert
  to authenticated
  with check (
    public.is_user_approved(auth.uid())
    and user_id = auth.uid()
    -- Check user doesn't already have an active group fast
    and not exists (
      select 1 from public.fast_participants
      where user_id = auth.uid()
      and status = 'active'
      and id != fast_participants.id
    )
  );

-- Users can update their own participation
create policy "Users can update own participation"
  on public.fast_participants for update
  to authenticated
  using (user_id = auth.uid());

-- Admins can update any participation
create policy "Admins can update any participation"
  on public.fast_participants for update
  to authenticated
  using (public.is_user_admin(auth.uid()));

-- Users can delete their own participation (leave fast)
create policy "Users can delete own participation"
  on public.fast_participants for delete
  to authenticated
  using (user_id = auth.uid());

-- Admins can remove any participant
create policy "Admins can remove any participant"
  on public.fast_participants for delete
  to authenticated
  using (public.is_user_admin(auth.uid()));

-- Indexes
create index fast_participants_group_fast_id_idx on public.fast_participants(group_fast_id);
create index fast_participants_user_id_idx on public.fast_participants(user_id);
create index fast_participants_status_idx on public.fast_participants(status);
create index fast_participants_started_at_idx on public.fast_participants(started_at);

-- Trigger for updated_at
create trigger update_fast_participants_updated_at
  before update on public.fast_participants
  for each row
  execute function public.update_updated_at_column();

-- Function to update group_fasts participant counts
create or replace function public.update_group_fast_participant_count()
returns trigger
language plpgsql
as $$
begin
  -- Update participant counts for the affected group fast
  update public.group_fasts
  set
    participant_count = (
      select count(*)
      from public.fast_participants
      where group_fast_id = coalesce(new.group_fast_id, old.group_fast_id)
    ),
    active_participant_count = (
      select count(*)
      from public.fast_participants
      where group_fast_id = coalesce(new.group_fast_id, old.group_fast_id)
      and status = 'active'
    )
  where id = coalesce(new.group_fast_id, old.group_fast_id);

  return coalesce(new, old);
end;
$$;

-- Trigger to update participant counts
create trigger update_participant_counts_on_insert
  after insert on public.fast_participants
  for each row
  execute function public.update_group_fast_participant_count();

create trigger update_participant_counts_on_update
  after update on public.fast_participants
  for each row
  execute function public.update_group_fast_participant_count();

create trigger update_participant_counts_on_delete
  after delete on public.fast_participants
  for each row
  execute function public.update_group_fast_participant_count();

-- Function to update user profile statistics
create or replace function public.update_user_profile_stats()
returns trigger
language plpgsql
as $$
declare
  v_hours_fasted numeric(10, 2);
begin
  -- Only update stats when participation is completed
  if new.status in ('completed', 'quit_early', 'extended') and new.ended_at is not null then
    -- Calculate hours fasted
    v_hours_fasted := extract(epoch from (new.ended_at - new.started_at)) / 3600;

    update public.user_profiles
    set
      total_fasts_completed = total_fasts_completed + 1,
      total_hours_fasted = total_hours_fasted + v_hours_fasted,
      longest_fast_hours = greatest(longest_fast_hours, v_hours_fasted)
    where id = new.user_id;
  end if;

  return new;
end;
$$;

-- Trigger to update user stats when fast is completed
create trigger update_user_stats_on_fast_completion
  after update on public.fast_participants
  for each row
  when (old.status = 'active' and new.status in ('completed', 'quit_early', 'extended'))
  execute function public.update_user_profile_stats();
