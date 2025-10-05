import { UserRepository } from "../repositories/userRepository";

export const useUserProfile = () => {
  const supabase = useSupabaseClient();
  const user = useSupabaseUser();
  const toast = useToast();

  const repository = new UserRepository(supabase);

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
      profile.value = await repository.getProfile(user.value.id);
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
  const fetchProfileById = async (
    userId: string
  ): Promise<UserProfile | null> => {
    try {
      return await repository.getProfile(userId);
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
      await repository.updateProfile(user.value.id, updates);

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
      await repository.uploadAvatar(user.value.id, file);

      // Refresh profile data
      await fetchProfile();

      toast.add({
        title: "Avatar uploaded",
        icon: "i-lucide-check-circle",
        color: "success",
      });

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
    return repository.getUserInitials(userProfile);
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
