import { StatsRepository } from "../repositories/statsRepository";

export const useUserStats = () => {
  const supabase = useSupabaseClient();
  const user = useSupabaseUser();

  const repository = new StatsRepository(supabase);

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
      stats.value = await repository.getUserStats(targetUserId);
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
    return repository.formatHours(hours);
  };

  /**
   * Calculate average fast duration
   */
  const averageFastDuration = computed(() => {
    if (!stats.value) return 0;
    return repository.calculateAverageFastDuration(stats.value);
  });

  /**
   * Get a motivational message based on stats
   */
  const getMotivationalMessage = computed(() => {
    if (!stats.value) return "Start your fasting journey today!";
    return repository.getMotivationalMessage(stats.value);
  });

  /**
   * Get achievement level based on total hours
   */
  const achievementLevel = computed(() => {
    if (!stats.value) return "Beginner";
    return repository.getAchievementLevel(stats.value);
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
