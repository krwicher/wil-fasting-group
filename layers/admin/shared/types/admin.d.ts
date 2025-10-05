import type { UserRole } from "~/layers/auth/app/composables/useAuth";

export interface AdminUser {
  id: string;
  email: string;
  display_name: string | null;
  role: UserRole;
  created_at: string;
  updated_at: string;
  last_sign_in_at: string | null;
}

export interface AdminStats {
  total_users: number;
  pending_users: number;
  approved_users: number;
  admin_users: number;
  total_fasts: number;
  active_fasts: number;
  total_participants: number;
}

export interface UserUpdateData {
  role?: UserRole;
  display_name?: string;
}
