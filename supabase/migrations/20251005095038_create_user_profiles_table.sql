-- Create user_profiles table for extended user information
create table public.user_profiles (
  id uuid primary key references auth.users(id) on delete cascade,

  -- Display information
  display_name text,
  bio text,
  avatar_url text,

  -- Preferences
  timezone text not null default 'UTC',
  receive_notifications boolean not null default true,
  notification_preferences jsonb default '{
    "fast_starting": true,
    "milestone_reached": true,
    "user_joined_fast": true,
    "new_chat_message": true,
    "achievement_earned": true
  }'::jsonb,

  -- Privacy settings
  profile_visibility text not null default 'public' check (profile_visibility in ('public', 'community', 'private')),
  show_fasting_stats boolean not null default true,

  -- Statistics (updated by triggers)
  total_fasts_completed integer not null default 0,
  total_hours_fasted numeric(10, 2) not null default 0,
  longest_fast_hours numeric(10, 2) not null default 0,
  current_streak_days integer not null default 0,

  -- Timestamps
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Enable RLS
alter table public.user_profiles enable row level security;

-- RLS Policies

-- Anyone can view public profiles
create policy "Anyone can view public profiles"
  on public.user_profiles for select
  to authenticated
  using (
    profile_visibility = 'public'
    or (profile_visibility = 'community' and public.is_user_approved(auth.uid()))
    or id = auth.uid()
  );

-- Users can insert their own profile
create policy "Users can create own profile"
  on public.user_profiles for insert
  to authenticated
  with check (auth.uid() = id);

-- Users can update their own profile
create policy "Users can update own profile"
  on public.user_profiles for update
  to authenticated
  using (auth.uid() = id);

-- Admins can view all profiles
create policy "Admins can view all profiles"
  on public.user_profiles for select
  to authenticated
  using (public.is_user_admin(auth.uid()));

-- Admins can update any profile (for moderation)
create policy "Admins can update any profile"
  on public.user_profiles for update
  to authenticated
  using (public.is_user_admin(auth.uid()));

-- Indexes
create index user_profiles_display_name_idx on public.user_profiles(display_name);
create index user_profiles_total_hours_fasted_idx on public.user_profiles(total_hours_fasted desc);
create index user_profiles_created_at_idx on public.user_profiles(created_at);

-- Trigger for updated_at
create trigger update_user_profiles_updated_at
  before update on public.user_profiles
  for each row
  execute function public.update_updated_at_column();

-- Function to automatically create profile on user registration
create or replace function public.handle_new_user_profile()
returns trigger
language plpgsql
security definer
as $$
begin
  insert into public.user_profiles (id, timezone, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'timezone', 'UTC'),
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1))
  );
  return new;
end;
$$;

-- Trigger to create profile when user registers
create trigger on_auth_user_created_profile
  after insert on auth.users
  for each row
  execute function public.handle_new_user_profile();
