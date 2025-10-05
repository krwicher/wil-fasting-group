-- Create achievements table for gamification
create table public.achievements (
  id uuid primary key default gen_random_uuid(),

  -- Achievement details
  name text not null check (char_length(name) >= 1 and char_length(name) <= 100),
  description text not null check (char_length(description) >= 1 and char_length(description) <= 500),
  icon text not null check (char_length(icon) >= 1 and char_length(icon) <= 50), -- Emoji or icon identifier
  category text not null check (category in (
    'fasting_duration',
    'participation',
    'consistency',
    'community',
    'milestones'
  )),

  -- Requirements
  requirement_type text not null check (requirement_type in (
    'total_hours_fasted',
    'total_fasts_completed',
    'longest_fast_hours',
    'consecutive_days_active',
    'group_fasts_joined',
    'group_fasts_created',
    'chat_messages_sent',
    'custom'
  )),
  requirement_value numeric(10, 2) not null check (requirement_value > 0),

  -- Rarity/difficulty
  tier text not null default 'bronze' check (tier in ('bronze', 'silver', 'gold', 'platinum', 'diamond')),

  -- Display order
  display_order integer not null default 0,

  -- Timestamps
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  -- Ensure unique achievement names
  unique(name)
);

-- Enable RLS
alter table public.achievements enable row level security;

-- RLS Policies

-- Anyone can view achievements
create policy "Anyone can view achievements"
  on public.achievements for select
  to authenticated
  using (true);

-- Only admins can manage achievements
create policy "Admins can manage achievements"
  on public.achievements for all
  to authenticated
  using (public.is_user_admin((select auth.uid())));

-- Indexes
create index achievements_category_idx on public.achievements(category);
create index achievements_tier_idx on public.achievements(tier);
create index achievements_display_order_idx on public.achievements(display_order);

-- Trigger for updated_at
create trigger update_achievements_updated_at
  before update on public.achievements
  for each row
  execute function public.update_updated_at_column();

-- Seed some default achievements
insert into public.achievements (name, description, icon, category, requirement_type, requirement_value, tier, display_order) values
  -- Fasting duration achievements
  ('First Fast', 'Complete your first fast', '<', 'fasting_duration', 'total_fasts_completed', 1, 'bronze', 1),
  ('24-Hour Warrior', 'Fast for 24 hours straight', 'ð', 'fasting_duration', 'longest_fast_hours', 24, 'bronze', 2),
  ('48-Hour Champion', 'Fast for 48 hours straight', '<Æ', 'fasting_duration', 'longest_fast_hours', 48, 'silver', 3),
  ('72-Hour Master', 'Fast for 72 hours straight', '=Q', 'fasting_duration', 'longest_fast_hours', 72, 'gold', 4),
  ('5-Day Legend', 'Fast for 5 days (120 hours) straight', '>…', 'fasting_duration', 'longest_fast_hours', 120, 'platinum', 5),
  ('Week Warrior', 'Fast for 7 days (168 hours) straight', '”', 'fasting_duration', 'longest_fast_hours', 168, 'diamond', 6),

  -- Total hours achievements
  ('100 Hours Club', 'Fast for a total of 100 hours', '=¯', 'milestones', 'total_hours_fasted', 100, 'bronze', 10),
  ('500 Hours Club', 'Fast for a total of 500 hours', '=%', 'milestones', 'total_hours_fasted', 500, 'silver', 11),
  ('1000 Hours Club', 'Fast for a total of 1000 hours', '=Ž', 'milestones', 'total_hours_fasted', 1000, 'gold', 12),

  -- Participation achievements
  ('Team Player', 'Join your first group fast', '>', 'participation', 'group_fasts_joined', 1, 'bronze', 20),
  ('Fast Enthusiast', 'Join 5 group fasts', '<¯', 'participation', 'group_fasts_joined', 5, 'silver', 21),
  ('Fast Veteran', 'Join 10 group fasts', '<', 'participation', 'group_fasts_joined', 10, 'gold', 22),
  ('Fast Leader', 'Create your first group fast', '=€', 'participation', 'group_fasts_created', 1, 'bronze', 23),

  -- Consistency achievements
  ('Consistent Faster', 'Complete 5 fasts', '=Ê', 'consistency', 'total_fasts_completed', 5, 'bronze', 30),
  ('Dedicated Faster', 'Complete 10 fasts', '=ª', 'consistency', 'total_fasts_completed', 10, 'silver', 31),
  ('Fasting Pro', 'Complete 25 fasts', '>G', 'consistency', 'total_fasts_completed', 25, 'gold', 32),
  ('Fasting Master', 'Complete 50 fasts', '=Q', 'consistency', 'total_fasts_completed', 50, 'platinum', 33);
