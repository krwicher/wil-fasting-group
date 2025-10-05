<script setup lang="ts">
const { profile, loading: profileLoading, fetchProfile } = useUserProfile();
const {
  stats,
  loading: statsLoading,
  fetchStats,
  statsSummary,
  getMotivationalMessage,
  achievementLevel,
} = useUserStats();

const loading = computed(
  () => profileLoading.value || statsLoading.value
);

// Fetch data on mount
onMounted(async () => {
  await Promise.all([fetchProfile(), fetchStats()]);
});
</script>

<template>
  <div class="container mx-auto px-4 py-8 max-w-6xl">
    <!-- Loading State -->
    <div v-if="loading" class="flex justify-center items-center min-h-[400px]">
      <UIcon name="i-lucide-loader-2" class="w-8 h-8 animate-spin text-primary-500" />
    </div>

    <!-- Profile Content -->
    <div v-else-if="profile && stats" class="space-y-6">
      <!-- Header Section -->
      <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div class="flex flex-col md:flex-row items-center md:items-start gap-6">
          <!-- Avatar -->
          <ProfileAvatar :profile="profile" size="2xl" />

          <!-- Profile Info -->
          <div class="flex-1 text-center md:text-left">
            <h1 class="text-3xl font-bold mb-2">
              {{ profile.display_name || "User" }}
            </h1>
            <p v-if="profile.bio" class="text-gray-600 mb-3">
              {{ profile.bio }}
            </p>
            <div class="flex flex-wrap gap-2 justify-center md:justify-start">
              <UBadge color="primary" variant="subtle">
                {{ achievementLevel }}
              </UBadge>
              <UBadge color="neutral" variant="subtle">
                <UIcon name="i-lucide-map-pin" class="w-3 h-3 mr-1" />
                {{ profile.timezone }}
              </UBadge>
            </div>
          </div>

          <!-- Edit Button -->
          <div>
            <UButton
              color="primary"
              variant="outline"
              to="/profile/edit"
              icon="i-lucide-pencil"
            >
              Edit Profile
            </UButton>
          </div>
        </div>

        <!-- Motivational Message -->
        <div class="mt-6 p-4 bg-primary-50 rounded-lg border border-primary-200">
          <p class="text-primary-800 font-medium text-center">
            {{ getMotivationalMessage }}
          </p>
        </div>
      </div>

      <!-- Stats Grid -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <div
          v-for="stat in statsSummary"
          :key="stat.label"
          class="bg-white rounded-lg shadow-sm border border-gray-200 p-6"
        >
          <div class="flex items-center gap-3">
            <div class="p-3 bg-primary-100 rounded-lg">
              <UIcon :name="stat.icon" class="w-6 h-6 text-primary-600" />
            </div>
            <div>
              <p class="text-sm text-gray-600">{{ stat.label }}</p>
              <p class="text-2xl font-bold">{{ stat.value }}</p>
            </div>
          </div>
        </div>
      </div>

      <!-- Fast History Section -->
      <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div class="flex items-center justify-between mb-6">
          <h2 class="text-2xl font-bold">Fast History</h2>
          <UButton
            color="neutral"
            variant="outline"
            icon="i-lucide-history"
            to="/fasts/history"
          >
            View All
          </UButton>
        </div>

        <div class="text-center py-12 text-gray-500">
          <UIcon name="i-lucide-calendar-x" class="w-12 h-12 mx-auto mb-4 opacity-50" />
          <p class="text-lg">No fast history yet</p>
          <p class="text-sm">Your completed fasts will appear here</p>
          <UButton
            color="primary"
            class="mt-4"
            to="/fasts"
            icon="i-lucide-plus"
          >
            Join Your First Fast
          </UButton>
        </div>
      </div>

      <!-- Achievements Section -->
      <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div class="flex items-center justify-between mb-6">
          <h2 class="text-2xl font-bold">Achievements</h2>
          <UButton
            color="neutral"
            variant="outline"
            icon="i-lucide-award"
            to="/achievements"
          >
            View All
          </UButton>
        </div>

        <div class="text-center py-12 text-gray-500">
          <UIcon name="i-lucide-star" class="w-12 h-12 mx-auto mb-4 opacity-50" />
          <p class="text-lg">No achievements yet</p>
          <p class="text-sm">Complete fasts to earn achievements</p>
        </div>
      </div>
    </div>

    <!-- Error State -->
    <div v-else class="text-center py-12">
      <UIcon name="i-lucide-alert-circle" class="w-12 h-12 mx-auto mb-4 text-red-500" />
      <p class="text-lg text-gray-700">Failed to load profile</p>
      <UButton
        color="primary"
        class="mt-4"
        @click="() => { fetchProfile(); fetchStats(); }"
      >
        Retry
      </UButton>
    </div>
  </div>
</template>
