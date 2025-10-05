<script setup lang="ts">
import type { AdminUser } from "~/layers/admin/shared/types/admin";

definePageMeta({
  middleware: ["admin"],
});

const { users, loading, fetchUsers, approveUser, rejectUser, updateUserRole } = useAdmin();
const { isSuperAdmin } = useUserRole();

const selectedRole = ref<string>("all");
const showRoleModal = ref(false);
const selectedUser = ref<AdminUser | null>(null);

// Fetch users on mount
onMounted(async () => {
  await fetchUsers();
});

// Watch role filter
watch(selectedRole, async (newRole) => {
  if (newRole === "all") {
    await fetchUsers();
  } else {
    await fetchUsers(newRole as any);
  }
});

// Handle approve
const handleApprove = async (userId: string) => {
  await approveUser(userId);
};

// Handle reject
const handleReject = async (userId: string) => {
  if (confirm("Are you sure you want to reject and delete this user? This action cannot be undone.")) {
    await rejectUser(userId);
  }
};

// Handle role change
const openRoleModal = (user: AdminUser) => {
  selectedUser.value = user;
  showRoleModal.value = true;
};

const changeRole = async (newRole: string) => {
  if (!selectedUser.value) return;

  await updateUserRole(selectedUser.value.id, newRole as any);
  showRoleModal.value = false;
  selectedUser.value = null;
};

// Role badge colors
const getRoleBadgeColor = (role: string) => {
  switch (role) {
    case "pending":
      return "neutral";
    case "approved":
      return "success";
    case "admin":
      return "primary";
    case "super_admin":
      return "error";
    default:
      return "neutral";
  }
};

// Format date
const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleDateString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
};

const formatDateTime = (dateString: string) => {
  return new Date(dateString).toLocaleString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
};
</script>

<template>
  <div class="container mx-auto px-4 py-8 max-w-7xl">
    <!-- Header -->
    <div class="mb-8">
      <div class="flex items-center justify-between">
        <div>
          <h1 class="text-3xl font-bold mb-2">User Management</h1>
          <p class="text-gray-600">Manage user accounts and permissions</p>
        </div>
        <UButton color="neutral" variant="outline" icon="i-lucide-arrow-left" to="/admin/dashboard">
          Back to Dashboard
        </UButton>
      </div>
    </div>

    <!-- Filters -->
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4 mb-6">
      <div class="flex items-center gap-4">
        <label class="text-sm font-medium text-gray-700">Filter by role:</label>
        <URadioGroup
          v-model="selectedRole"
          :options="[
            { value: 'all', label: 'All Users' },
            { value: 'pending', label: 'Pending' },
            { value: 'approved', label: 'Approved' },
            { value: 'admin', label: 'Admin' },
            { value: 'super_admin', label: 'Super Admin' },
          ]"
        />
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="flex justify-center items-center min-h-[400px]">
      <UIcon name="i-lucide-loader-2" class="w-8 h-8 animate-spin text-primary-500" />
    </div>

    <!-- Users Table -->
    <div v-else-if="users.length > 0" class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
      <div class="overflow-x-auto">
        <table class="w-full">
          <thead class="bg-gray-50 border-b border-gray-200">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                User
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Email
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Role
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Joined
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Last Sign In
              </th>
              <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-200">
            <tr v-for="user in users" :key="user.id" class="hover:bg-gray-50">
              <!-- User -->
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="font-medium text-gray-900">
                  {{ user.display_name || "No name" }}
                </div>
              </td>

              <!-- Email -->
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="text-sm text-gray-600">{{ user.email }}</div>
              </td>

              <!-- Role -->
              <td class="px-6 py-4 whitespace-nowrap">
                <UBadge :color="getRoleBadgeColor(user.role)" variant="subtle">
                  {{ user.role.replace("_", " ") }}
                </UBadge>
              </td>

              <!-- Joined Date -->
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="text-sm text-gray-600">
                  {{ formatDate(user.created_at) }}
                </div>
              </td>

              <!-- Last Sign In -->
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="text-sm text-gray-600">
                  {{ user.last_sign_in_at ? formatDateTime(user.last_sign_in_at) : "Never" }}
                </div>
              </td>

              <!-- Actions -->
              <td class="px-6 py-4 whitespace-nowrap text-right">
                <div class="flex items-center justify-end gap-2">
                  <!-- Approve Button (only for pending users) -->
                  <UButton
                    v-if="user.role === 'pending'"
                    color="success"
                    size="sm"
                    @click="handleApprove(user.id)"
                  >
                    Approve
                  </UButton>

                  <!-- Change Role Button -->
                  <UButton
                    color="neutral"
                    variant="outline"
                    size="sm"
                    icon="i-lucide-shield"
                    @click="openRoleModal(user)"
                  >
                    Change Role
                  </UButton>

                  <!-- Reject/Delete Button -->
                  <UButton
                    color="error"
                    variant="outline"
                    size="sm"
                    icon="i-lucide-trash-2"
                    @click="handleReject(user.id)"
                  >
                    Delete
                  </UButton>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Empty State -->
    <div v-else class="bg-white rounded-lg shadow-sm border border-gray-200 p-12 text-center">
      <UIcon name="i-lucide-users" class="w-12 h-12 mx-auto mb-4 text-gray-400" />
      <p class="text-lg text-gray-700">No users found</p>
      <p class="text-sm text-gray-500">Try changing the filter</p>
    </div>

    <!-- Change Role Modal -->
    <UModal v-model="showRoleModal">
      <UCard>
        <template #header>
          <h3 class="text-xl font-bold">Change User Role</h3>
        </template>

        <div v-if="selectedUser" class="space-y-4">
          <div>
            <p class="text-sm text-gray-600 mb-1">User:</p>
            <p class="font-medium">{{ selectedUser.display_name || selectedUser.email }}</p>
          </div>

          <div>
            <p class="text-sm text-gray-600 mb-1">Current Role:</p>
            <UBadge :color="getRoleBadgeColor(selectedUser.role)" variant="subtle">
              {{ selectedUser.role.replace("_", " ") }}
            </UBadge>
          </div>

          <div>
            <p class="text-sm text-gray-600 mb-3">Select New Role:</p>
            <div class="space-y-2">
              <UButton
                v-if="selectedUser.role !== 'pending'"
                color="neutral"
                variant="outline"
                block
                @click="changeRole('pending')"
              >
                Pending
              </UButton>
              <UButton
                v-if="selectedUser.role !== 'approved'"
                color="success"
                variant="outline"
                block
                @click="changeRole('approved')"
              >
                Approved
              </UButton>
              <UButton
                v-if="selectedUser.role !== 'admin' && isSuperAdmin"
                color="primary"
                variant="outline"
                block
                @click="changeRole('admin')"
              >
                Admin
              </UButton>
              <UButton
                v-if="selectedUser.role !== 'super_admin' && isSuperAdmin"
                color="error"
                variant="outline"
                block
                @click="changeRole('super_admin')"
              >
                Super Admin
              </UButton>
            </div>
          </div>
        </div>

        <template #footer>
          <div class="flex justify-end">
            <UButton color="neutral" variant="outline" @click="showRoleModal = false">
              Cancel
            </UButton>
          </div>
        </template>
      </UCard>
    </UModal>
  </div>
</template>
