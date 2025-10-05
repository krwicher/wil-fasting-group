import { createClient } from "@supabase/supabase-js";
import type { SupabaseClient } from "@supabase/supabase-js";

/**
 * Create a Supabase client with service role key for admin operations
 * This client bypasses RLS policies and should ONLY be used server-side
 *
 * SECURITY: Never expose this client or service role key to the client
 */
export const createAdminClient = (): SupabaseClient => {
  const config = useRuntimeConfig();

  const supabaseUrl = config.public.supabase?.url;
  const serviceRoleKey = config.supabaseServiceRoleKey;

  if (!supabaseUrl || !serviceRoleKey) {
    throw new Error(
      "Missing Supabase configuration. Ensure SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are set."
    );
  }

  return createClient(supabaseUrl, serviceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });
};

/**
 * Verify the requesting user is an admin
 * Returns the user if authorized, throws error otherwise
 */
export const verifyAdminAuth = async (event: any) => {
  const supabase = await serverSupabaseClient(event);

  // Get the authenticated user
  const {
    data: { user },
    error: authError,
  } = await supabase.auth.getUser();

  if (authError || !user) {
    throw createError({
      statusCode: 401,
      message: "Unauthorized - Please sign in",
    });
  }

  // Check if user has admin role
  const role = user.user_metadata?.role;
  if (!["admin", "super_admin"].includes(role)) {
    throw createError({
      statusCode: 403,
      message: "Forbidden - Admin access required",
    });
  }

  return { user, role };
};
