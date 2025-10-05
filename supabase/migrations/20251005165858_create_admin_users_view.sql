-- Create a view for admins to access auth.users data
-- This provides read-only access to email, role, and last_sign_in_at
-- Uses security_invoker = true to enforce RLS based on calling user's permissions

create or replace view public.admin_users_view
with (security_invoker = true)
as
select
  u.id,
  u.email,
  u.raw_user_meta_data->>'role' as role,
  u.last_sign_in_at
from auth.users u
where public.is_user_admin(auth.uid()); -- Only return rows if user is admin

-- Comment
comment on view public.admin_users_view is
  'Admin-only view providing access to auth.users metadata (email, role, last_sign_in_at) for user management. Filters results to only return data when queried by admin users.';
