<script setup lang="ts">
const { isAuthenticated, signOut } = useAuth();
const { isAdmin } = useUserRole();

const pendingCount = ref(0);

// Fetch pending count for admins
const fetchPendingCount = async () => {
  if (!isAdmin.value) return;

  try {
    const { getPendingCount } = useAdmin();
    pendingCount.value = await getPendingCount();
  } catch (error) {
    console.error("Failed to fetch pending count:", error);
  }
};

// Fetch on mount and every 30 seconds
onMounted(async () => {
  await fetchPendingCount();

  // Poll for updates every 30 seconds
  if (isAdmin.value) {
    setInterval(fetchPendingCount, 30000);
  }
});

const searchTerm = ref("");
const navigationItems = ref([
  {
    label: "Leady",
    type: "link",
    to: "/leads",
  },
]);
</script>

<template>
  <header class="w-full bg-white">
    <div class="header-main py-4 max-w-full">
      <UContainer>
        <div class="flex items-center justify-between gap-4">
          <UButton variant="link">
            <NuxtImg src="/images/logo.avif" alt="Logo" class="h-10" />
          </UButton>

          <template v-if="!isAuthenticated">
            <div class="flex items-center gap-4">
              <UButton
                variant="link"
                icon="i-lucide-user"
                class="hidden lg:flex"
                to="/sign-up"
              >
                <span class="">Zarejestruj się</span>
              </UButton>
              <UButton variant="solid" icon="i-lucide-user" to="/sign-in">
                <span class="hidden lg:inline">Zaloguj się</span>
              </UButton>
            </div>
          </template>
          <template v-else>
            <div class="flex items-center gap-4">
              <!-- Admin Dashboard Link with Badge -->
              <UButton
                v-if="isAdmin"
                variant="outline"
                icon="i-lucide-shield"
                to="/admin/dashboard"
                class="relative"
              >
                <span class="hidden lg:inline">Admin</span>
                <UBadge
                  v-if="pendingCount > 0"
                  color="error"
                  variant="solid"
                  class="absolute -top-1 -right-1"
                  size="xs"
                >
                  {{ pendingCount }}
                </UBadge>
              </UButton>

              <UButton variant="solid" icon="i-lucide-user" to="/profile">
                <span class="hidden lg:inline">Konto użytkownika</span>
              </UButton>
              <UButton
                variant="link"
                icon="i-lucide-log-out"
                @click="signOut"
              ></UButton>
            </div>
          </template>
        </div>
      </UContainer>
    </div>
    <UContainer class="header-navigation" v-if="isAuthenticated">
      <UNavigationMenu :items="navigationItems" class="w-full justify-start" />
    </UContainer>
  </header>
</template>

<style scoped>
.header-badge {
  background-color: var(--ui-primary);
  /* color: var(--ui-text-white); */
  font-weight: 600;
}

.header-main {
  border-bottom: 1px solid var(--ui-primary);
}

.header-main__search {
  border: 1px solid var(--ui-primary);
}
</style>
