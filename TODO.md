# TODO - What I've Learned Fasting Group App

## Current Status

**Phase**: Foundation Setup - Phase 1 Complete ✅
**Last Updated**: October 5, 2025

---

## Phase 1: Foundation & Setup ✅

### 1.1 Supabase Project Setup (Hybrid Approach) ✅

**Context**: We use a hybrid approach - local development for speed, remote staging for OAuth testing.

- [x] Create Supabase project for development (remote staging)
- [x] Install Supabase CLI locally
- [x] Initialize Supabase in project (`supabase init`)
- [x] Start Docker and run local Supabase stack (`supabase start`)
- [x] Link local project to remote staging project (`supabase link --project-ref ujgmthzlrfwjqvbkgcet`)
- [x] Set up environment variables in `.env` (local Supabase URLs)
- [ ] **MANUAL TASK**: Configure OAuth providers (Google, Apple) on **remote staging** via Supabase Dashboard
  - [ ] Set up Google OAuth in Google Cloud Console
  - [ ] Set up Apple OAuth in Apple Developer Console
  - [ ] Add OAuth credentials to Supabase Dashboard (remote staging)
  - [ ] Configure redirect URLs for staging domain
- [x] Set up Supabase Storage bucket for avatars (migration created: `20251005092725_create_avatars_bucket.sql`)
- [x] Create `.env.staging` with remote staging credentials for OAuth testing
- [x] Create `.env.local` for local development
- [x] Document environment switching process (local vs staging)

### 1.1b Development Workflow Documentation ✅

- [x] Create `DEVELOPMENT.md` documenting:
  - [x] When to use local vs remote staging
  - [x] How to start local Supabase (`supabase start`)
  - [x] How to switch between local and remote (`.env` vs `.env.staging`)
  - [x] Migration workflow: local → staging → production
  - [x] OAuth testing strategy on staging
  - [x] Common commands reference
  - [x] Better migration approach (psql instead of db reset)

#### ✅ Phase 1.1 Verification Checklist

Run these commands to verify Phase 1.1 is complete:

```bash
# 1. Check Supabase is linked
cat .supabase/config.toml | grep project_id
# Should show: project_id = "ujgmthzlrfwjqvbkgcet"

# 2. Check environment files exist
ls -la .env .env.local .env.staging
# Should show all three files

# 3. Check .env is using local by default
cat .env | grep SUPABASE_URL
# Should show: http://127.0.0.1:54321

# 4. Check documentation exists
ls -la DEVELOPMENT.md
# Should exist

# 5. Check storage bucket migration exists
ls -la supabase/migrations/20251005092725_create_avatars_bucket.sql
# Should exist

# 6. Start Supabase and verify it works
supabase start
supabase status
# Should show all services running

# 7. Apply storage migration (first time only)
psql postgresql://postgres:postgres@127.0.0.1:54322/postgres \
  -f supabase/migrations/20251005092725_create_avatars_bucket.sql
# Should complete without errors

# 8. Verify bucket in Studio
open http://127.0.0.1:54323
# Navigate to Storage → should see "avatars" bucket
```

**Expected Results:**
- ✅ Supabase linked to staging project
- ✅ Three environment files exist
- ✅ `.env` defaults to local development
- ✅ `DEVELOPMENT.md` exists with comprehensive guide
- ✅ Storage bucket migration created
- ✅ Supabase starts successfully
- ⚠️ OAuth configuration is pending (manual task via web consoles)

### 1.2 Database Schema - Core Tables ✅

- [x] Create `user_roles` enum type (pending, approved, admin, super_admin) - `20251005095004_create_enums.sql`
- [x] Create `fast_status` enum type (upcoming, active, completed, closed) - `20251005095004_create_enums.sql`
- [x] Create `participation_status` enum type (active, completed, quit_early, extended) - `20251005095004_create_enums.sql`
- [x] Create migration: `users` table extension - `20251005095018_extend_users_table.sql`
  - [x] Helper functions: `get_user_role()`, `is_user_approved()`, `is_user_admin()`
  - [x] Trigger: `handle_new_user()` sets default role and timezone
  - [x] Stores role in `raw_user_meta_data->>'role'`
- [x] Create migration: `user_profiles` table - `20251005095038_create_user_profiles_table.sql`
  - [x] `id` (uuid, FK to auth.users)
  - [x] `display_name`, `bio`, `avatar_url` text
  - [x] `timezone` text
  - [x] `notification_preferences` jsonb
  - [x] `profile_visibility` (public/community/private)
  - [x] Statistics: `total_fasts_completed`, `total_hours_fasted`, `longest_fast_hours`, `current_streak_days`
  - [x] `created_at`, `updated_at` timestamps
  - [x] Add RLS policies (view own, view public/community, admins view all)
  - [x] Trigger: Auto-create profile on user registration
- [x] Create migration: `group_fasts` table - `20251005095059_create_group_fasts_table.sql`
  - [x] `id` (uuid, PK)
  - [x] `name`, `description` text
  - [x] `creator_id` (uuid, FK to users)
  - [x] `start_time` timestamptz
  - [x] `target_duration_hours` integer
  - [x] `status` (references fast_status enum)
  - [x] Settings: `is_public`, `max_participants`, `allow_late_join`, `chat_enabled`
  - [x] Statistics: `participant_count`, `active_participant_count`
  - [x] `created_at`, `updated_at` timestamps
  - [x] Add RLS policies (view public, creators update own, admins manage all)
  - [x] Trigger: Auto-update status to 'active' when start_time passes
- [x] Create migration: `fast_participants` table - `20251005095122_create_fast_participants_table.sql`
  - [x] `id` (uuid, PK)
  - [x] `user_id` (uuid, FK to users)
  - [x] `group_fast_id` (uuid, FK to group_fasts)
  - [x] `started_at` timestamptz (nullable)
  - [x] `ended_at` timestamptz (nullable)
  - [x] `target_duration_hours` integer
  - [x] `status` (references participation_status enum)
  - [x] `notes`, `quit_reason` text
  - [x] `created_at`, `updated_at` timestamps
  - [x] Add unique constraint: `(group_fast_id, user_id)`
  - [x] Add constraint: one active group fast per user
  - [x] Add RLS policies (participants view same fast, users manage own)
  - [x] Trigger: Update `group_fasts` participant counts
  - [x] Trigger: Update user profile stats on completion
- [x] Create migration: `personal_fasts` table - `20251005095151_create_personal_fasts_table.sql`
  - [x] `id` (uuid, PK)
  - [x] `user_id` (uuid, FK to users)
  - [x] `name` text (optional)
  - [x] `started_at` timestamptz
  - [x] `ended_at` timestamptz (nullable)
  - [x] `target_duration_hours` integer
  - [x] `status` (references participation_status enum)
  - [x] `notes`, `quit_reason` text
  - [x] `created_at`, `updated_at` timestamps
  - [x] Add constraint: one active personal fast per user
  - [x] Add RLS policies (users view/manage own, admins view all)
  - [x] Trigger: Update user profile stats on completion
- [x] Create utility functions - `20251005095000_create_utility_functions.sql`
  - [x] `update_updated_at_column()` trigger function

### 1.3 Database Schema - Supporting Tables ✅

- [x] Create migration: `notifications` table - `20251005103034_create_notifications_table.sql`
  - [x] `id` (uuid, PK)
  - [x] `user_id` (uuid, FK to users)
  - [x] `type` text (user_joined_fast, fast_starting_soon, milestone_reached, new_chat_message, achievement_earned, admin_approval, admin_rejection, new_user_registration)
  - [x] `title` text
  - [x] `message` text
  - [x] `related_entity_type` text (group_fast, personal_fast, user, achievement)
  - [x] `related_entity_id` uuid (nullable)
  - [x] `is_read` boolean, `read_at` timestamptz (nullable)
  - [x] `created_at` timestamp
  - [x] Add RLS policies (users view own, admins view all)
  - [x] Add indexes on user_id, is_read, created_at, type
  - [x] Functions: `mark_notification_read()`, `mark_all_notifications_read()`
- [x] Create migration: `chat_messages` table - `20251005103151_create_chat_messages_table.sql`
  - [x] `id` (uuid, PK)
  - [x] `group_fast_id` (uuid, FK to group_fasts)
  - [x] `user_id` (uuid, FK to users)
  - [x] `message` text
  - [x] Moderation: `is_deleted`, `deleted_at`, `deleted_by`, `deletion_reason`
  - [x] Edit tracking: `is_edited`, `edited_at`
  - [x] `created_at` timestamp
  - [x] Add RLS policies (participants view, participants send if not banned, users edit own, admins/creators delete)
  - [x] Add indexes on group_fast_id, user_id, created_at, is_deleted
  - [x] Functions: `delete_chat_message()`, trigger for `edited_at`
- [x] Create migration: `chat_bans` table - `20251005103239_create_chat_bans_table.sql`
  - [x] `id` (uuid, PK)
  - [x] `user_id` (uuid, FK to users)
  - [x] `group_fast_id` (uuid, FK to group_fasts)
  - [x] `banned_by` (uuid, FK to users)
  - [x] `reason` text
  - [x] `expires_at` timestamptz (nullable for permanent bans)
  - [x] `created_at` timestamp
  - [x] Add unique constraint: (group_fast_id, user_id)
  - [x] Add RLS policies (participants view, admins/creators ban/unban)
  - [x] Add indexes on group_fast_id, user_id, expires_at
  - [x] Functions: `ban_user_from_chat()`, `unban_user_from_chat()`, `is_user_banned_from_chat()`
- [x] Create migration: `achievements` table - `20251005103429_create_achievements_table.sql`
  - [x] `id` (uuid, PK)
  - [x] `name`, `description`, `icon` text
  - [x] `category` (fasting_duration, participation, consistency, community, milestones)
  - [x] `requirement_type` (total_hours_fasted, total_fasts_completed, longest_fast_hours, consecutive_days_active, group_fasts_joined, group_fasts_created, chat_messages_sent, custom)
  - [x] `requirement_value` numeric
  - [x] `tier` (bronze, silver, gold, platinum, diamond)
  - [x] `display_order` integer
  - [x] `created_at`, `updated_at` timestamps
  - [x] Add RLS policies (all view, admins manage)
  - [x] Add indexes on category, tier, display_order
  - [x] Seed 17 default achievements
- [x] Create migration: `user_achievements` table - `20251005103630_create_user_achievements_table.sql`
  - [x] `id` (uuid, PK)
  - [x] `user_id` (uuid, FK to users)
  - [x] `achievement_id` (uuid, FK to achievements)
  - [x] `progress` numeric, `is_completed` boolean
  - [x] `earned_at`, `created_at`, `updated_at` timestamps
  - [x] Add unique constraint: (user_id, achievement_id)
  - [x] Add RLS policies (users view own, all view completed, admins view all)
  - [x] Add indexes on user_id, achievement_id, is_completed, earned_at
  - [x] Functions: `check_and_award_achievements()`, trigger on profile update

### 1.4 Database Functions & Views ✅

- [x] Create helper functions - `20251005103832_create_helper_functions.sql`
  - [x] `calculate_hours_fasted(started_at, ended_at)` → returns numeric
  - [x] `calculate_progress_percentage(started_at, target_hours, ended_at)` → returns numeric
  - [x] `get_user_active_fast(user_id)` → returns jsonb
  - [x] `get_unread_notification_count(user_id)` → returns integer
  - [x] `update_user_role(user_id, new_role)` → admin function
  - [x] `end_fast(fast_type, fast_id, status, quit_reason)` → end group/personal fast
  - [x] `leave_group_fast(participant_id)` → leave participation
  - [x] `close_group_fast(fast_id)` → admin/creator close fast
- [x] Create database views - `20251005103928_create_database_views.sql`
  - [x] `group_fast_leaderboard` - participants ranked by hours fasted per fast
  - [x] `global_leaderboard` - all users ranked by various metrics
  - [x] `active_fasts_summary` - upcoming/active fasts with creator info
  - [x] `user_fast_history` - combined personal and group fast history
  - [x] `pending_user_approvals` - admin view of pending users
  - [x] `recent_activity` - feed of recent completions and achievements

### 1.5 Seed Data ✅

- [x] Default achievements seeded in migration `20251005103429_create_achievements_table.sql`
  - [x] 17 achievements across 5 categories (fasting_duration, participation, consistency, community, milestones)
  - [x] Bronze, silver, gold, platinum, and diamond tiers
- [x] Create standalone seed script `scripts/seed.js`
  - [x] Promotes user to super_admin
  - [x] Creates 4 sample group fasts (upcoming, active, completed)
  - [x] Auto-joins admin to active fast
  - [x] Creates sample personal fast
  - [x] Can be run independently with environment variables
- [x] Create `scripts/README.md` with usage instructions

---

## Phase 2: Authentication & User Management 🔐

### 2.1 Authentication Flow Enhancement ✅

- [x] Update `useAuth` composable to handle approval status
- [x] Create `useUserRole` composable for role checking
- [x] Add OAuth callback handling for Google
- [x] Add OAuth callback handling for Apple
- [x] Create post-signup profile completion flow
- [x] Add timezone detection on signup
- [x] Create "pending approval" screen for new users
- [x] Add middleware to block unapproved users from main app

### 2.2 User Profile Pages ✅

- [x] Create `/profile` page
  - [x] Display user stats (total hours, longest fast, current streak)
  - [x] Show circular progress indicator for active fast
  - [x] Display fast history table
  - [x] Add "Edit Profile" button
- [x] Create `/profile/edit` page
  - [x] Upload/change avatar (Supabase Storage)
  - [x] Edit display name
  - [x] Edit bio
  - [x] Change timezone
  - [x] Add "Delete All My Data" button with confirmation
- [x] Create `useUserProfile` composable
- [x] Create `useUserStats` composable
- [x] Add profile avatar component with fallback initials

### 2.3 Admin User Management ✅

- [x] Create `layers/admin` Nuxt layer
- [x] Implement repository pattern for data access
  - [x] Create `UserRepository` for user data operations
  - [x] Create `StatsRepository` for statistics queries
  - [x] Create `AdminRepository` for admin operations
  - [x] Refactor composables to use repositories
- [x] Create `/admin/users` page
  - [x] List pending users with approve/reject buttons
  - [x] List all approved users with role management
  - [x] Filter users by role
  - [x] Change user roles (with super_admin restriction)
  - [x] Delete users
- [x] Create `/admin/dashboard` page
  - [x] Show user statistics (total, pending, approved, admins)
  - [x] Show fasting statistics (total fasts, active fasts, participants)
  - [x] Display admin capabilities
- [x] Add admin-only middleware
- [x] Create `useAdmin` composable
- [x] Add notification badge for pending approvals in header

---

## Phase 3: Core Fasting Features 🕐

### 3.1 Group Fasts - Create & List

- [ ] Create `layers/fasting` Nuxt layer
- [ ] Create `/fasts` page (group fasts listing)
  - [ ] Filter tabs: Upcoming, Active, Completed
  - [ ] Display fast cards with participant count
  - [ ] Show "Create Fast" button
  - [ ] Sort by start time
- [ ] Create `/fasts/create` page
  - [ ] Form: name, description, target duration, start time
  - [ ] Timezone display and conversion preview
  - [ ] Validation with Zod schema
  - [ ] Auto-join creator on creation
- [ ] Create `useGroupFasts` composable
- [ ] Create `GroupFastCard` component
- [ ] Add fast creation form validation

### 3.2 Group Fasts - Detail & Participation

- [ ] Create `/fasts/[id]` page
  - [ ] Show fast details (name, description, times, creator)
  - [ ] Display horizontal progress bars for all participants (sorted by hours)
  - [ ] Show "Join Fast" / "Leave Fast" / "Start Timer" / "End Fast" buttons
  - [ ] Display participant list with avatars
  - [ ] Show group chat section
- [ ] Create `useFastParticipation` composable
- [ ] Create `ParticipantProgressBar` component
- [ ] Create `FastControls` component (join/leave/start/end buttons)
- [ ] Add modal for ending fast (add notes and feeling)
- [ ] Implement timezone conversion for all displayed times
- [ ] Add real-time participant count (on page refresh)

### 3.3 Personal Fast Tracking

- [ ] Create `/fasts/personal` page
  - [ ] Show active personal fast with circular progress
  - [ ] Display "Start Personal Fast" button
  - [ ] List personal fast history
- [ ] Create `/fasts/personal/create` page
  - [ ] Form: name (optional), target duration
  - [ ] Start immediately option
- [ ] Create `usePersonalFasts` composable
- [ ] Create `CircularProgress` component
- [ ] Add personal fast controls (start/end/extend)

### 3.4 Fast History & Stats

- [ ] Create `FastHistory` component
  - [ ] Table view: date, name, duration, target, status
  - [ ] Filter by completed/quit/extended
  - [ ] Sort by date or duration
- [ ] Create `UserStatsCard` component
  - [ ] Total hours fasted
  - [ ] Longest single fast
  - [ ] Current streak
  - [ ] Total fasts completed
- [ ] Create `useFastHistory` composable
- [ ] Add pagination for long history lists

---

## Phase 4: Social Features 💬

### 4.1 Group Chat

- [ ] Create `ChatBox` component
  - [ ] Message list with user avatars
  - [ ] Message input textarea
  - [ ] Send button
  - [ ] Auto-scroll to bottom
  - [ ] Refresh button (manual reload)
- [ ] Create `ChatMessage` component
  - [ ] User avatar and name
  - [ ] Message content
  - [ ] Timestamp
  - [ ] Delete button (for admins and message author)
- [ ] Create `useGroupChat` composable
  - [ ] `sendMessage(fastId, message)`
  - [ ] `deleteMessage(messageId)`
  - [ ] `getMessages(fastId)`
  - [ ] `banUserFromChat(userId, fastId)`
- [ ] Add chat section to `/fasts/[id]` page
- [ ] Implement chat message deletion (soft delete)
- [ ] Add "archived" state indicator when fast completes
- [ ] Block banned users from sending messages

### 4.2 Leaderboards

- [ ] Create `/leaderboard` page
  - [ ] Tabs: Monthly, All-Time
  - [ ] Metrics dropdown: Total Hours, Longest Fast, Most Fasts, Current Streak
  - [ ] Top 100 users with ranks
  - [ ] Highlight current user
- [ ] Create `LeaderboardTable` component
- [ ] Create `useLeaderboard` composable
- [ ] Add database views for leaderboard queries (performance optimization)
- [ ] Add "View Leaderboard" link in header navigation

### 4.3 Achievements & Badges

- [ ] Create `/achievements` page
  - [ ] Grid of all achievements
  - [ ] Show locked/unlocked state
  - [ ] Display progress toward next achievement
- [ ] Create `AchievementBadge` component
  - [ ] Icon, name, description
  - [ ] Earned date (if unlocked)
  - [ ] Progress bar (if in progress)
- [ ] Create `useAchievements` composable
- [ ] Implement achievement checking logic (trigger on fast completion)
- [ ] Add achievement notification when earned
- [ ] Display badge count on profile page

### 4.4 Notifications System

- [ ] Create `NotificationBell` component in header
  - [ ] Badge with unread count
  - [ ] Dropdown list of recent notifications
  - [ ] Mark as read on click
  - [ ] "View All" link to notifications page
- [ ] Create `/notifications` page
  - [ ] List all notifications (read and unread)
  - [ ] Filter by type
  - [ ] Mark all as read button
- [ ] Create `useNotifications` composable
  - [ ] `getUnreadCount()`
  - [ ] `markAsRead(notificationId)`
  - [ ] `markAllAsRead()`
- [ ] Implement notification creation for all trigger events:
  - [ ] User joins your fast
  - [ ] Fast starting soon (1 hour before)
  - [ ] Milestone reached (24hr, 48hr, 72hr, etc.)
  - [ ] New chat message in your active fast
  - [ ] Achievement earned
  - [ ] Admin approval/rejection
  - [ ] New user registration (admin only)

---

## Phase 5: Admin Features & Moderation 🛡️

### 5.1 Fast Management

- [ ] Add admin controls to `/fasts/[id]` page
  - [ ] "Close Fast" button (ends for everyone)
  - [ ] "Delete Fast" button with confirmation
  - [ ] "Feature Fast" toggle
- [ ] Create `/admin/fasts` page
  - [ ] List all fasts with filters
  - [ ] Quick actions (close, delete, feature)
  - [ ] View flagged/reported fasts
- [ ] Create `useFastModeration` composable
- [ ] Add "featured" badge on fast cards
- [ ] Implement fast deletion (cascade to participants, chat)

### 5.2 Chat Moderation

- [ ] Add "Delete" button to messages (visible to admins)
- [ ] Add "Ban User from Chat" option in message context menu
- [ ] Create `/admin/moderation` page
  - [ ] List of banned users
  - [ ] Unban functionality
  - [ ] Recent deleted messages log
- [ ] Add notification when user is banned
- [ ] Display "banned from chat" indicator to user

### 5.3 User Moderation

- [ ] Add user search to `/admin/users`
- [ ] Add role change dropdown (admin can promote to admin, super admin only can promote to super admin)
- [ ] Add "Suspend User" functionality (block access without deletion)
- [ ] Create activity log for admin actions
- [ ] Add export user data functionality (GDPR)

---

## Phase 6: Polish & UX Improvements ✨

### 6.1 UI/UX Enhancements

- [ ] Extract brand colors from "What I've Learned" thumbnails
- [ ] Update Tailwind config with brand colors
- [ ] Create design system documentation
- [ ] Add loading states to all async operations
- [ ] Add skeleton loaders for fast lists and profiles
- [ ] Implement optimistic UI updates for chat and fast participation
- [ ] Add empty states for all lists (no fasts, no history, etc.)
- [ ] Add error boundaries and error messages
- [ ] Create 404 and 500 error pages

### 6.2 Responsive Design

- [ ] Test and fix mobile layouts for all pages
- [ ] Optimize progress bars for small screens
- [ ] Add mobile navigation menu
- [ ] Test on iOS Safari and Android Chrome
- [ ] Add touch-friendly buttons and controls
- [ ] Optimize images for mobile

### 6.3 Performance Optimization

- [ ] Add database indexes for frequently queried columns
- [ ] Implement pagination for fast lists and chat messages
- [ ] Add caching for leaderboard queries
- [ ] Optimize Supabase queries (reduce N+1 queries)
- [ ] Lazy load images and avatars
- [ ] Code splitting for admin routes

### 6.4 Accessibility

- [ ] Add ARIA labels to all interactive elements
- [ ] Ensure keyboard navigation works throughout app
- [ ] Add focus indicators
- [ ] Test with screen readers
- [ ] Ensure color contrast meets WCAG AA standards
- [ ] Add alt text to all images

---

## Phase 7: Testing & Quality Assurance 🧪

### 7.1 Automated Testing

- [ ] Set up Vitest for unit tests
- [ ] Write tests for composables (useAuth, useGroupFasts, etc.)
- [ ] Write tests for utility functions (time calculations, etc.)
- [ ] Set up Playwright for E2E tests
- [ ] Write E2E test: User signup and approval flow
- [ ] Write E2E test: Create and join group fast
- [ ] Write E2E test: Complete fast and check leaderboard
- [ ] Add CI/CD pipeline for running tests

### 7.2 Manual Testing

- [ ] Test OAuth login with Google
- [ ] Test OAuth login with Apple
- [ ] Test admin approval flow
- [ ] Test timezone conversions (multiple timezones)
- [ ] Test participation constraints (only one active fast)
- [ ] Test chat functionality and moderation
- [ ] Test achievement unlocking
- [ ] Test notifications for all trigger events
- [ ] Test GDPR data deletion
- [ ] Cross-browser testing (Chrome, Firefox, Safari, Edge)
- [ ] Mobile device testing (iOS and Android)

### 7.3 User Acceptance Testing

- [ ] Deploy to dev domain
- [ ] Invite Joseph to test
- [ ] Invite small group of community members
- [ ] Collect feedback and bug reports
- [ ] Create issues for all reported bugs
- [ ] Prioritize and fix critical bugs

---

## Phase 8: Deployment & Launch 🚀

### 8.1 Pre-Launch Checklist

- [ ] Set up production Supabase project
- [ ] Run all migrations on production database
- [ ] Set up production environment variables
- [ ] Configure OAuth for production domain
- [ ] Set up Supabase Storage CORS for production
- [ ] Test production build locally
- [ ] Create backup strategy for database
- [ ] Set up monitoring and error tracking (e.g., Sentry)

### 8.2 Deployment

- [ ] Choose hosting platform (Vercel, Netlify, or custom)
- [ ] Configure build settings
- [ ] Deploy to staging environment
- [ ] Run smoke tests on staging
- [ ] Deploy to production
- [ ] Verify OAuth works on production domain
- [ ] Test critical user flows on production

### 8.3 Post-Launch

- [ ] Create first super admin account
- [ ] Seed initial achievements
- [ ] Create welcome announcement
- [ ] Monitor error logs for first 48 hours
- [ ] Collect user feedback
- [ ] Create backlog for post-v1 features

---

## Future Enhancements (Post-v1) 🔮

### Real-Time Features

- [ ] Add WebSocket support for real-time progress updates
- [ ] Implement real-time chat messages
- [ ] Add live notification updates

### Advanced Fast Types

- [ ] Implement recurring weekly fasts
- [ ] Add rolling start fasts (no fixed time)
- [ ] Add fast templates (16:8, OMAD, etc. for shorter tracking)

### Analytics & Reporting

- [ ] Create personal analytics dashboard
- [ ] Add charts for fasting trends over time
- [ ] Create community analytics page (admin only)
- [ ] Export personal data to CSV

### Integrations

- [ ] Apple Health integration
- [ ] Google Fit integration
- [ ] Calendar integration (add fasts to calendar)
- [ ] Zapier/webhook support

### Community Enhancements

- [ ] User-to-user direct messaging
- [ ] Friend/follow system
- [ ] Private groups within community
- [ ] Reporting system for inappropriate content
- [ ] Community guidelines page

### Content & Education

- [ ] Add fasting tips and articles
- [ ] Create FAQ section
- [ ] Add onboarding tutorial
- [ ] Weekly newsletter with community highlights

---

## Notes & Decisions

### Technical Decisions

- **Why Nuxt Layers?** Modular architecture allows independent development and testing of features
- **Why Supabase?** Fast development, built-in auth, real-time capabilities, generous free tier
- **Why no real-time in v1?** Simpler implementation, lower costs, easier to debug
- **Why fixed-start fasts first?** Clearer group coordination, easier progress comparison

### Open Questions

- [ ] Should we add a "Cancel Fast" feature (vs just ending early)?
- [ ] Should leaderboard show all users or just top 100?
- [ ] Should we add push notifications (browser/mobile)?
- [ ] Should we allow users to edit their notes after ending a fast?

### Risks & Mitigation

- **Risk**: Low user engagement
  - **Mitigation**: Add gamification early (achievements, leaderboards)
- **Risk**: Timezone confusion
  - **Mitigation**: Always show local time with timezone label
- **Risk**: Spam in group chats
  - **Mitigation**: Strong moderation tools, ban functionality
- **Risk**: Database performance with many users
  - **Mitigation**: Proper indexing, caching, pagination from the start

---

**Last Review**: October 4, 2025
**Next Review**: After Phase 1 completion
