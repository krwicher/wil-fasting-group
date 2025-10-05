import type { SupabaseClient } from "@supabase/supabase-js";
import type { UserProfile, UpdateProfileData } from "~/layers/base/shared/types/profile";

export class UserRepository {
  constructor(private supabase: SupabaseClient) {}

  /**
   * Fetch user profile by ID
   */
  async getProfile(userId: string): Promise<UserProfile | null> {
    const { data, error } = await this.supabase
      .from("user_profiles")
      .select("*")
      .eq("id", userId)
      .single();

    if (error) {
      if (error.code === "PGRST116") {
        // Profile doesn't exist yet
        return null;
      }
      throw new Error(`Failed to fetch profile: ${error.message}`);
    }

    return data;
  }

  /**
   * Update user profile
   */
  async updateProfile(userId: string, updates: UpdateProfileData): Promise<UserProfile> {
    const { data, error } = await this.supabase
      .from("user_profiles")
      .update({
        ...updates,
        updated_at: new Date().toISOString(),
      })
      .eq("id", userId)
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to update profile: ${error.message}`);
    }

    return data;
  }

  /**
   * Delete user profile and all associated data
   */
  async deleteProfile(userId: string): Promise<void> {
    const { error } = await this.supabase
      .from("user_profiles")
      .delete()
      .eq("id", userId);

    if (error) {
      throw new Error(`Failed to delete profile: ${error.message}`);
    }
  }

  /**
   * Upload avatar to storage and update profile
   */
  async uploadAvatar(userId: string, file: File): Promise<string> {
    // Generate unique filename
    const fileExt = file.name.split(".").pop();
    const fileName = `${userId}_${Date.now()}.${fileExt}`;
    const filePath = `${userId}/${fileName}`;

    // Upload file
    const { error: uploadError } = await this.supabase.storage
      .from("avatars")
      .upload(filePath, file, { upsert: true });

    if (uploadError) {
      throw new Error(`Failed to upload avatar: ${uploadError.message}`);
    }

    // Get public URL
    const { data } = this.supabase.storage
      .from("avatars")
      .getPublicUrl(filePath);

    // Update profile with new avatar URL
    await this.updateProfile(userId, { avatar_url: data.publicUrl });

    return data.publicUrl;
  }

  /**
   * Delete avatar from storage
   */
  async deleteAvatar(userId: string, avatarUrl: string): Promise<void> {
    // Extract file path from URL
    const urlParts = avatarUrl.split("/avatars/");
    if (urlParts.length < 2) {
      throw new Error("Invalid avatar URL");
    }
    const filePath = urlParts[1];

    const { error } = await this.supabase.storage
      .from("avatars")
      .remove([filePath]);

    if (error) {
      throw new Error(`Failed to delete avatar: ${error.message}`);
    }
  }

  /**
   * Get user initials from profile
   */
  getUserInitials(profile: UserProfile | null): string {
    if (!profile) return "?";

    const name = profile.display_name;
    if (!name) return "?";

    const parts = name.trim().split(/\s+/);
    if (parts.length === 1) {
      return parts[0].charAt(0).toUpperCase();
    }

    return (parts[0].charAt(0) + parts[parts.length - 1].charAt(0)).toUpperCase();
  }
}
