-- Create chat_bans table for managing chat moderation
create table public.chat_bans (
  id uuid primary key default gen_random_uuid(),

  -- References
  group_fast_id uuid references public.group_fasts(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  banned_by uuid references auth.users(id) on delete set null not null,

  -- Ban details
  reason text not null check (char_length(reason) >= 1 and char_length(reason) <= 500),
  expires_at timestamptz, -- null means permanent ban

  -- Timestamps
  created_at timestamptz not null default now(),

  -- Constraints
  unique(group_fast_id, user_id) -- One ban record per user per fast
);

-- Enable RLS
alter table public.chat_bans enable row level security;

-- RLS Policies

-- Participants can view bans in their fast
create policy "Participants can view bans"
  on public.chat_bans for select
  to authenticated
  using (
    exists (
      select 1 from public.fast_participants
      where group_fast_id = chat_bans.group_fast_id
      and user_id = (select auth.uid())
    )
    or exists (
      select 1 from public.group_fasts
      where id = chat_bans.group_fast_id
      and creator_id = (select auth.uid())
    )
    or public.is_user_admin((select auth.uid()))
  );

-- Only admins and fast creators can ban users
create policy "Admins and creators can ban users"
  on public.chat_bans for insert
  to authenticated
  with check (
    public.is_user_admin((select auth.uid()))
    or exists (
      select 1 from public.group_fasts
      where id = chat_bans.group_fast_id
      and creator_id = (select auth.uid())
    )
  );

-- Only admins and fast creators can update bans
create policy "Admins and creators can update bans"
  on public.chat_bans for update
  to authenticated
  using (
    public.is_user_admin((select auth.uid()))
    or exists (
      select 1 from public.group_fasts
      where id = chat_bans.group_fast_id
      and creator_id = (select auth.uid())
    )
  );

-- Only admins and fast creators can remove bans
create policy "Admins and creators can remove bans"
  on public.chat_bans for delete
  to authenticated
  using (
    public.is_user_admin((select auth.uid()))
    or exists (
      select 1 from public.group_fasts
      where id = chat_bans.group_fast_id
      and creator_id = (select auth.uid())
    )
  );

-- Indexes
create index chat_bans_group_fast_id_idx on public.chat_bans(group_fast_id);
create index chat_bans_user_id_idx on public.chat_bans(user_id);
create index chat_bans_expires_at_idx on public.chat_bans(expires_at);

-- Function to ban a user from chat
create or replace function public.ban_user_from_chat(
  p_group_fast_id uuid,
  p_user_id uuid,
  p_reason text,
  p_expires_at timestamptz default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_ban_id uuid;
begin
  -- Check if caller is admin or fast creator
  if not (
    public.is_user_admin(auth.uid())
    or exists (
      select 1 from public.group_fasts
      where id = p_group_fast_id
      and creator_id = auth.uid()
    )
  ) then
    raise exception 'Not authorized to ban users';
  end if;

  -- Insert or update ban
  insert into public.chat_bans (group_fast_id, user_id, banned_by, reason, expires_at)
  values (p_group_fast_id, p_user_id, auth.uid(), p_reason, p_expires_at)
  on conflict (group_fast_id, user_id)
  do update set
    banned_by = auth.uid(),
    reason = p_reason,
    expires_at = p_expires_at,
    created_at = now()
  returning id into v_ban_id;

  return v_ban_id;
end;
$$;

-- Function to unban a user from chat
create or replace function public.unban_user_from_chat(
  p_group_fast_id uuid,
  p_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- Check if caller is admin or fast creator
  if not (
    public.is_user_admin(auth.uid())
    or exists (
      select 1 from public.group_fasts
      where id = p_group_fast_id
      and creator_id = auth.uid()
    )
  ) then
    raise exception 'Not authorized to unban users';
  end if;

  -- Delete ban record
  delete from public.chat_bans
  where group_fast_id = p_group_fast_id
  and user_id = p_user_id;
end;
$$;

-- Function to check if user is banned from chat
create or replace function public.is_user_banned_from_chat(
  p_group_fast_id uuid,
  p_user_id uuid
)
returns boolean
language sql
stable
set search_path = ''
as $$
  select exists (
    select 1 from public.chat_bans
    where group_fast_id = p_group_fast_id
    and user_id = p_user_id
    and (expires_at is null or expires_at > now())
  );
$$;
