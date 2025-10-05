-- Create chat_messages table for group fast chat
create table public.chat_messages (
  id uuid primary key default gen_random_uuid(),

  -- References
  group_fast_id uuid references public.group_fasts(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade not null,

  -- Message content
  message text not null check (char_length(message) >= 1 and char_length(message) <= 2000),

  -- Moderation
  is_deleted boolean not null default false,
  deleted_at timestamptz,
  deleted_by uuid references auth.users(id) on delete set null,
  deletion_reason text,

  is_edited boolean not null default false,
  edited_at timestamptz,

  -- Timestamps
  created_at timestamptz not null default now(),

  -- Constraints
  check (is_deleted = false or deleted_at is not null),
  check (is_deleted = false or deleted_by is not null),
  check (is_edited = false or edited_at is not null)
);

-- Enable RLS
alter table public.chat_messages enable row level security;

-- RLS Policies

-- Participants can view messages in their fast's chat
create policy "Participants can view chat messages"
  on public.chat_messages for select
  to authenticated
  using (
    exists (
      select 1 from public.fast_participants
      where group_fast_id = chat_messages.group_fast_id
      and user_id = (select auth.uid())
    )
    or exists (
      select 1 from public.group_fasts
      where id = chat_messages.group_fast_id
      and creator_id = (select auth.uid())
    )
  );

-- Participants can send messages (if not banned)
create policy "Participants can send messages"
  on public.chat_messages for insert
  to authenticated
  with check (
    exists (
      select 1 from public.fast_participants
      where group_fast_id = chat_messages.group_fast_id
      and user_id = (select auth.uid())
    )
    and not exists (
      select 1 from public.chat_bans
      where group_fast_id = chat_messages.group_fast_id
      and user_id = (select auth.uid())
      and (expires_at is null or expires_at > now())
    )
  );

-- Users can update their own messages (edit)
create policy "Users can edit own messages"
  on public.chat_messages for update
  to authenticated
  using (
    user_id = (select auth.uid())
    and is_deleted = false
  );

-- Admins and fast creators can delete messages
create policy "Admins and creators can delete messages"
  on public.chat_messages for update
  to authenticated
  using (
    public.is_user_admin((select auth.uid()))
    or exists (
      select 1 from public.group_fasts
      where id = chat_messages.group_fast_id
      and creator_id = (select auth.uid())
    )
  );

-- Indexes
create index chat_messages_group_fast_id_idx on public.chat_messages(group_fast_id);
create index chat_messages_user_id_idx on public.chat_messages(user_id);
create index chat_messages_created_at_idx on public.chat_messages(created_at desc);
create index chat_messages_is_deleted_idx on public.chat_messages(is_deleted);

-- Function to soft delete a message
create or replace function public.delete_chat_message(
  message_id uuid,
  reason text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.chat_messages
  set
    is_deleted = true,
    deleted_at = now(),
    deleted_by = auth.uid(),
    deletion_reason = reason
  where id = message_id
  and (
    -- User deleting their own message
    user_id = auth.uid()
    -- Or admin
    or public.is_user_admin(auth.uid())
    -- Or fast creator
    or exists (
      select 1 from public.group_fasts
      where id = chat_messages.group_fast_id
      and creator_id = auth.uid()
    )
  );
end;
$$;

-- Trigger to set edited_at when message is updated
create or replace function public.update_chat_message_edited_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if old.message != new.message and new.is_deleted = false then
    new.is_edited = true;
    new.edited_at = now();
  end if;
  return new;
end;
$$;

create trigger update_chat_message_edited_at
  before update on public.chat_messages
  for each row
  execute function public.update_chat_message_edited_at();
