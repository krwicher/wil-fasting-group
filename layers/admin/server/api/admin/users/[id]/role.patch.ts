import { createAdminClient, verifyAdminAuth } from "../../../../utils/supabaseAdmin";

/**
 * PATCH /api/admin/users/:id/role
 * Update a user's role in auth.users metadata
 * Requires admin authentication
 */
export default defineEventHandler(async (event) => {
  // Verify admin authorization
  const { user: adminUser, role: adminRole } = await verifyAdminAuth(event);

  // Get user ID from route params
  const userId = getRouterParam(event, "id");
  if (!userId) {
    throw createError({
      statusCode: 400,
      message: "User ID is required",
    });
  }

  // Get new role from request body
  const body = await readBody(event);
  const { role: newRole } = body;

  if (!newRole) {
    throw createError({
      statusCode: 400,
      message: "Role is required",
    });
  }

  // Validate role
  const validRoles = ["pending", "approved", "admin", "super_admin"];
  if (!validRoles.includes(newRole)) {
    throw createError({
      statusCode: 400,
      message: `Invalid role. Must be one of: ${validRoles.join(", ")}`,
    });
  }

  // Only super_admins can promote to admin or super_admin
  if (["admin", "super_admin"].includes(newRole) && adminRole !== "super_admin") {
    throw createError({
      statusCode: 403,
      message: "Only Super Admins can promote users to Admin or Super Admin roles",
    });
  }

  try {
    // Create admin client with service role key
    const adminClient = createAdminClient();

    // Update user role in auth.users metadata
    const { data, error } = await adminClient.auth.admin.updateUserById(userId, {
      user_metadata: { role: newRole },
    });

    if (error) {
      throw error;
    }

    return {
      success: true,
      data: {
        id: data.user.id,
        email: data.user.email,
        role: newRole,
      },
    };
  } catch (error: any) {
    console.error("Error updating user role:", error);
    throw createError({
      statusCode: 500,
      message: `Failed to update user role: ${error.message}`,
    });
  }
});
