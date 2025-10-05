-- Create enum types for the application

-- User roles enum
create type public.user_role as enum (
  'pending',      -- Newly registered, awaiting approval
  'approved',     -- Can access app and all features
  'admin',        -- Can moderate content, manage users
  'super_admin'   -- Full access, can promote other admins
);

-- Fast status enum
create type public.fast_status as enum (
  'upcoming',     -- Fast hasn't started yet
  'active',       -- Fast is currently in progress
  'completed',    -- Fast has ended (all participants finished)
  'closed'        -- Fast was manually closed by admin/creator
);

-- Participation status enum
create type public.participation_status as enum (
  'active',       -- Currently fasting
  'completed',    -- Reached target duration
  'quit_early',   -- Ended before target
  'extended'      -- Continuing past target duration
);
