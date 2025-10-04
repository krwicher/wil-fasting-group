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

  const userName = computed(() => user.value?.user_metadata.name);

  const userEmail = computed(() => user.value?.email ?? null);

  return {
    isAuthenticated,
    user: readonly(user),
    refresh: fetch,
    signOut,
    userName,
    userEmail,
  };
};
