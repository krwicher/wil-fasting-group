-- Create group_fasts table for multi-day group fasting events
create table public.group_fasts (
  id uuid primary key default gen_random_uuid(),

  -- Basic information
  name text not null check (char_length(name) >= 3 and char_length(name) <= 100),
  description text check (char_length(description) <= 1000),

  -- Creator and ownership
  creator_id uuid references auth.users(id) on delete cascade not null,

  -- Timing
  start_time timestamptz not null,
  target_duration_hours integer not null check (target_duration_hours > 0 and target_duration_hours <= 336), -- Max 14 days

  -- Status
  status public.fast_status not null default 'upcoming',

  -- Settings
  is_public boolean not null default true,
  max_participants integer check (max_participants > 0 and max_participants <= 1000),
  allow_late_join boolean not null default true,
  chat_enabled boolean not null default true,

  -- Statistics (updated by triggers)
  participant_count integer not null default 0,
  active_participant_count integer not null default 0,

  -- Timestamps
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Enable RLS
alter table public.group_fasts enable row level security;

-- RLS Policies

-- Anyone can view public group fasts
create policy "Anyone can view public group fasts"
  on public.group_fasts for select
  to authenticated
  using (is_public = true or creator_id = auth.uid());

-- Approved users can create group fasts
create policy "Approved users can create group fasts"
  on public.group_fasts for insert
  to authenticated
  with check (public.is_user_approved(auth.uid()));

-- Creators can update their own fasts
create policy "Creators can update own fasts"
  on public.group_fasts for update
  to authenticated
  using (creator_id = auth.uid());

-- Admins can update any fast
create policy "Admins can update any fast"
  on public.group_fasts for update
  to authenticated
  using (public.is_user_admin(auth.uid()));

-- Admins can delete any fast
create policy "Admins can delete any fast"
  on public.group_fasts for delete
  to authenticated
  using (public.is_user_admin(auth.uid()));

-- Creators can delete their own fasts (if no participants or only upcoming)
create policy "Creators can delete own fasts"
  on public.group_fasts for delete
  to authenticated
  using (
    creator_id = auth.uid()
    and (participant_count = 0 or status = 'upcoming')
  );

-- Indexes
create index group_fasts_creator_id_idx on public.group_fasts(creator_id);
create index group_fasts_status_idx on public.group_fasts(status);
create index group_fasts_start_time_idx on public.group_fasts(start_time);
create index group_fasts_created_at_idx on public.group_fasts(created_at);
create index group_fasts_public_status_idx on public.group_fasts(is_public, status) where is_public = true;

-- Trigger for updated_at
create trigger update_group_fasts_updated_at
  before update on public.group_fasts
  for each row
  execute function public.update_updated_at_column();

-- Function to automatically update fast status based on time
create or replace function public.update_fast_status()
returns trigger
language plpgsql
as $$
begin
  -- Update status to 'active' if start_time has passed and status is 'upcoming'
  if new.status = 'upcoming' and new.start_time <= now() then
    new.status = 'active';
  end if;

  return new;
end;
$$;

-- Trigger to automatically update status
create trigger auto_update_fast_status
  before insert or update on public.group_fasts
  for each row
  execute function public.update_fast_status();
