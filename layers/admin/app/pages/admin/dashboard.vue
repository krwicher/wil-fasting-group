<script setup lang="ts">
definePageMeta({
  middleware: ["admin"],
});

const { stats, loading, fetchStats, getPendingCount } = useAdmin();
const { isAdmin, isSuperAdmin } = useUserRole();

const pendingCount = ref(0);

// Fetch data on mount
onMounted(async () => {
  await fetchStats();
  pendingCount.value = await getPendingCount();
});

// Refresh data
const refreshData = async () => {
  await fetchStats();
  pendingCount.value = await getPendingCount();
};
</script>

<template>
  <div class="container mx-auto px-4 py-8 max-w-7xl">
    <!-- Header -->
    <div class="mb-8">
      <div class="flex items-center justify-between">
        <div>
          <h1 class="text-3xl font-bold mb-2">Admin Dashboard</h1>
          <p class="text-gray-600">Manage users and monitor app statistics</p>
        </div>
        <UButton
          color="neutral"
          variant="outline"
          icon="i-lucide-refresh-cw"
          @click="refreshData"
          :loading="loading"
        >
          Refresh
        </UButton>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="flex justify-center items-center min-h-[400px]">
      <UIcon
        name="i-lucide-loader-2"
        class="w-8 h-8 animate-spin text-primary-500"
      />
    </div>

    <!-- Dashboard Content -->
    <div v-else-if="stats" class="space-y-6">
      <!-- Quick Actions -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <NuxtLink
          to="/admin/users"
          class="block bg-white rounded-lg shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow"
        >
          <div class="flex items-center justify-between mb-4">
            <div class="p-3 bg-primary-100 rounded-lg">
              <UIcon name="i-lucide-users" class="w-6 h-6 text-primary-600" />
            </div>
            <UBadge v-if="pendingCount > 0" color="error" variant="solid">
              {{ pendingCount }} pending
            </UBadge>
          </div>
          <h3 class="text-lg font-semibold mb-1">User Management</h3>
          <p class="text-sm text-gray-600">Approve users and manage roles</p>
        </NuxtLink>

        <div
          class="block bg-white rounded-lg shadow-sm border border-gray-200 p-6"
        >
          <div class="flex items-center justify-between mb-4">
            <div class="p-3 bg-success-100 rounded-lg">
              <UIcon
                name="i-lucide-activity"
                class="w-6 h-6 text-success-600"
              />
            </div>
          </div>
          <h3 class="text-lg font-semibold mb-1">Activity Logs</h3>
          <p class="text-sm text-gray-600">Coming soon</p>
        </div>
      </div>

      <!-- User Statistics -->
      <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h2 class="text-2xl font-bold mb-6">User Statistics</h2>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <div class="p-4 bg-gray-50 rounded-lg">
            <div class="flex items-center gap-3 mb-2">
              <UIcon name="i-lucide-users" class="w-5 h-5 text-gray-600" />
              <p class="text-sm text-gray-600">Total Users</p>
            </div>
            <p class="text-3xl font-bold">{{ stats.total_users }}</p>
          </div>

          <div class="p-4 bg-yellow-50 rounded-lg">
            <div class="flex items-center gap-3 mb-2">
              <UIcon name="i-lucide-clock" class="w-5 h-5 text-yellow-600" />
              <p class="text-sm text-yellow-800">Pending Approval</p>
            </div>
            <p class="text-3xl font-bold text-yellow-900">
              {{ stats.pending_users }}
            </p>
          </div>

          <div class="p-4 bg-green-50 rounded-lg">
            <div class="flex items-center gap-3 mb-2">
              <UIcon
                name="i-lucide-check-circle"
                class="w-5 h-5 text-green-600"
              />
              <p class="text-sm text-green-800">Approved</p>
            </div>
            <p class="text-3xl font-bold text-green-900">
              {{ stats.approved_users }}
            </p>
          </div>

          <div class="p-4 bg-blue-50 rounded-lg">
            <div class="flex items-center gap-3 mb-2">
              <UIcon name="i-lucide-shield" class="w-5 h-5 text-blue-600" />
              <p class="text-sm text-blue-800">Admins</p>
            </div>
            <p class="text-3xl font-bold text-blue-900">
              {{ stats.admin_users }}
            </p>
          </div>
        </div>
      </div>

      <!-- Fasting Statistics -->
      <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h2 class="text-2xl font-bold mb-6">Fasting Statistics</h2>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div class="p-4 bg-gray-50 rounded-lg">
            <div class="flex items-center gap-3 mb-2">
              <UIcon name="i-lucide-calendar" class="w-5 h-5 text-gray-600" />
              <p class="text-sm text-gray-600">Total Fasts</p>
            </div>
            <p class="text-3xl font-bold">{{ stats.total_fasts }}</p>
          </div>

          <div class="p-4 bg-purple-50 rounded-lg">
            <div class="flex items-center gap-3 mb-2">
              <UIcon name="i-lucide-flame" class="w-5 h-5 text-purple-600" />
              <p class="text-sm text-purple-800">Active Fasts</p>
            </div>
            <p class="text-3xl font-bold text-purple-900">
              {{ stats.active_fasts }}
            </p>
          </div>

          <div class="p-4 bg-indigo-50 rounded-lg">
            <div class="flex items-center gap-3 mb-2">
              <UIcon name="i-lucide-users-2" class="w-5 h-5 text-indigo-600" />
              <p class="text-sm text-indigo-800">Total Participants</p>
            </div>
            <p class="text-3xl font-bold text-indigo-900">
              {{ stats.total_participants }}
            </p>
          </div>
        </div>
      </div>

      <!-- Admin Info -->
      <div class="bg-blue-50 border border-blue-200 rounded-lg p-6">
        <div class="flex items-start gap-3">
          <UIcon name="i-lucide-info" class="w-5 h-5 text-blue-600 mt-0.5" />
          <div>
            <h3 class="font-semibold text-blue-900 mb-2">Admin Capabilities</h3>
            <ul class="text-sm text-blue-800 space-y-1">
              <li>✓ Approve or reject user registrations</li>
              <li>
                ✓ Change user roles (approved, admin{{
                  isSuperAdmin ? ", super_admin" : ""
                }})
              </li>
              <li>✓ View all users and their activity</li>
              <li>✓ Monitor platform statistics</li>
              <li v-if="!isSuperAdmin" class="text-blue-600">
                ℹ Only Super Admins can promote users to Admin or Super Admin
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>

    <!-- Error State -->
    <div v-else class="text-center py-12">
      <UIcon
        name="i-lucide-alert-circle"
        class="w-12 h-12 mx-auto mb-4 text-red-500"
      />
      <p class="text-lg text-gray-700">Failed to load admin statistics</p>
      <UButton color="primary" class="mt-4" @click="refreshData">
        Retry
      </UButton>
    </div>
  </div>
</template>
