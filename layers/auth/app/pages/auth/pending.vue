<script setup lang="ts">
definePageMeta({
  layout: "sign-up",
});

const { user, signOut } = useAuth();
const userEmail = computed(() => user.value?.email);
const userName = computed(
  () => user.value?.user_metadata?.display_name || "there"
);
</script>

<template>
  <div class="flex items-center justify-center min-h-screen py-12">
    <div class="w-full max-w-2xl px-4">
      <div class="bg-white rounded-lg shadow-lg p-8 text-center">
        <!-- Pending Icon -->
        <div class="mb-6">
          <div
            class="w-20 h-20 bg-yellow-100 rounded-full flex items-center justify-center mx-auto"
          >
            <UIcon
              name="i-lucide-clock"
              class="w-10 h-10 text-yellow-600"
            />
          </div>
        </div>

        <!-- Title -->
        <h1 class="text-3xl font-bold mb-4">Awaiting Approval</h1>

        <!-- Message -->
        <div class="space-y-4 text-gray-600 mb-8">
          <p class="text-lg">
            Hi <strong>{{ userName }}</strong>, thanks for signing up!
          </p>
          <p>
            Your account (<strong>{{ userEmail }}</strong>) is currently pending
            approval from our community administrators. This is a closed
            community for the "What I've Learned" fasting group, and we manually
            review all new registrations to maintain a supportive environment.
          </p>
          <p>
            You'll receive access to the app once an admin approves your
            account. This typically happens within 24-48 hours.
          </p>
        </div>

        <!-- Info Box -->
        <div
          class="bg-blue-50 border border-blue-200 rounded-lg p-6 mb-8 text-left"
        >
          <h3 class="font-semibold text-blue-900 mb-3">
            What happens next?
          </h3>
          <ul class="space-y-2 text-sm text-blue-800">
            <li class="flex items-start">
              <UIcon
                name="i-lucide-check-circle"
                class="w-5 h-5 mr-2 mt-0.5 flex-shrink-0"
              />
              <span
                >An admin will review your registration and verify you're part of
                the community</span
              >
            </li>
            <li class="flex items-start">
              <UIcon
                name="i-lucide-check-circle"
                class="w-5 h-5 mr-2 mt-0.5 flex-shrink-0"
              />
              <span
                >Once approved, you'll be able to access all features including
                group fasts, leaderboards, and chat</span
              >
            </li>
            <li class="flex items-start">
              <UIcon
                name="i-lucide-check-circle"
                class="w-5 h-5 mr-2 mt-0.5 flex-shrink-0"
              />
              <span
                >You can check back anytime by signing in again - this page will
                update when you're approved</span
              >
            </li>
          </ul>
        </div>

        <!-- Actions -->
        <div class="flex flex-col sm:flex-row gap-3 justify-center">
          <UButton
            color="primary"
            size="lg"
            @click="$router.go(0)"
            variant="outline"
          >
            <template #leading>
              <UIcon name="i-lucide-refresh-cw" />
            </template>
            Refresh Status
          </UButton>

          <UButton color="neutral" size="lg" @click="signOut" variant="outline">
            <template #leading>
              <UIcon name="i-lucide-log-out" />
            </template>
            Sign Out
          </UButton>
        </div>

        <!-- Contact Info -->
        <div class="mt-8 pt-6 border-t border-gray-200">
          <p class="text-sm text-gray-500">
            Questions about your approval?
            <a
              href="https://www.youtube.com/@WhatIveLearned"
              target="_blank"
              class="text-primary hover:underline"
              >Visit the What I've Learned channel</a
            >
          </p>
        </div>
      </div>
    </div>
  </div>
</template>
