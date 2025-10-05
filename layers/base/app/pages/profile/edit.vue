<script setup lang="ts">
import { z } from "zod";

const {
  profile,
  loading: profileLoading,
  fetchProfile,
  updateProfile,
  uploadAvatar,
  deleteAllData,
} = useUserProfile();

const router = useRouter();
const toast = useToast();

// Fetch profile on mount
onMounted(async () => {
  await fetchProfile();
  if (profile.value) {
    // Pre-fill form with existing data
    formState.value = {
      display_name: profile.value.display_name || "",
      bio: profile.value.bio || "",
      timezone: profile.value.timezone,
      profile_visibility: profile.value.profile_visibility,
      show_fasting_stats: profile.value.show_fasting_stats,
    };
  }
});

// Form state
const formState = ref({
  display_name: "",
  bio: "",
  timezone: "UTC",
  profile_visibility: "public" as "public" | "community" | "private",
  show_fasting_stats: true,
});

// Avatar upload
const avatarFile = ref<File | null>(null);
const avatarPreview = ref<string | null>(null);
const uploadingAvatar = ref(false);

// Handle avatar file selection
const handleAvatarChange = (event: Event) => {
  const target = event.target as HTMLInputElement;
  const file = target.files?.[0];

  if (file) {
    // Validate file type
    if (!file.type.startsWith("image/")) {
      toast.add({
        title: "Error",
        description: "Please select an image file",
        icon: "i-lucide-alert-circle",
        color: "error",
      });
      return;
    }

    // Validate file size (max 5MB)
    if (file.size > 5 * 1024 * 1024) {
      toast.add({
        title: "Error",
        description: "Image size must be less than 5MB",
        icon: "i-lucide-alert-circle",
        color: "error",
      });
      return;
    }

    avatarFile.value = file;

    // Create preview
    const reader = new FileReader();
    reader.onload = (e) => {
      avatarPreview.value = e.target?.result as string;
    };
    reader.readAsDataURL(file);
  }
};

// Upload avatar
const handleAvatarUpload = async () => {
  if (!avatarFile.value) return;

  uploadingAvatar.value = true;
  const success = await uploadAvatar(avatarFile.value);
  uploadingAvatar.value = false;

  if (success) {
    avatarFile.value = null;
    avatarPreview.value = null;
    await fetchProfile();
  }
};

// Validation schema
const schema = z.object({
  display_name: z
    .string()
    .min(2, "Display name must be at least 2 characters")
    .max(50, "Display name must be less than 50 characters"),
  bio: z.string().max(500, "Bio must be less than 500 characters").optional(),
  timezone: z.string().min(1, "Timezone is required"),
  profile_visibility: z.enum(["public", "community", "private"]),
  show_fasting_stats: z.boolean(),
});

// Form submission
const submitting = ref(false);

const handleSubmit = async () => {
  try {
    const validated = schema.parse(formState.value);

    submitting.value = true;
    const success = await updateProfile(validated);
    submitting.value = false;

    if (success) {
      router.push("/profile");
    }
  } catch (error) {
    submitting.value = false;
    if (error instanceof z.ZodError) {
      const firstError = error.errors[0];
      toast.add({
        title: "Validation Error",
        description: firstError.message,
        icon: "i-lucide-alert-circle",
        color: "error",
      });
    }
  }
};

// Delete account
const showDeleteConfirmation = ref(false);
const deleteConfirmationText = ref("");
const deleting = ref(false);

const handleDeleteAccount = async () => {
  if (deleteConfirmationText.value !== "DELETE") {
    toast.add({
      title: "Error",
      description: 'Please type "DELETE" to confirm',
      icon: "i-lucide-alert-circle",
      color: "error",
    });
    return;
  }

  deleting.value = true;
  await deleteAllData();
  deleting.value = false;

  // User will be signed out and redirected by the composable
  router.push("/sign-in");
};

// Timezone options (common timezones)
const timezoneOptions = [
  "UTC",
  "America/New_York",
  "America/Chicago",
  "America/Denver",
  "America/Los_Angeles",
  "America/Toronto",
  "America/Mexico_City",
  "America/Sao_Paulo",
  "Europe/London",
  "Europe/Paris",
  "Europe/Berlin",
  "Europe/Warsaw",
  "Europe/Moscow",
  "Asia/Dubai",
  "Asia/Kolkata",
  "Asia/Shanghai",
  "Asia/Tokyo",
  "Asia/Seoul",
  "Australia/Sydney",
  "Pacific/Auckland",
];
</script>

<template>
  <div class="container mx-auto px-4 py-8 max-w-4xl">
    <div class="mb-6">
      <UButton
        color="neutral"
        variant="ghost"
        icon="i-lucide-arrow-left"
        to="/profile"
      >
        Back to Profile
      </UButton>
    </div>

    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-8">
      <h1 class="text-3xl font-bold mb-6">Edit Profile</h1>

      <!-- Loading State -->
      <div v-if="profileLoading" class="flex justify-center py-12">
        <UIcon name="i-lucide-loader-2" class="w-8 h-8 animate-spin text-primary-500" />
      </div>

      <!-- Edit Form -->
      <div v-else-if="profile" class="space-y-8">
        <!-- Avatar Section -->
        <div class="space-y-4">
          <h2 class="text-xl font-semibold">Avatar</h2>
          <div class="flex items-center gap-6">
            <ProfileAvatar
              :profile="{ ...profile, avatar_url: avatarPreview || profile.avatar_url }"
              size="2xl"
            />
            <div class="flex-1 space-y-2">
              <input
                type="file"
                accept="image/*"
                @change="handleAvatarChange"
                class="block w-full text-sm text-gray-500
                  file:mr-4 file:py-2 file:px-4
                  file:rounded-full file:border-0
                  file:text-sm file:font-semibold
                  file:bg-primary-50 file:text-primary-700
                  hover:file:bg-primary-100
                  cursor-pointer"
              />
              <p class="text-sm text-gray-500">
                JPG, PNG, or GIF. Max size 5MB.
              </p>
              <UButton
                v-if="avatarFile"
                color="primary"
                size="sm"
                :loading="uploadingAvatar"
                @click="handleAvatarUpload"
              >
                Upload Avatar
              </UButton>
            </div>
          </div>
        </div>

        <UDivider />

        <!-- Profile Form -->
        <form @submit.prevent="handleSubmit" class="space-y-6">
          <!-- Display Name -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Display Name *
            </label>
            <UInput
              v-model="formState.display_name"
              placeholder="Enter your display name"
              size="lg"
              required
            />
          </div>

          <!-- Bio -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Bio
            </label>
            <UTextarea
              v-model="formState.bio"
              placeholder="Tell us about yourself..."
              :rows="4"
              size="lg"
            />
            <p class="text-sm text-gray-500 mt-1">
              {{ formState.bio?.length || 0 }} / 500 characters
            </p>
          </div>

          <!-- Timezone -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Timezone *
            </label>
            <USelect
              v-model="formState.timezone"
              :options="timezoneOptions"
              size="lg"
            />
          </div>

          <!-- Profile Visibility -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Profile Visibility
            </label>
            <URadioGroup
              v-model="formState.profile_visibility"
              :options="[
                { value: 'public', label: 'Public - Anyone can see your profile' },
                { value: 'community', label: 'Community - Only approved members can see' },
                { value: 'private', label: 'Private - Only you can see your profile' },
              ]"
            />
          </div>

          <!-- Show Fasting Stats -->
          <div class="flex items-center gap-3">
            <UCheckbox
              v-model="formState.show_fasting_stats"
              id="show_fasting_stats"
            />
            <label for="show_fasting_stats" class="text-sm font-medium text-gray-700">
              Show my fasting stats publicly
            </label>
          </div>

          <UDivider />

          <!-- Action Buttons -->
          <div class="flex gap-3">
            <UButton
              type="submit"
              color="primary"
              size="lg"
              :loading="submitting"
            >
              Save Changes
            </UButton>
            <UButton
              type="button"
              color="neutral"
              variant="outline"
              size="lg"
              to="/profile"
            >
              Cancel
            </UButton>
          </div>
        </form>

        <UDivider />

        <!-- Danger Zone -->
        <div class="space-y-4">
          <h2 class="text-xl font-semibold text-red-600">Danger Zone</h2>
          <div class="border border-red-200 rounded-lg p-6 bg-red-50">
            <h3 class="font-semibold mb-2">Delete All My Data</h3>
            <p class="text-sm text-gray-600 mb-4">
              This will permanently delete your account and all associated data.
              This action cannot be undone.
            </p>
            <UButton
              color="error"
              variant="outline"
              @click="showDeleteConfirmation = true"
            >
              Delete Account
            </UButton>
          </div>
        </div>
      </div>
    </div>

    <!-- Delete Confirmation Modal -->
    <UModal v-model="showDeleteConfirmation">
      <UCard>
        <template #header>
          <h3 class="text-xl font-bold text-red-600">Confirm Account Deletion</h3>
        </template>

        <div class="space-y-4">
          <p class="text-gray-700">
            Are you absolutely sure you want to delete your account? This will:
          </p>
          <ul class="list-disc list-inside text-sm text-gray-600 space-y-1">
            <li>Delete your profile and all personal information</li>
            <li>Remove you from all group fasts</li>
            <li>Delete all your fast history</li>
            <li>Remove all your chat messages</li>
            <li>Delete all your achievements</li>
          </ul>
          <p class="text-red-600 font-semibold">
            This action cannot be undone!
          </p>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Type "DELETE" to confirm
            </label>
            <UInput
              v-model="deleteConfirmationText"
              placeholder="DELETE"
              size="lg"
            />
          </div>
        </div>

        <template #footer>
          <div class="flex gap-3 justify-end">
            <UButton
              color="neutral"
              variant="outline"
              @click="showDeleteConfirmation = false"
            >
              Cancel
            </UButton>
            <UButton
              color="error"
              :loading="deleting"
              @click="handleDeleteAccount"
            >
              Delete My Account
            </UButton>
          </div>
        </template>
      </UCard>
    </UModal>
  </div>
</template>
