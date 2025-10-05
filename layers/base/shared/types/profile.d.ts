export type ProfileVisibility = "public" | "community" | "private";

export interface UserProfile {
  id: string;
  display_name: string | null;
  bio: string | null;
  avatar_url: string | null;
  timezone: string;
  receive_notifications: boolean;
  notification_preferences: {
    fast_starting: boolean;
    milestone_reached: boolean;
    user_joined_fast: boolean;
    new_chat_message: boolean;
    achievement_earned: boolean;
  };
  profile_visibility: ProfileVisibility;
  show_fasting_stats: boolean;
  total_fasts_completed: number;
  total_hours_fasted: number;
  longest_fast_hours: number;
  current_streak_days: number;
  created_at: string;
  updated_at: string;
}

export interface UserStats {
  total_fasts_completed: number;
  total_hours_fasted: number;
  longest_fast_hours: number;
  current_streak_days: number;
}

export interface UpdateProfileData {
  display_name?: string;
  bio?: string;
  avatar_url?: string;
  timezone?: string;
  receive_notifications?: boolean;
  notification_preferences?: UserProfile["notification_preferences"];
  profile_visibility?: ProfileVisibility;
  show_fasting_stats?: boolean;
}
