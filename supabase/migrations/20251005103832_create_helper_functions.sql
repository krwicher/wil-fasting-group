-- Helper functions for common operations

-- Function to calculate hours fasted
create or replace function public.calculate_hours_fasted(
  p_started_at timestamptz,
  p_ended_at timestamptz default null
)
returns numeric(10, 2)
language sql
immutable
set search_path = ''
as $$
  select extract(epoch from (coalesce(p_ended_at, now()) - p_started_at)) / 3600;
$$;

-- Function to calculate progress percentage
create or replace function public.calculate_progress_percentage(
  p_started_at timestamptz,
  p_target_hours integer,
  p_ended_at timestamptz default null
)
returns numeric(5, 2)
language sql
immutable
set search_path = ''
as $$
  select least(
    (extract(epoch from (coalesce(p_ended_at, now()) - p_started_at)) / 3600 / p_target_hours * 100)::numeric(5, 2),
    100.00
  );
$$;

-- Function to get user's active fast (group or personal)
create or replace function public.get_user_active_fast(p_user_id uuid)
returns jsonb
language plpgsql
stable
set search_path = ''
as $$
declare
  v_result jsonb;
begin
  -- Check for active group fast participation
  select jsonb_build_object(
    'type', 'group',
    'id', fp.id,
    'group_fast_id', fp.group_fast_id,
    'group_fast_name', gf.name,
    'started_at', fp.started_at,
    'target_duration_hours', fp.target_duration_hours,
    'status', fp.status
  )
  into v_result
  from public.fast_participants fp
  join public.group_fasts gf on gf.id = fp.group_fast_id
  where fp.user_id = p_user_id
  and fp.status = 'active'
  limit 1;

  if v_result is not null then
    return v_result;
  end if;

  -- Check for active personal fast
  select jsonb_build_object(
    'type', 'personal',
    'id', pf.id,
    'name', pf.name,
    'started_at', pf.started_at,
    'target_duration_hours', pf.target_duration_hours,
    'status', pf.status
  )
  into v_result
  from public.personal_fasts pf
  where pf.user_id = p_user_id
  and pf.status = 'active'
  limit 1;

  return v_result;
end;
$$;

-- Function to get unread notification count
create or replace function public.get_unread_notification_count(p_user_id uuid)
returns integer
language sql
stable
set search_path = ''
as $$
  select count(*)::integer
  from public.notifications
  where user_id = p_user_id
  and is_read = false;
$$;

-- Function to update user role (admin only)
create or replace function public.update_user_role(
  p_user_id uuid,
  p_new_role public.user_role
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_caller_role public.user_role;
begin
  -- Get caller's role
  v_caller_role := public.get_user_role(auth.uid());

  -- Only super_admin can promote to admin or super_admin
  if p_new_role in ('admin', 'super_admin') and v_caller_role != 'super_admin' then
    raise exception 'Only super admins can promote to admin roles';
  end if;

  -- Only admin or super_admin can update roles
  if v_caller_role not in ('admin', 'super_admin') then
    raise exception 'Only admins can update user roles';
  end if;

  -- Update user metadata
  update auth.users
  set raw_user_meta_data = coalesce(raw_user_meta_data, '{}'::jsonb) || jsonb_build_object('role', p_new_role)
  where id = p_user_id;

  -- Create notification for the user
  insert into public.notifications (
    user_id,
    type,
    title,
    message
  )
  values (
    p_user_id,
    case
      when p_new_role = 'approved' then 'admin_approval'
      when p_new_role = 'pending' then 'admin_rejection'
      else 'admin_approval'
    end,
    case
      when p_new_role = 'approved' then 'Account Approved!'
      when p_new_role = 'admin' then 'Promoted to Admin'
      when p_new_role = 'super_admin' then 'Promoted to Super Admin'
      else 'Account Status Updated'
    end,
    case
      when p_new_role = 'approved' then 'Your account has been approved. Welcome to the community!'
      when p_new_role = 'admin' then 'You have been promoted to admin.'
      when p_new_role = 'super_admin' then 'You have been promoted to super admin.'
      else 'Your account status has been updated to: ' || p_new_role
    end
  );
end;
$$;

-- Function to end fast (group or personal)
create or replace function public.end_fast(
  p_fast_type text, -- 'group' or 'personal'
  p_fast_id uuid,
  p_status public.participation_status default 'completed',
  p_quit_reason text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_fast_type = 'group' then
    update public.fast_participants
    set
      status = p_status,
      ended_at = now(),
      quit_reason = p_quit_reason
    where id = p_fast_id
    and user_id = auth.uid()
    and status = 'active';
  elsif p_fast_type = 'personal' then
    update public.personal_fasts
    set
      status = p_status,
      ended_at = now(),
      quit_reason = p_quit_reason
    where id = p_fast_id
    and user_id = auth.uid()
    and status = 'active';
  else
    raise exception 'Invalid fast type. Must be "group" or "personal"';
  end if;

  if not found then
    raise exception 'Fast not found or already ended';
  end if;
end;
$$;

-- Function to leave group fast
create or replace function public.leave_group_fast(p_participant_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- Delete participation record
  delete from public.fast_participants
  where id = p_participant_id
  and user_id = auth.uid();

  if not found then
    raise exception 'Participation not found or not authorized';
  end if;
end;
$$;

-- Function to close group fast (admin or creator)
create or replace function public.close_group_fast(p_fast_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- Check if caller is admin or creator
  if not (
    public.is_user_admin(auth.uid())
    or exists (
      select 1 from public.group_fasts
      where id = p_fast_id
      and creator_id = auth.uid()
    )
  ) then
    raise exception 'Not authorized to close this fast';
  end if;

  -- Update fast status
  update public.group_fasts
  set status = 'closed'
  where id = p_fast_id;

  if not found then
    raise exception 'Fast not found';
  end if;

  -- End all active participations
  update public.fast_participants
  set
    status = 'completed',
    ended_at = now()
  where group_fast_id = p_fast_id
  and status = 'active';
end;
$$;
