import { AdminRepository } from "../repositories/adminRepository";
import type { AdminUser, AdminStats } from "../../shared/types/admin";

export const useAdmin = () => {
  const supabase = useSupabaseClient();
  const toast = useToast();
  const { isAdmin } = useUserRole();

  const repository = new AdminRepository(supabase);

  const users = ref<AdminUser[]>([]);
  const stats = ref<AdminStats | null>(null);
  const loading = ref(false);
  const error = ref<string | null>(null);

  /**
   * Fetch all users (admin only)
   */
  const fetchUsers = async (roleFilter?: UserRole) => {
    if (!isAdmin.value) {
      error.value = "Unauthorized";
      return;
    }

    loading.value = true;
    error.value = null;

    try {
      users.value = await repository.listUsers(roleFilter);
    } catch (err) {
      error.value = (err as Error).message;
      console.error("Error fetching users:", err);
      toast.add({
        title: "Error",
        description: "Failed to fetch users",
        icon: "i-lucide-alert-circle",
        color: "error",
      });
    } finally {
      loading.value = false;
    }
  };

  /**
   * Update user role (admin only)
   */
  const updateUserRole = async (
    userId: string,
    newRole: UserRole
  ): Promise<boolean> => {
    if (!isAdmin.value) {
      error.value = "Unauthorized";
      return false;
    }

    loading.value = true;
    error.value = null;

    try {
      await repository.updateUserRole(userId, newRole);

      toast.add({
        title: "Success",
        description: "User role updated successfully",
        icon: "i-lucide-check-circle",
        color: "success",
      });

      // Refresh users list
      await fetchUsers();

      return true;
    } catch (err) {
      error.value = (err as Error).message;
      console.error("Error updating user role:", err);
      toast.add({
        title: "Error",
        description: "Failed to update user role",
        icon: "i-lucide-alert-circle",
        color: "error",
      });
      return false;
    } finally {
      loading.value = false;
    }
  };

  /**
   * Approve user (set role to 'approved')
   */
  const approveUser = async (userId: string): Promise<boolean> => {
    return await updateUserRole(userId, "approved");
  };

  /**
   * Reject user (delete account)
   */
  const rejectUser = async (userId: string): Promise<boolean> => {
    if (!isAdmin.value) {
      error.value = "Unauthorized";
      return false;
    }

    loading.value = true;
    error.value = null;

    try {
      await repository.deleteUser(userId);

      toast.add({
        title: "Success",
        description: "User rejected and deleted",
        icon: "i-lucide-check-circle",
        color: "success",
      });

      // Refresh users list
      await fetchUsers();

      return true;
    } catch (err) {
      error.value = (err as Error).message;
      console.error("Error rejecting user:", err);
      toast.add({
        title: "Error",
        description: "Failed to reject user",
        icon: "i-lucide-alert-circle",
        color: "error",
      });
      return false;
    } finally {
      loading.value = false;
    }
  };

  /**
   * Fetch admin statistics
   */
  const fetchStats = async () => {
    if (!isAdmin.value) {
      error.value = "Unauthorized";
      return;
    }

    loading.value = true;
    error.value = null;

    try {
      stats.value = await repository.getAdminStats();
    } catch (err) {
      error.value = (err as Error).message;
      console.error("Error fetching stats:", err);
      toast.add({
        title: "Error",
        description: "Failed to fetch statistics",
        icon: "i-lucide-alert-circle",
        color: "error",
      });
    } finally {
      loading.value = false;
    }
  };

  /**
   * Get pending users count
   */
  const getPendingCount = async (): Promise<number> => {
    try {
      return await repository.getPendingUsersCount();
    } catch (err) {
      console.error("Error fetching pending count:", err);
      return 0;
    }
  };

  return {
    users: readonly(users),
    stats: readonly(stats),
    loading: readonly(loading),
    error: readonly(error),
    fetchUsers,
    updateUserRole,
    approveUser,
    rejectUser,
    fetchStats,
    getPendingCount,
  };
};
