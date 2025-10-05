export type UserRole = "pending" | "approved" | "admin" | "super_admin";

export const useAuth = () => {
  const user = useSupabaseUser();
  const supabase = useSupabaseClient();

  async function signOut() {
    try {
      const { error } = await supabase.auth.signOut();
      if (error) throw error;
      user.value = null;
    } catch (error) {
      alert((error as Error).message);
    } finally {
      await navigateTo("/sign-in");
    }
  }

  const isAuthenticated = computed(() => user.value?.role === "authenticated");

  const userName = computed(() => user.value?.user_metadata?.name ?? user.value?.user_metadata?.display_name);

  const userEmail = computed(() => user.value?.email ?? null);

  const userRole = computed<UserRole>(() => {
    return (user.value?.user_metadata?.role as UserRole) ?? "pending";
  });

  const isApproved = computed(() => {
    const role = userRole.value;
    return role === "approved" || role === "admin" || role === "super_admin";
  });

  const isAdmin = computed(() => {
    const role = userRole.value;
    return role === "admin" || role === "super_admin";
  });

  const isSuperAdmin = computed(() => {
    return userRole.value === "super_admin";
  });

  const isPending = computed(() => {
    return userRole.value === "pending";
  });

  return {
    isAuthenticated,
    user: readonly(user),
    refresh: fetch,
    signOut,
    userName,
    userEmail,
    userRole: readonly(userRole),
    isApproved: readonly(isApproved),
    isAdmin: readonly(isAdmin),
    isSuperAdmin: readonly(isSuperAdmin),
    isPending: readonly(isPending),
  };
};
