import { createAdminClient, verifyAdminAuth } from "../../../utils/supabaseAdmin";

/**
 * DELETE /api/admin/users/:id
 * Delete a user account (reject user)
 * Requires admin authentication
 */
export default defineEventHandler(async (event) => {
  // Verify admin authorization
  await verifyAdminAuth(event);

  // Get user ID from route params
  const userId = getRouterParam(event, "id");
  if (!userId) {
    throw createError({
      statusCode: 400,
      message: "User ID is required",
    });
  }

  try {
    // Create admin client with service role key
    const adminClient = createAdminClient();

    // Delete user from auth (this will cascade to user_profiles due to foreign key)
    const { error } = await adminClient.auth.admin.deleteUser(userId);

    if (error) {
      throw error;
    }

    return {
      success: true,
      message: "User deleted successfully",
    };
  } catch (error: any) {
    console.error("Error deleting user:", error);
    throw createError({
      statusCode: 500,
      message: `Failed to delete user: ${error.message}`,
    });
  }
});
