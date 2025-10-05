import type { UserRole } from "./useAuth";

/**
 * Composable for role-based access control
 * Re-exports role checking utilities from useAuth for convenience
 */
export const useUserRole = () => {
  const { userRole, isApproved, isAdmin, isSuperAdmin, isPending } = useAuth();

  /**
   * Check if user has at least one of the specified roles
   */
  const hasRole = (roles: UserRole | UserRole[]): boolean => {
    const rolesToCheck = Array.isArray(roles) ? roles : [roles];
    return rolesToCheck.includes(userRole.value);
  };

  /**
   * Check if user has at least the minimum required role
   * Role hierarchy: pending < approved < admin < super_admin
   */
  const hasMinimumRole = (minimumRole: UserRole): boolean => {
    const roleHierarchy: UserRole[] = [
      "pending",
      "approved",
      "admin",
      "super_admin",
    ];
    const userRoleIndex = roleHierarchy.indexOf(userRole.value);
    const minimumRoleIndex = roleHierarchy.indexOf(minimumRole);
    return userRoleIndex >= minimumRoleIndex;
  };

  /**
   * Check if user can perform an action based on role
   */
  const canCreateFast = computed(() => isApproved.value);
  const canModerateChat = computed(() => isAdmin.value);
  const canManageUsers = computed(() => isAdmin.value);
  const canPromoteToAdmin = computed(() => isSuperAdmin.value);

  return {
    userRole,
    isApproved,
    isAdmin,
    isSuperAdmin,
    isPending,
    hasRole,
    hasMinimumRole,
    canCreateFast,
    canModerateChat,
    canManageUsers,
    canPromoteToAdmin,
  };
};
