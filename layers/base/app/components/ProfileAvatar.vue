<script setup lang="ts">
import type { UserProfile } from "~/layers/base/shared/types/profile";

interface Props {
  profile: UserProfile | null;
  size?: "xs" | "sm" | "md" | "lg" | "xl" | "2xl";
}

const props = withDefaults(defineProps<Props>(), {
  size: "md",
});

const { getUserInitials } = useUserProfile();

const sizeClasses = computed(() => {
  const sizes = {
    xs: "w-6 h-6 text-xs",
    sm: "w-8 h-8 text-sm",
    md: "w-10 h-10 text-base",
    lg: "w-12 h-12 text-lg",
    xl: "w-16 h-16 text-xl",
    "2xl": "w-24 h-24 text-3xl",
  };
  return sizes[props.size];
});

const initials = computed(() => getUserInitials(props.profile));

const displayName = computed(() => {
  return props.profile?.display_name || "User";
});
</script>

<template>
  <div
    :class="[
      'relative inline-flex items-center justify-center rounded-full overflow-hidden bg-gradient-to-br from-primary-500 to-primary-600 text-white font-semibold',
      sizeClasses,
    ]"
    :title="displayName"
  >
    <img
      v-if="profile?.avatar_url"
      :src="profile.avatar_url"
      :alt="displayName"
      class="w-full h-full object-cover"
      @error="(e) => ((e.target as HTMLImageElement).style.display = 'none')"
    />
    <span v-else>{{ initials }}</span>
  </div>
</template>
