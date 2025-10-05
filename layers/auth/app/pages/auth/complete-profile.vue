<script setup lang="ts">
import z from "zod";

definePageMeta({
  layout: "sign-up",
});

const supabase = useSupabaseClient();
const user = useSupabaseUser();
const toast = useToast();

// Redirect if already has display_name
if (user.value?.user_metadata?.display_name) {
  navigateTo("/", { replace: true });
}

// Auto-detect timezone
const detectedTimezone = ref(Intl.DateTimeFormat().resolvedOptions().timeZone);

const fields = [
  {
    name: "display_name",
    type: "text" as const,
    label: "Display Name",
    placeholder: "Enter your display name",
    required: true,
    size: "xl" as const,
  },
  {
    name: "timezone",
    type: "text" as const,
    label: "Timezone",
    placeholder: "Auto-detected",
    required: false,
    size: "xl" as const,
  },
];

const schema = z.object({
  display_name: z
    .string()
    .min(2, "Display name must be at least 2 characters")
    .max(50, "Display name must be less than 50 characters"),
  timezone: z.string().optional(),
});

async function handleSubmit(payload: any) {
  try {
    const displayName = payload.data.display_name;
    const timezone = payload.data.timezone || detectedTimezone.value;

    // Update user metadata
    const { error: updateError } = await supabase.auth.updateUser({
      data: {
        display_name: displayName,
        timezone: timezone,
      },
    });

    if (updateError) throw updateError;

    toast.add({
      title: "Profile completed",
      icon: "i-lucide-check-circle",
      color: "success",
    });

    // Check if user is pending approval
    const role = user.value?.user_metadata?.role;
    if (role === "pending") {
      await navigateTo("/auth/pending", { replace: true });
    } else {
      await navigateTo("/", { replace: true });
    }
  } catch (error) {
    toast.add({
      title: "Error",
      description: (error as Error).message,
      icon: "i-lucide-alert-circle",
      color: "error",
    });
  }
}

// Pre-fill with detected timezone
const initialState = {
  timezone: detectedTimezone.value,
};
</script>

<template>
  <div class="flex items-center justify-center py-12">
    <div class="w-full max-w-md px-4">
      <div class="mb-8 text-center">
        <h1 class="text-3xl font-bold mb-2">Complete Your Profile</h1>
        <p class="text-gray-600">
          Just a couple more details to get you started
        </p>
      </div>

      <UAuthForm
        :schema="schema"
        :fields="fields"
        :initial-state="initialState"
        @submit="handleSubmit"
        :submit="{
          label: 'Complete Profile',
          size: 'xl',
        }"
        class="max-w-[28rem] mx-auto"
        :ui="{
          title: 'text-3xl text-left',
          description: 'text-left',
        }"
      >
        <template #description>
          <div class="mb-6 p-4 bg-blue-50 rounded-lg border border-blue-200">
            <p class="text-sm text-blue-800">
              <strong>Welcome!</strong> We've auto-detected your timezone as
              <strong>{{ detectedTimezone }}</strong
              >. You can change it below if needed.
            </p>
          </div>
        </template>
      </UAuthForm>
    </div>
  </div>
</template>
