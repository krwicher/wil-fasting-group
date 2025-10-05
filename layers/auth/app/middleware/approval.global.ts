/**
 * Global middleware to enforce user approval
 * Redirects unapproved (pending) users to the pending approval page
 */
export default defineNuxtRouteMiddleware((to) => {
  const user = useSupabaseUser();

  // Skip middleware for auth-related pages and public routes
  const publicRoutes = [
    "/sign-in",
    "/sign-up",
    "/auth/callback",
    "/auth/complete-profile",
    "/auth/pending",
  ];

  if (publicRoutes.includes(to.path)) {
    return;
  }

  // If user is authenticated, check their approval status
  if (user.value) {
    const role = user.value.user_metadata?.role as string;

    // Check if user needs to complete their profile
    if (!user.value.user_metadata?.display_name) {
      return navigateTo("/auth/complete-profile");
    }

    // Redirect pending users to the pending page
    if (role === "pending") {
      return navigateTo("/auth/pending");
    }

    // Allow approved, admin, and super_admin users to proceed
    const approvedRoles = ["approved", "admin", "super_admin"];
    if (!approvedRoles.includes(role)) {
      // If role is not recognized, treat as pending
      return navigateTo("/auth/pending");
    }
  }

  // User is either not authenticated (will be handled by Supabase auth)
  // or is approved and can proceed
});
