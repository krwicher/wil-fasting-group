-- Extend auth.users with additional metadata columns
-- Note: We cannot directly alter auth.users, but we can store data in raw_user_meta_data
-- This migration documents the expected structure of raw_user_meta_data

-- Expected raw_user_meta_data structure (stored as JSONB):
-- {
--   "role": "pending" | "approved" | "admin" | "super_admin",
--   "timezone": "America/New_York",  -- IANA timezone
--   "full_name": "John Doe",
--   "avatar_url": "avatars/user-id/filename.jpg"
-- }

-- Create a helper function to get user role
create or replace function public.get_user_role(user_id uuid)
returns public.user_role
language sql
security definer
stable
as $$
  select coalesce(
    (raw_user_meta_data->>'role')::public.user_role,
    'pending'::public.user_role
  )
  from auth.users
  where id = user_id;
$$;

-- Create a helper function to check if user is approved
create or replace function public.is_user_approved(user_id uuid)
returns boolean
language sql
security definer
stable
as $$
  select (raw_user_meta_data->>'role')::public.user_role in ('approved', 'admin', 'super_admin')
  from auth.users
  where id = user_id;
$$;

-- Create a helper function to check if user is admin
create or replace function public.is_user_admin(user_id uuid)
returns boolean
language sql
security definer
stable
as $$
  select (raw_user_meta_data->>'role')::public.user_role in ('admin', 'super_admin')
  from auth.users
  where id = user_id;
$$;

-- Create a trigger function to set default role on user creation
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
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

-- Create trigger on auth.users for new user registration
create trigger on_auth_user_created
  before insert on auth.users
  for each row
  execute function public.handle_new_user();
