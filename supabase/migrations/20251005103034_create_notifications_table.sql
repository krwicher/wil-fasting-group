-- Create notifications table for in-app notifications
create table public.notifications (
  id uuid primary key default gen_random_uuid(),

  -- Recipient
  user_id uuid references auth.users(id) on delete cascade not null,

  -- Notification details
  type text not null check (type in (
    'user_joined_fast',
    'fast_starting_soon',
    'milestone_reached',
    'new_chat_message',
    'achievement_earned',
    'admin_approval',
    'admin_rejection',
    'new_user_registration'
  )),
  title text not null check (char_length(title) >= 1 and char_length(title) <= 200),
  message text not null check (char_length(message) >= 1 and char_length(message) <= 1000),

  -- Optional link to related entity
  related_entity_type text check (related_entity_type in ('group_fast', 'personal_fast', 'user', 'achievement')),
  related_entity_id uuid,

  -- Status
  is_read boolean not null default false,
  read_at timestamptz,

  -- Timestamps
  created_at timestamptz not null default now()
);

-- Enable RLS
alter table public.notifications enable row level security;

-- RLS Policies

-- Users can view their own notifications
create policy "Users can view own notifications"
  on public.notifications for select
  to authenticated
  using (user_id = (select auth.uid()));

-- System can insert notifications (via backend functions)
create policy "System can create notifications"
  on public.notifications for insert
  to authenticated
  with check (true);

-- Users can update their own notifications (mark as read)
create policy "Users can update own notifications"
  on public.notifications for update
  to authenticated
  using (user_id = (select auth.uid()));

-- Users can delete their own notifications
create policy "Users can delete own notifications"
  on public.notifications for delete
  to authenticated
  using (user_id = (select auth.uid()));

-- Admins can view all notifications
create policy "Admins can view all notifications"
  on public.notifications for select
  to authenticated
  using (public.is_user_admin((select auth.uid())));

-- Indexes
create index notifications_user_id_idx on public.notifications(user_id);
create index notifications_is_read_idx on public.notifications(is_read);
create index notifications_created_at_idx on public.notifications(created_at desc);
create index notifications_type_idx on public.notifications(type);

-- Function to mark notification as read
create or replace function public.mark_notification_read(notification_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.notifications
  set is_read = true, read_at = now()
  where id = notification_id
  and user_id = auth.uid();
end;
$$;

-- Function to mark all user notifications as read
create or replace function public.mark_all_notifications_read()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.notifications
  set is_read = true, read_at = now()
  where user_id = auth.uid()
  and is_read = false;
end;
$$;
