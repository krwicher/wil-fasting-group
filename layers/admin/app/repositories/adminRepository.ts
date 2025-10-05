import type { SupabaseClient } from "@supabase/supabase-js";
import type { AdminUser, AdminStats, ApprovalStatus } from "../../shared/types/admin";
import type { UserRole } from "~/layers/auth/app/composables/useAuth";

/**
 * Admin Repository
 * Handles admin operations for user management
 * Uses user_profiles table for listing/filtering (no service role key needed)
 * Uses server API for privileged operations (role updates, deletions)
 */
export class AdminRepository {
  constructor(private supabase: SupabaseClient) {}

  /**
   * Fetch all users from user_profiles table
   * Can filter by approval_status or role
   */
  async listUsers(filter?: {
    approval_status?: ApprovalStatus;
    role?: UserRole;
  }): Promise<AdminUser[]> {
    let query = this.supabase
      .from("user_profiles")
      .select(
        `
        id,
        display_name,
        approval_status,
        created_at,
        updated_at
      `
      )
      .order("created_at", { ascending: false });

    // Apply filters
    if (filter?.approval_status) {
      query = query.eq("approval_status", filter.approval_status);
    }

    const { data: profiles, error: profilesError } = await query;

    if (profilesError) {
      throw new Error(`Failed to fetch user profiles: ${profilesError.message}`);
    }

    // Fetch auth metadata from admin_users_view (created in migration)
    const { data: authData, error: authError } = await this.supabase
      .from("admin_users_view")
      .select("id, email, role, last_sign_in_at")
      .in(
        "id",
        profiles.map((p) => p.id)
      );

    if (authError) {
      console.warn("Could not fetch auth data:", authError);
      // Fallback: return profiles without auth data
      return profiles.map((profile) => ({
        id: profile.id,
        email: "",
        display_name: profile.display_name,
        role: "pending" as UserRole,
        approval_status: profile.approval_status as ApprovalStatus,
        created_at: profile.created_at,
        updated_at: profile.updated_at,
        last_sign_in_at: null,
      }));
    }

    // Merge profile and auth data
    const authMap = new Map(
      authData.map((a) => [a.id, a])
    );

    const users: AdminUser[] = profiles.map((profile) => {
      const auth = authMap.get(profile.id);
      return {
        id: profile.id,
        email: auth?.email || "",
        display_name: profile.display_name,
        role: (auth?.role || "pending") as UserRole,
        approval_status: profile.approval_status as ApprovalStatus,
        created_at: profile.created_at,
        updated_at: profile.updated_at,
        last_sign_in_at: auth?.last_sign_in_at || null,
      };
    });

    // Apply role filter if specified
    if (filter?.role) {
      return users.filter((u) => u.role === filter.role);
    }

    return users;
  }

  /**
   * Update user role via server API
   */
  async updateUserRole(userId: string, newRole: UserRole): Promise<void> {
    const response = await $fetch(`/api/admin/users/${userId}/role`, {
      method: "PATCH",
      body: { role: newRole },
    });

    if (!response.success) {
      throw new Error("Failed to update user role");
    }
  }

  /**
   * Update user approval status in user_profiles
   */
  async updateApprovalStatus(
    userId: string,
    status: ApprovalStatus
  ): Promise<void> {
    const { error } = await this.supabase
      .from("user_profiles")
      .update({ approval_status: status })
      .eq("id", userId);

    if (error) {
      throw new Error(`Failed to update approval status: ${error.message}`);
    }
  }

  /**
   * Approve user: set approval_status to 'approved' and role to 'approved'
   */
  async approveUser(userId: string): Promise<void> {
    // Update approval status in user_profiles
    await this.updateApprovalStatus(userId, "approved");

    // Update role in auth.users via server API
    await this.updateUserRole(userId, "approved");
  }

  /**
   * Delete user account via server API
   */
  async deleteUser(userId: string): Promise<void> {
    const response = await $fetch(`/api/admin/users/${userId}`, {
      method: "DELETE",
    });

    if (!response.success) {
      throw new Error("Failed to delete user");
    }
  }

  /**
   * Fetch admin statistics
   */
  async getAdminStats(): Promise<AdminStats> {
    // Count users by approval_status
    const { count: totalUsers, error: totalError } = await this.supabase
      .from("user_profiles")
      .select("*", { count: "exact", head: true });

    if (totalError) {
      throw new Error(`Failed to count total users: ${totalError.message}`);
    }

    const { count: pendingUsers, error: pendingError } = await this.supabase
      .from("user_profiles")
      .select("*", { count: "exact", head: true })
      .eq("approval_status", "pending");

    if (pendingError) {
      throw new Error(`Failed to count pending users: ${pendingError.message}`);
    }

    const { count: approvedUsers, error: approvedError } = await this.supabase
      .from("user_profiles")
      .select("*", { count: "exact", head: true })
      .eq("approval_status", "approved");

    if (approvedError) {
      throw new Error(`Failed to count approved users: ${approvedError.message}`);
    }

    // For admin count, we'll estimate as 0 for now (TODO: implement proper count)
    // Would need to query admin_users_view and count by role

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
      total_users: totalUsers || 0,
      pending_users: pendingUsers || 0,
      approved_users: approvedUsers || 0,
      admin_users: 0, // TODO: Implement proper admin count via RPC
      total_fasts: totalFasts || 0,
      active_fasts: activeFasts || 0,
      total_participants: totalParticipants || 0,
    };
  }

  /**
   * Get count of pending users
   */
  async getPendingUsersCount(): Promise<number> {
    const { count, error } = await this.supabase
      .from("user_profiles")
      .select("*", { count: "exact", head: true })
      .eq("approval_status", "pending");

    if (error) {
      throw new Error(`Failed to count pending users: ${error.message}`);
    }

    return count || 0;
  }
}
