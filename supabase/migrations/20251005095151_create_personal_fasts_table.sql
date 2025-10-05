-- Create personal_fasts table for solo fasting tracking
create table public.personal_fasts (
  id uuid primary key default gen_random_uuid(),

  -- Owner
  user_id uuid references auth.users(id) on delete cascade not null,

  -- Basic information
  name text check (char_length(name) >= 3 and char_length(name) <= 100),
  notes text check (char_length(notes) <= 2000),

  -- Target
  target_duration_hours integer not null check (target_duration_hours > 0 and target_duration_hours <= 336), -- Max 14 days

  -- Timing
  started_at timestamptz not null default now(),
  ended_at timestamptz,

  -- Status
  status public.participation_status not null default 'active',

  -- Tracking
  quit_reason text,

  -- Timestamps
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  -- Constraints
  check (ended_at is null or ended_at >= started_at)
);

-- Enable RLS
alter table public.personal_fasts enable row level security;

-- RLS Policies

-- Users can view their own personal fasts
create policy "Users can view own personal fasts"
  on public.personal_fasts for select
  to authenticated
  using (user_id = auth.uid());

-- Approved users can create personal fasts
create policy "Approved users can create personal fasts"
  on public.personal_fasts for insert
  to authenticated
  with check (
    public.is_user_approved(auth.uid())
    and user_id = auth.uid()
    -- Check user doesn't already have an active personal fast
    and not exists (
      select 1 from public.personal_fasts
      where user_id = auth.uid()
      and status = 'active'
      and id != personal_fasts.id
    )
  );

-- Users can update their own personal fasts
create policy "Users can update own personal fasts"
  on public.personal_fasts for update
  to authenticated
  using (user_id = auth.uid());

-- Users can delete their own personal fasts
create policy "Users can delete own personal fasts"
  on public.personal_fasts for delete
  to authenticated
  using (user_id = auth.uid());

-- Admins can view all personal fasts
create policy "Admins can view all personal fasts"
  on public.personal_fasts for select
  to authenticated
  using (public.is_user_admin(auth.uid()));

-- Indexes
create index personal_fasts_user_id_idx on public.personal_fasts(user_id);
create index personal_fasts_status_idx on public.personal_fasts(status);
create index personal_fasts_started_at_idx on public.personal_fasts(started_at);

-- Trigger for updated_at
create trigger update_personal_fasts_updated_at
  before update on public.personal_fasts
  for each row
  execute function public.update_updated_at_column();

-- Function to update user profile statistics for personal fasts
create or replace function public.update_user_profile_stats_personal()
returns trigger
language plpgsql
as $$
declare
  v_hours_fasted numeric(10, 2);
begin
  -- Only update stats when fast is completed
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

-- Trigger to update user stats when personal fast is completed
create trigger update_user_stats_on_personal_fast_completion
  after update on public.personal_fasts
  for each row
  when (old.status = 'active' and new.status in ('completed', 'quit_early', 'extended'))
  execute function public.update_user_profile_stats_personal();
