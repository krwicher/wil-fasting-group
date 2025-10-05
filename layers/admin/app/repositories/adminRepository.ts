import type { SupabaseClient } from "@supabase/supabase-js";

export class AdminRepository {
  constructor(private supabase: SupabaseClient) {}

  /**
   * Fetch all users (requires admin auth client)
   */
  async listUsers(roleFilter?: UserRole): Promise<AdminUser[]> {
    const { data, error } = await this.supabase.auth.admin.listUsers();

    if (error) {
      throw new Error(`Failed to fetch users: ${error.message}`);
    }

    // Map auth users to AdminUser format
    let mappedUsers: AdminUser[] = data.users.map((user) => ({
      id: user.id,
      email: user.email || "",
      display_name: user.user_metadata?.display_name || null,
      role: (user.user_metadata?.role || "pending") as UserRole,
      created_at: user.created_at,
      updated_at: user.updated_at || null,
      last_sign_in_at: user.last_sign_in_at || null,
    }));

    // Filter by role if specified
    if (roleFilter) {
      mappedUsers = mappedUsers.filter((user) => user.role === roleFilter);
    }

    // Sort by created_at descending (newest first)
    mappedUsers.sort(
      (a, b) =>
        new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
    );

    return mappedUsers;
  }

  /**
   * Update user role
   */
  async updateUserRole(userId: string, newRole: UserRole): Promise<void> {
    const { error } = await this.supabase.auth.admin.updateUserById(userId, {
      user_metadata: { role: newRole },
    });

    if (error) {
      throw new Error(`Failed to update user role: ${error.message}`);
    }
  }

  /**
   * Delete user account
   */
  async deleteUser(userId: string): Promise<void> {
    const { error } = await this.supabase.auth.admin.deleteUser(userId);

    if (error) {
      throw new Error(`Failed to delete user: ${error.message}`);
    }
  }

  /**
   * Fetch admin statistics
   */
  async getAdminStats(): Promise<AdminStats> {
    // Fetch all users
    const { data: allUsersData, error: usersError } =
      await this.supabase.auth.admin.listUsers();

    if (usersError) {
      throw new Error(`Failed to fetch users: ${usersError.message}`);
    }

    const allUsers = allUsersData.users;

    // Count users by role
    const pendingCount = allUsers.filter(
      (u) => u.user_metadata?.role === "pending"
    ).length;
    const approvedCount = allUsers.filter(
      (u) => u.user_metadata?.role === "approved"
    ).length;
    const adminCount = allUsers.filter((u) =>
      ["admin", "super_admin"].includes(u.user_metadata?.role)
    ).length;

    // Fetch fast counts
    const { count: totalFasts, error: fastsError } = await this.supabase
      .from("group_fasts")
      .select("*", { count: "exact", head: true });

    if (fastsError) {
      throw new Error(`Failed to fetch total fasts: ${fastsError.message}`);
    }

    const { count: activeFasts, error: activeFastsError } = await this.supabase
      .from("group_fasts")
      .select("*", { count: "exact", head: true })
      .eq("status", "active");

    if (activeFastsError) {
      throw new Error(
        `Failed to fetch active fasts: ${activeFastsError.message}`
      );
    }

    // Fetch participant count
    const { count: totalParticipants, error: participantsError } =
      await this.supabase
        .from("fast_participants")
        .select("*", { count: "exact", head: true });

    if (participantsError) {
      throw new Error(
        `Failed to fetch participants: ${participantsError.message}`
      );
    }

    return {
      total_users: allUsers.length,
      pending_users: pendingCount,
      approved_users: approvedCount,
      admin_users: adminCount,
      total_fasts: totalFasts || 0,
      active_fasts: activeFasts || 0,
      total_participants: totalParticipants || 0,
    };
  }

  /**
   * Get count of pending users
   */
  async getPendingUsersCount(): Promise<number> {
    const { data, error } = await this.supabase.auth.admin.listUsers();

    if (error) {
      throw new Error(`Failed to fetch users: ${error.message}`);
    }

    return data.users.filter((u) => u.user_metadata?.role === "pending").length;
  }
}
