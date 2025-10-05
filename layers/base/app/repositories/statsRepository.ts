import type { SupabaseClient } from "@supabase/supabase-js";

export interface UserStats {
  total_fasts_completed: number;
  total_hours_fasted: number;
  longest_fast_hours: number;
  current_streak_days: number;
}

export class StatsRepository {
  constructor(private supabase: SupabaseClient) {}

  /**
   * Fetch user statistics
   */
  async getUserStats(userId: string): Promise<UserStats> {
    const { data, error } = await this.supabase
      .from("user_profiles")
      .select("total_fasts_completed, total_hours_fasted, longest_fast_hours, current_streak_days")
      .eq("id", userId)
      .single();

    if (error) {
      throw new Error(`Failed to fetch user stats: ${error.message}`);
    }

    return data;
  }

  /**
   * Format hours for display
   */
  formatHours(hours: number): string {
    if (hours < 24) {
      return `${hours.toFixed(1)} hours`;
    }

    const days = Math.floor(hours / 24);
    const remainingHours = hours % 24;

    if (remainingHours === 0) {
      return `${days} ${days === 1 ? "day" : "days"}`;
    }

    return `${days} ${days === 1 ? "day" : "days"} ${remainingHours.toFixed(1)} hours`;
  }

  /**
   * Calculate average fast duration
   */
  calculateAverageFastDuration(stats: UserStats): number {
    if (stats.total_fasts_completed === 0) return 0;
    return stats.total_hours_fasted / stats.total_fasts_completed;
  }

  /**
   * Get motivational message based on stats
   */
  getMotivationalMessage(stats: UserStats): string {
    const { total_fasts_completed, total_hours_fasted, current_streak_days } = stats;

    if (total_fasts_completed === 0) {
      return "Ready to start your first fast?";
    }

    if (current_streak_days >= 7) {
      return `Amazing! ${current_streak_days} day streak!`;
    }

    if (total_hours_fasted >= 1000) {
      return "You're a fasting legend! 🏆";
    }

    if (total_hours_fasted >= 500) {
      return "Incredible dedication! Keep it up! 💪";
    }

    if (total_hours_fasted >= 100) {
      return "You're on a roll! Keep going! 🔥";
    }

    return "Great start! Stay consistent! ⭐";
  }

  /**
   * Get achievement level based on total hours
   */
  getAchievementLevel(stats: UserStats): string {
    const hours = stats.total_hours_fasted;

    if (hours >= 1000) return "Legend";
    if (hours >= 500) return "Master";
    if (hours >= 250) return "Expert";
    if (hours >= 100) return "Advanced";
    if (hours >= 50) return "Intermediate";
    return "Beginner";
  }
}
