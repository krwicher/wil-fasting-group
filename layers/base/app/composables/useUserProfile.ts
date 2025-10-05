import type { UserProfile, UpdateProfileData } from "~/layers/base/shared/types/profile";

export const useUserProfile = () => {
  const supabase = useSupabaseClient();
  const user = useSupabaseUser();
  const toast = useToast();

  const profile = ref<UserProfile | null>(null);
  const loading = ref(false);
  const error = ref<string | null>(null);

  /**
   * Fetch the current user's profile
   */
  const fetchProfile = async () => {
    if (!user.value) {
      error.value = "User not authenticated";
      return;
    }

    loading.value = true;
    error.value = null;

    try {
      const { data, error: fetchError } = await supabase
        .from("user_profiles")
        .select("*")
        .eq("id", user.value.id)
        .single();

      if (fetchError) throw fetchError;

      profile.value = data;
    } catch (err) {
      error.value = (err as Error).message;
      console.error("Error fetching profile:", err);
    } finally {
      loading.value = false;
    }
  };

  /**
   * Fetch a specific user's profile by ID
   */
  const fetchProfileById = async (userId: string): Promise<UserProfile | null> => {
    try {
      const { data, error: fetchError } = await supabase
        .from("user_profiles")
        .select("*")
        .eq("id", userId)
        .single();

      if (fetchError) throw fetchError;

      return data;
    } catch (err) {
      console.error("Error fetching profile by ID:", err);
      return null;
    }
  };

  /**
   * Update the current user's profile
   */
  const updateProfile = async (updates: UpdateProfileData) => {
    if (!user.value) {
      error.value = "User not authenticated";
      return false;
    }

    loading.value = true;
    error.value = null;

    try {
      const { error: updateError } = await supabase
        .from("user_profiles")
        .update(updates)
        .eq("id", user.value.id);

      if (updateError) throw updateError;

      // Refresh profile data
      await fetchProfile();

      toast.add({
        title: "Profile updated",
        icon: "i-lucide-check-circle",
        color: "success",
      });

      return true;
    } catch (err) {
      error.value = (err as Error).message;
      console.error("Error updating profile:", err);

      toast.add({
        title: "Error",
        description: error.value,
        icon: "i-lucide-alert-circle",
        color: "error",
      });

      return false;
    } finally {
      loading.value = false;
    }
  };

  /**
   * Upload avatar to Supabase Storage and update profile
   */
  const uploadAvatar = async (file: File) => {
    if (!user.value) {
      error.value = "User not authenticated";
      return false;
    }

    loading.value = true;
    error.value = null;

    try {
      // Generate unique filename
      const fileExt = file.name.split(".").pop();
      const fileName = `${user.value.id}_${Date.now()}.${fileExt}`;
      const filePath = `${user.value.id}/${fileName}`;

      // Upload to Supabase Storage
      const { error: uploadError } = await supabase.storage
        .from("avatars")
        .upload(filePath, file, {
          upsert: true,
        });

      if (uploadError) throw uploadError;

      // Get public URL
      const { data } = supabase.storage
        .from("avatars")
        .getPublicUrl(filePath);

      // Update profile with new avatar URL
      await updateProfile({ avatar_url: data.publicUrl });

      return true;
    } catch (err) {
      error.value = (err as Error).message;
      console.error("Error uploading avatar:", err);

      toast.add({
        title: "Error",
        description: "Failed to upload avatar",
        icon: "i-lucide-alert-circle",
        color: "error",
      });

      return false;
    } finally {
      loading.value = false;
    }
  };

  /**
   * Delete all user data (GDPR compliance)
   */
  const deleteAllData = async () => {
    if (!user.value) {
      error.value = "User not authenticated";
      return false;
    }

    loading.value = true;
    error.value = null;

    try {
      // Call Supabase RPC function to delete all user data
      const { error: deleteError } = await supabase.rpc("delete_user_data", {
        user_id_to_delete: user.value.id,
      });

      if (deleteError) throw deleteError;

      // Sign out the user
      await supabase.auth.signOut();

      toast.add({
        title: "Account deleted",
        description: "All your data has been deleted",
        icon: "i-lucide-check-circle",
        color: "success",
      });

      return true;
    } catch (err) {
      error.value = (err as Error).message;
      console.error("Error deleting user data:", err);

      toast.add({
        title: "Error",
        description: "Failed to delete account",
        icon: "i-lucide-alert-circle",
        color: "error",
      });

      return false;
    } finally {
      loading.value = false;
    }
  };

  /**
   * Get user initials from display name or email
   */
  const getUserInitials = (userProfile: UserProfile | null): string => {
    if (!userProfile) return "?";

    if (userProfile.display_name) {
      const names = userProfile.display_name.trim().split(" ");
      if (names.length >= 2) {
        return `${names[0][0]}${names[names.length - 1][0]}`.toUpperCase();
      }
      return names[0].substring(0, 2).toUpperCase();
    }

    return "U";
  };

  return {
    profile: readonly(profile),
    loading: readonly(loading),
    error: readonly(error),
    fetchProfile,
    fetchProfileById,
    updateProfile,
    uploadAvatar,
    deleteAllData,
    getUserInitials,
  };
};
