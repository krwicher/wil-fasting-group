<script setup lang="ts">
/**
 * OAuth callback handler
 * This page is redirected to after OAuth authentication (Google, Apple)
 */

definePageMeta({
  layout: "sign-up",
});

const supabase = useSupabaseClient();
const toast = useToast();
const route = useRoute();
const loading = ref(true);
const error = ref<string | null>(null);

onMounted(async () => {
  try {
    // Get the OAuth code from the URL
    const code = route.query.code as string;

    if (!code) {
      error.value = "No authorization code found";
      loading.value = false;
      return;
    }

    // Exchange the code for a session
    const { data, error: authError } = await supabase.auth.exchangeCodeForSession(code);

    if (authError) {
      throw authError;
    }

    if (data.user) {
      // Check if user needs to complete their profile
      const needsProfileCompletion = !data.user.user_metadata?.display_name;

      if (needsProfileCompletion) {
        // Redirect to profile completion
        await navigateTo("/auth/complete-profile", { replace: true });
      } else {
        // Check if user is pending approval
        const role = data.user.user_metadata?.role;
        if (role === "pending") {
          await navigateTo("/auth/pending", { replace: true });
        } else {
          // User is approved, go to home
          toast.add({
            title: "Signed in successfully",
            icon: "i-lucide-check-circle",
            color: "success",
          });
          await navigateTo("/", { replace: true });
        }
      }
    }
  } catch (err) {
    console.error("OAuth callback error:", err);
    error.value = (err as Error).message;
    toast.add({
      title: "Authentication Error",
      description: error.value,
      icon: "i-lucide-alert-circle",
      color: "error",
    });
    loading.value = false;
  }
});
</script>

<template>
  <div class="flex items-center justify-center min-h-screen">
    <div class="text-center max-w-md mx-auto p-8">
      <div v-if="loading" class="space-y-4">
        <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto"></div>
        <h2 class="text-xl font-semibold">Completing sign in...</h2>
        <p class="text-gray-600">Please wait while we authenticate your account.</p>
      </div>

      <div v-else-if="error" class="space-y-4">
        <div class="text-red-500">
          <UIcon name="i-lucide-alert-circle" class="w-12 h-12 mx-auto" />
        </div>
        <h2 class="text-xl font-semibold text-red-600">Authentication Failed</h2>
        <p class="text-gray-600">{{ error }}</p>
        <UButton to="/sign-in" color="primary" size="lg">
          Back to Sign In
        </UButton>
      </div>
    </div>
  </div>
</template>
