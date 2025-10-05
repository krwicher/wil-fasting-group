#!/usr/bin/env node

/**
 * Seed script for development/testing data
 *
 * Usage:
 *   node scripts/seed.js
 *
 * Environment variables required:
 *   SUPABASE_URL - Your Supabase project URL
 *   SUPABASE_SERVICE_ROLE_KEY - Service role key (for admin operations)
 *   ADMIN_EMAIL - Email of the user to promote to super_admin
 */

import { createClient } from "@supabase/supabase-js";
import { config } from "dotenv";

// Load environment variables from .env.local
config({ path: ".env.local" });

// Load environment variables
const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const ADMIN_EMAIL = process.env.ADMIN_EMAIL;

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error("❌ Error: Missing required environment variables");
  console.error("Required: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY");
  console.error("\nExample:");
  console.error("  SUPABASE_URL=http://127.0.0.1:54321 \\");
  console.error("  SUPABASE_SERVICE_ROLE_KEY=your-service-role-key \\");
  console.error("  ADMIN_EMAIL=admin@example.com \\");
  console.error("  node scripts/seed.js");
  process.exit(1);
}

// Create Supabase client with service role (bypasses RLS)
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});

async function promoteToSuperAdmin(email) {
  console.log(`\n🔐 Promoting ${email} to super_admin...`);

  const { data: user, error: userError } =
    await supabase.auth.admin.listUsers();
  if (userError) {
    console.error("❌ Error fetching users:", userError.message);
    return null;
  }

  const targetUser = user.users.find((u) => u.email === email);
  if (!targetUser) {
    console.error(`❌ User not found: ${email}`);
    console.log("\n💡 Tip: Sign up via the app first, then run this script");
    return null;
  }

  const { error: updateError } = await supabase.auth.admin.updateUserById(
    targetUser.id,
    {
      user_metadata: {
        ...targetUser.user_metadata,
        role: "super_admin",
      },
    }
  );

  if (updateError) {
    console.error("❌ Error promoting user:", updateError.message);
    return null;
  }

  console.log(`✅ Successfully promoted ${email} to super_admin`);
  return targetUser.id;
}

async function seedGroupFasts(creatorId) {
  console.log("\n📅 Creating sample group fasts...");

  const fasts = [
    {
      name: "48-Hour Weekend Challenge",
      description:
        "Join us for a 48-hour fast starting Friday evening. Let's support each other through the weekend!",
      creator_id: creatorId,
      start_time: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString(), // 3 days from now
      target_duration_hours: 48,
      status: "upcoming",
      is_public: true,
      max_participants: 50,
      allow_late_join: true,
      chat_enabled: true,
    },
    {
      name: "72-Hour Deep Fast",
      description:
        "A longer fast for experienced fasters. We start Monday morning and break Thursday morning.",
      creator_id: creatorId,
      start_time: new Date(Date.now() - 12 * 60 * 60 * 1000).toISOString(), // 12 hours ago
      target_duration_hours: 72,
      status: "active",
      is_public: true,
      max_participants: 30,
      allow_late_join: true,
      chat_enabled: true,
    },
    {
      name: "5-Day Extended Fast",
      description:
        "Our monthly extended fast. This is for committed fasters ready to go the distance.",
      creator_id: creatorId,
      start_time: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(), // 7 days from now
      target_duration_hours: 120,
      status: "upcoming",
      is_public: true,
      max_participants: 20,
      allow_late_join: false,
      chat_enabled: true,
    },
    {
      name: "24-Hour Beginner Fast",
      description: "Our first community fast - great success!",
      creator_id: creatorId,
      start_time: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(), // 5 days ago
      target_duration_hours: 24,
      status: "completed",
      is_public: true,
      max_participants: 100,
      allow_late_join: true,
      chat_enabled: true,
    },
  ];

  const { data, error } = await supabase
    .from("group_fasts")
    .insert(fasts)
    .select();

  if (error) {
    console.error("❌ Error creating group fasts:", error.message);
    return [];
  }

  console.log(`✅ Created ${data.length} sample group fasts`);
  return data;
}

async function joinActiveFast(userId, fastId, fastName) {
  console.log(`\n👤 Joining ${fastName}...`);

  const { error } = await supabase.from("fast_participants").insert({
    group_fast_id: fastId,
    user_id: userId,
    target_duration_hours: 72,
    started_at: new Date(Date.now() - 12 * 60 * 60 * 1000).toISOString(),
    status: "active",
  });

  if (error) {
    console.error("❌ Error joining fast:", error.message);
    return;
  }

  console.log("✅ Successfully joined fast");
}

async function seedPersonalFast(userId) {
  console.log("\n⭐ Creating sample personal fast...");

  const { error } = await supabase.from("personal_fasts").insert({
    user_id: userId,
    name: "My First Solo Fast",
    target_duration_hours: 24,
    started_at: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(), // 3 days ago
    ended_at: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(), // 2 days ago
    status: "completed",
  });

  if (error) {
    console.error("❌ Error creating personal fast:", error.message);
    return;
  }

  console.log("✅ Created sample personal fast");
}

async function main() {
  console.log("🌱 Starting seed script...\n");
  console.log(`📍 Supabase URL: ${SUPABASE_URL}`);

  try {
    // Step 1: Promote user to super_admin (if email provided)
    let adminUserId = null;
    if (ADMIN_EMAIL) {
      adminUserId = await promoteToSuperAdmin(ADMIN_EMAIL);
      if (!adminUserId) {
        console.log("\n⚠️  Skipping data seeding (no admin user)");
        return;
      }
    } else {
      console.log("\n⚠️  No ADMIN_EMAIL provided - skipping user promotion");
      console.log(
        "Set ADMIN_EMAIL environment variable to promote a user to super_admin"
      );
      return;
    }

    // Step 2: Seed group fasts
    const fasts = await seedGroupFasts(adminUserId);

    // Step 3: Join the active fast
    const activeFast = fasts.find((f) => f.status === "active");
    if (activeFast) {
      await joinActiveFast(adminUserId, activeFast.id, activeFast.name);
    }

    // Step 4: Seed personal fast
    await seedPersonalFast(adminUserId);

    console.log("\n🎉 Seed script completed successfully!");
    console.log("\n📝 Next steps:");
    console.log("  1. Sign in with your admin account");
    console.log("  2. Explore the sample group fasts");
    console.log("  3. Check your profile stats");
  } catch (error) {
    console.error("\n❌ Unexpected error:", error);
    process.exit(1);
  }
}

main();
