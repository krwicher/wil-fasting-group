# TODO - What I've Learned Fasting Group App

## Current Status

**Phase**: Foundation Setup - Phase 1.1 Complete
**Last Updated**: October 5, 2025

---

## Phase 1: Foundation & Setup ⏳

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

### 1.2 Database Schema - Core Tables

- [ ] Create `user_roles` enum type (pending, approved, admin, super_admin)
- [ ] Create `fast_status` enum type (upcoming, active, completed, closed)
- [ ] Create `participation_status` enum type (active, completed, quit_early, extended)
- [ ] Create migration: `users` table extension
  - [ ] Add `role` column (references user_roles enum)
  - [ ] Add `approved_at` timestamp
  - [ ] Add `approved_by` uuid reference
  - [ ] Add RLS policies
- [ ] Create migration: `user_profiles` table
  - [ ] `id` (uuid, FK to auth.users)
  - [ ] `display_name` text
  - [ ] `avatar_url` text
  - [ ] `bio` text
  - [ ] `timezone` text
  - [ ] `created_at`, `updated_at` timestamps
  - [ ] Add RLS policies
- [ ] Create migration: `group_fasts` table
  - [ ] `id` (uuid, PK)
  - [ ] `name` text
  - [ ] `description` text
  - [ ] `creator_id` (uuid, FK to users)
  - [ ] `start_time` timestamptz
  - [ ] `target_duration_hours` integer
  - [ ] `status` (references fast_status enum)
  - [ ] `created_at`, `updated_at`, `closed_at` timestamps
  - [ ] Add RLS policies
- [ ] Create migration: `fast_participants` table
  - [ ] `id` (uuid, PK)
  - [ ] `user_id` (uuid, FK to users)
  - [ ] `group_fast_id` (uuid, FK to group_fasts)
  - [ ] `started_at` timestamptz (nullable)
  - [ ] `ended_at` timestamptz (nullable)
  - [ ] `target_duration_hours` integer
  - [ ] `status` (references participation_status enum)
  - [ ] `notes` text
  - [ ] `feeling` text
  - [ ] `created_at`, `updated_at` timestamps
  - [ ] Add unique constraint: one active participation per user
  - [ ] Add RLS policies
- [ ] Create migration: `personal_fasts` table
  - [ ] `id` (uuid, PK)
  - [ ] `user_id` (uuid, FK to users)
  - [ ] `name` text
  - [ ] `started_at` timestamptz
  - [ ] `ended_at` timestamptz (nullable)
  - [ ] `target_duration_hours` integer
  - [ ] `status` (references participation_status enum)
  - [ ] `notes` text
  - [ ] `feeling` text
  - [ ] `created_at`, `updated_at` timestamps
  - [ ] Add constraint: one active personal fast per user
  - [ ] Add RLS policies

### 1.3 Database Schema - Supporting Tables

- [ ] Create migration: `notifications` table
  - [ ] `id` (uuid, PK)
  - [ ] `user_id` (uuid, FK to users)
  - [ ] `type` text (e.g., 'fast_joined', 'milestone', 'chat_message')
  - [ ] `title` text
  - [ ] `message` text
  - [ ] `related_id` uuid (nullable, for linking to fasts/messages)
  - [ ] `read_at` timestamptz (nullable)
  - [ ] `created_at` timestamp
  - [ ] Add RLS policies
  - [ ] Add index on user_id and read_at
- [ ] Create migration: `chat_messages` table
  - [ ] `id` (uuid, PK)
  - [ ] `group_fast_id` (uuid, FK to group_fasts)
  - [ ] `user_id` (uuid, FK to users)
  - [ ] `message` text
  - [ ] `created_at`, `updated_at`, `deleted_at` timestamps
  - [ ] Add RLS policies
  - [ ] Add index on group_fast_id and created_at
- [ ] Create migration: `chat_bans` table
  - [ ] `id` (uuid, PK)
  - [ ] `user_id` (uuid, FK to users)
  - [ ] `group_fast_id` (uuid, FK to group_fasts)
  - [ ] `banned_by` (uuid, FK to users)
  - [ ] `reason` text
  - [ ] `created_at` timestamp
  - [ ] Add unique constraint: user_id + group_fast_id
  - [ ] Add RLS policies
- [ ] Create migration: `achievements` table
  - [ ] `id` (uuid, PK)
  - [ ] `name` text
  - [ ] `description` text
  - [ ] `icon` text
  - [ ] `requirement_type` text (e.g., 'total_hours', 'longest_fast', 'streak')
  - [ ] `requirement_value` integer
  - [ ] `created_at` timestamp
- [ ] Create migration: `user_achievements` table
  - [ ] `id` (uuid, PK)
  - [ ] `user_id` (uuid, FK to users)
  - [ ] `achievement_id` (uuid, FK to achievements)
  - [ ] `earned_at` timestamp
  - [ ] Add unique constraint: user_id + achievement_id
  - [ ] Add RLS policies

### 1.4 Database Functions & Triggers

- [ ] Create function: `calculate_hours_fasted(start_time, end_time)` → returns decimal
- [ ] Create function: `get_user_total_hours(user_id)` → returns decimal
- [ ] Create function: `get_user_longest_fast(user_id)` → returns decimal
- [ ] Create function: `get_user_current_streak(user_id)` → returns integer
- [ ] Create trigger: Auto-update `updated_at` on all tables
- [ ] Create trigger: Send notification when user joins a fast
- [ ] Create trigger: Check achievement criteria when fast completed
- [ ] Create function: `check_single_active_fast_constraint()` for participants

### 1.5 Seed Data

- [ ] Create seed script: Default achievements (24hr, 48hr, 72hr, 5-day, 7-day, 100hr total, 500hr total)
- [ ] Create seed script: First super admin user (for testing)
- [ ] Add sample group fasts for testing

---

## Phase 2: Authentication & User Management 🔐

### 2.1 Authentication Flow Enhancement

- [ ] Update `useAuth` composable to handle approval status
- [ ] Create `useUserRole` composable for role checking
- [ ] Add OAuth callback handling for Google
- [ ] Add OAuth callback handling for Apple
- [ ] Create post-signup profile completion flow
- [ ] Add timezone detection on signup
- [ ] Create "pending approval" screen for new users
- [ ] Add middleware to block unapproved users from main app

### 2.2 User Profile Pages

- [ ] Create `/profile` page
  - [ ] Display user stats (total hours, longest fast, current streak)
  - [ ] Show circular progress indicator for active fast
  - [ ] Display fast history table
  - [ ] Add "Edit Profile" button
- [ ] Create `/profile/edit` page
  - [ ] Upload/change avatar (Supabase Storage)
  - [ ] Edit display name
  - [ ] Edit bio
  - [ ] Change timezone
  - [ ] Add "Delete All My Data" button with confirmation
- [ ] Create `useUserProfile` composable
- [ ] Create `useUserStats` composable
- [ ] Add profile avatar component with fallback initials

### 2.3 Admin User Management

- [ ] Create `layers/admin` Nuxt layer
- [ ] Create `/admin/users` page
  - [ ] List pending users with approve/reject buttons
  - [ ] List all approved users with role management
  - [ ] Search and filter users
- [ ] Create `/admin/dashboard` page
  - [ ] Show key metrics (total users, active fasts, messages today)
  - [ ] Show recent activity feed
- [ ] Add admin-only middleware
- [ ] Create `useAdmin` composable
- [ ] Add notification badge for pending approvals in header

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
