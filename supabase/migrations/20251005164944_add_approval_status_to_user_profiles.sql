-- Add approval_status column to user_profiles
-- This separates profile approval from auth role management
-- Admins can easily query/filter users by approval status without auth.admin API

-- Add approval_status column
alter table public.user_profiles
add column approval_status text not null default 'pending'
check (approval_status in ('pending', 'approved', 'rejected'));

-- Sync existing users: if they have 'approved' or higher role in auth, mark as approved
update public.user_profiles
set approval_status = 'approved'
where id in (
  select id from auth.users
  where raw_user_meta_data->>'role' in ('approved', 'admin', 'super_admin')
);

-- Add index for filtering by approval status
create index user_profiles_approval_status_idx on public.user_profiles(approval_status);

-- Update RLS policies to allow admins to see all profiles regardless of approval status
-- (This policy already exists, but let's make sure pending users are visible to admins)

-- Add policy for admins to update approval_status
create policy "Admins can manage approval status"
  on public.user_profiles for update
  to authenticated
  using (
    public.is_user_admin(auth.uid())
    and approval_status is not null
  );

-- Update the handle_new_user_profile function to set approval_status based on role
create or replace function public.handle_new_user_profile()
returns trigger
language plpgsql
security definer
as $$
begin
  insert into public.user_profiles (id, timezone, display_name, approval_status)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'timezone', 'UTC'),
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1)),
    -- Set approval_status based on initial role (admins are pre-approved)
    case
      when new.raw_user_meta_data->>'role' in ('approved', 'admin', 'super_admin') then 'approved'
      else 'pending'
    end
  );
  return new;
end;
$$;

-- Comment explaining the design
comment on column public.user_profiles.approval_status is
  'User approval status for admin review. Separate from auth role for easier querying. Values: pending (awaiting admin approval), approved (can access app), rejected (denied access).';
