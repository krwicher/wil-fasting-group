-- Fix RLS policies and functions to address Supabase linter warnings
-- This migration addresses:
-- 1. Auth RLS InitPlan warnings (wrap auth functions with SELECT)
-- 2. Multiple Permissive Policies warnings (consolidate duplicate policies)
-- 3. Function Search Path Mutable warnings (add search_path to security definer functions)

-- ============================================================================
-- PART 1: Fix Functions - Add search_path to security definer functions
-- ============================================================================

-- Fix update_updated_at_column
create or replace function public.update_updated_at_column()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Fix get_user_role
create or replace function public.get_user_role(user_id uuid)
returns public.user_role
language sql
security definer
stable
set search_path = ''
as $$
  select coalesce(
    (raw_user_meta_data->>'role')::public.user_role,
    'pending'::public.user_role
  )
  from auth.users
  where id = user_id;
$$;

-- Fix is_user_approved
create or replace function public.is_user_approved(user_id uuid)
returns boolean
language sql
security definer
stable
set search_path = ''
as $$
  select (raw_user_meta_data->>'role')::public.user_role in ('approved', 'admin', 'super_admin')
  from auth.users
  where id = user_id;
$$;

-- Fix is_user_admin
create or replace function public.is_user_admin(user_id uuid)
returns boolean
language sql
security definer
stable
set search_path = ''
as $$
  select (raw_user_meta_data->>'role')::public.user_role in ('admin', 'super_admin')
  from auth.users
  where id = user_id;
$$;

-- Fix handle_new_user
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- Set default role to 'pending' if not specified
  if new.raw_user_meta_data is null or new.raw_user_meta_data->>'role' is null then
    new.raw_user_meta_data = coalesce(new.raw_user_meta_data, '{}'::jsonb) || '{"role": "pending"}'::jsonb;
  end if;

  -- Set default timezone to UTC if not specified
  if new.raw_user_meta_data->>'timezone' is null then
    new.raw_user_meta_data = new.raw_user_meta_data || '{"timezone": "UTC"}'::jsonb;
  end if;

  return new;
end;
$$;

-- Fix handle_new_user_profile
create or replace function public.handle_new_user_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
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

-- Fix update_fast_status
create or replace function public.update_fast_status()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  -- Update status to 'active' if start_time has passed and status is 'upcoming'
  if new.status = 'upcoming' and new.start_time <= now() then
    new.status = 'active';
  end if;

  return new;
end;
$$;

-- Fix update_group_fast_participant_count
create or replace function public.update_group_fast_participant_count()
returns trigger
language plpgsql
set search_path = ''
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

-- Fix update_user_profile_stats
create or replace function public.update_user_profile_stats()
returns trigger
language plpgsql
set search_path = ''
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

-- Fix update_user_profile_stats_personal
create or replace function public.update_user_profile_stats_personal()
returns trigger
language plpgsql
set search_path = ''
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

-- ============================================================================
-- PART 2: Fix user_profiles RLS policies
-- ============================================================================

-- Drop existing policies
drop policy if exists "Anyone can view public profiles" on public.user_profiles;
drop policy if exists "Admins can view all profiles" on public.user_profiles;
drop policy if exists "Users can create own profile" on public.user_profiles;
drop policy if exists "Users can update own profile" on public.user_profiles;
drop policy if exists "Admins can update any profile" on public.user_profiles;

-- Recreate consolidated policies with optimized auth calls
create policy "Anyone can view public profiles"
  on public.user_profiles for select
  to authenticated
  using (
    profile_visibility = 'public'
    or (profile_visibility = 'community' and public.is_user_approved((select auth.uid())))
    or id = (select auth.uid())
  );

create policy "Users can create own profile"
  on public.user_profiles for insert
  to authenticated
  with check ((select auth.uid()) = id);

create policy "Users and admins can update profiles"
  on public.user_profiles for update
  to authenticated
  using (
    (select auth.uid()) = id
    or public.is_user_admin((select auth.uid()))
  );

-- ============================================================================
-- PART 3: Fix group_fasts RLS policies
-- ============================================================================

-- Drop existing policies
drop policy if exists "Anyone can view public group fasts" on public.group_fasts;
drop policy if exists "Approved users can create group fasts" on public.group_fasts;
drop policy if exists "Creators can update own fasts" on public.group_fasts;
drop policy if exists "Admins can update any fast" on public.group_fasts;
drop policy if exists "Admins can delete any fast" on public.group_fasts;
drop policy if exists "Creators can delete own fasts" on public.group_fasts;

-- Recreate consolidated policies with optimized auth calls
create policy "Anyone can view public group fasts"
  on public.group_fasts for select
  to authenticated
  using (is_public = true or creator_id = (select auth.uid()));

create policy "Approved users can create group fasts"
  on public.group_fasts for insert
  to authenticated
  with check (public.is_user_approved((select auth.uid())));

create policy "Creators and admins can update fasts"
  on public.group_fasts for update
  to authenticated
  using (
    creator_id = (select auth.uid())
    or public.is_user_admin((select auth.uid()))
  );

create policy "Creators and admins can delete fasts"
  on public.group_fasts for delete
  to authenticated
  using (
    public.is_user_admin((select auth.uid()))
    or (
      creator_id = (select auth.uid())
      and (participant_count = 0 or status = 'upcoming')
    )
  );

-- ============================================================================
-- PART 4: Fix fast_participants RLS policies
-- ============================================================================

-- Drop existing policies
drop policy if exists "Participants can view same fast participants" on public.fast_participants;
drop policy if exists "Approved users can join fasts" on public.fast_participants;
drop policy if exists "Users can update own participation" on public.fast_participants;
drop policy if exists "Admins can update any participation" on public.fast_participants;
drop policy if exists "Users can delete own participation" on public.fast_participants;
drop policy if exists "Admins can remove any participant" on public.fast_participants;

-- Recreate consolidated policies with optimized auth calls
create policy "Participants can view same fast participants"
  on public.fast_participants for select
  to authenticated
  using (
    exists (
      select 1 from public.group_fasts
      where id = group_fast_id
      and (is_public = true or creator_id = (select auth.uid()))
    )
    or user_id = (select auth.uid())
  );

create policy "Approved users can join fasts"
  on public.fast_participants for insert
  to authenticated
  with check (
    public.is_user_approved((select auth.uid()))
    and user_id = (select auth.uid())
    -- Check user doesn't already have an active group fast
    and not exists (
      select 1 from public.fast_participants
      where user_id = (select auth.uid())
      and status = 'active'
      and id != fast_participants.id
    )
  );

create policy "Users and admins can update participation"
  on public.fast_participants for update
  to authenticated
  using (
    user_id = (select auth.uid())
    or public.is_user_admin((select auth.uid()))
  );

create policy "Users and admins can delete participation"
  on public.fast_participants for delete
  to authenticated
  using (
    user_id = (select auth.uid())
    or public.is_user_admin((select auth.uid()))
  );

-- ============================================================================
-- PART 5: Fix personal_fasts RLS policies
-- ============================================================================

-- Drop existing policies
drop policy if exists "Users can view own personal fasts" on public.personal_fasts;
drop policy if exists "Admins can view all personal fasts" on public.personal_fasts;
drop policy if exists "Approved users can create personal fasts" on public.personal_fasts;
drop policy if exists "Users can update own personal fasts" on public.personal_fasts;
drop policy if exists "Users can delete own personal fasts" on public.personal_fasts;

-- Recreate consolidated policies with optimized auth calls
create policy "Users and admins can view personal fasts"
  on public.personal_fasts for select
  to authenticated
  using (
    user_id = (select auth.uid())
    or public.is_user_admin((select auth.uid()))
  );

create policy "Approved users can create personal fasts"
  on public.personal_fasts for insert
  to authenticated
  with check (
    public.is_user_approved((select auth.uid()))
    and user_id = (select auth.uid())
    -- Check user doesn't already have an active personal fast
    and not exists (
      select 1 from public.personal_fasts
      where user_id = (select auth.uid())
      and status = 'active'
      and id != personal_fasts.id
    )
  );

create policy "Users can update own personal fasts"
  on public.personal_fasts for update
  to authenticated
  using (user_id = (select auth.uid()));

create policy "Users can delete own personal fasts"
  on public.personal_fasts for delete
  to authenticated
  using (user_id = (select auth.uid()));
