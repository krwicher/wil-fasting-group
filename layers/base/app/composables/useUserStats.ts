import type { UserStats } from "~/layers/base/shared/types/profile";

export const useUserStats = () => {
  const supabase = useSupabaseClient();
  const user = useSupabaseUser();

  const stats = ref<UserStats | null>(null);
  const loading = ref(false);
  const error = ref<string | null>(null);

  /**
   * Fetch user statistics from profile
   */
  const fetchStats = async (userId?: string) => {
    const targetUserId = userId || user.value?.id;

    if (!targetUserId) {
      error.value = "User not authenticated";
      return;
    }

    loading.value = true;
    error.value = null;

    try {
      const { data, error: fetchError } = await supabase
        .from("user_profiles")
        .select(
          "total_fasts_completed, total_hours_fasted, longest_fast_hours, current_streak_days"
        )
        .eq("id", targetUserId)
        .single();

      if (fetchError) throw fetchError;

      stats.value = data;
    } catch (err) {
      error.value = (err as Error).message;
      console.error("Error fetching stats:", err);
    } finally {
      loading.value = false;
    }
  };

  /**
   * Format hours for display (e.g., "48.5 hours" or "2 days 0.5 hours")
   */
  const formatHours = (hours: number): string => {
    if (hours < 24) {
      return `${hours.toFixed(1)} hours`;
    }

    const days = Math.floor(hours / 24);
    const remainingHours = hours % 24;

    if (remainingHours === 0) {
      return `${days} ${days === 1 ? "day" : "days"}`;
    }

    return `${days} ${days === 1 ? "day" : "days"} ${remainingHours.toFixed(1)} hours`;
  };

  /**
   * Calculate average fast duration
   */
  const averageFastDuration = computed(() => {
    if (!stats.value || stats.value.total_fasts_completed === 0) return 0;
    return stats.value.total_hours_fasted / stats.value.total_fasts_completed;
  });

  /**
   * Get a motivational message based on stats
   */
  const getMotivationalMessage = computed(() => {
    if (!stats.value) return "Start your fasting journey today!";

    const { total_fasts_completed, total_hours_fasted, current_streak_days } =
      stats.value;

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
  });

  /**
   * Get achievement level based on total hours
   */
  const achievementLevel = computed(() => {
    if (!stats.value) return "Beginner";

    const hours = stats.value.total_hours_fasted;

    if (hours >= 1000) return "Legend";
    if (hours >= 500) return "Master";
    if (hours >= 250) return "Expert";
    if (hours >= 100) return "Advanced";
    if (hours >= 50) return "Intermediate";
    return "Beginner";
  });

  /**
   * Calculate stats summary for display
   */
  const statsSummary = computed(() => {
    if (!stats.value) return null;

    return [
      {
        label: "Total Fasts",
        value: stats.value.total_fasts_completed,
        icon: "i-lucide-calendar-check",
      },
      {
        label: "Total Hours",
        value: formatHours(stats.value.total_hours_fasted),
        icon: "i-lucide-clock",
      },
      {
        label: "Longest Fast",
        value: formatHours(stats.value.longest_fast_hours),
        icon: "i-lucide-trophy",
      },
      {
        label: "Current Streak",
        value: `${stats.value.current_streak_days} ${
          stats.value.current_streak_days === 1 ? "day" : "days"
        }`,
        icon: "i-lucide-flame",
      },
    ];
  });

  return {
    stats: readonly(stats),
    loading: readonly(loading),
    error: readonly(error),
    fetchStats,
    formatHours,
    averageFastDuration,
    getMotivationalMessage,
    achievementLevel,
    statsSummary,
  };
};
