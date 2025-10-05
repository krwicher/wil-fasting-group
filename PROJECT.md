# What I've Learned - Fasting Group App

## Project Overview

A closed community web application for intermittent fasting enthusiasts from the "What I've Learned" YouTube channel. The app enables users to create and participate in multi-day group fasts, track their progress, compete on leaderboards, and communicate through group chats.

## Core Concept

This is a **community-focused fasting tracker** that emphasizes social accountability and group participation for multi-day fasting periods (e.g., 48-hour, 72-hour, 5-day fasts). Unlike typical interval fasting trackers (16:8, OMAD), this focuses on extended fasting periods done together as a community.

## Key Features (v1 Scope)

### Authentication & User Management
- **OAuth Login**: Google and Apple sign-in via Supabase Auth
- **Admin Approval**: New registrations require admin approval before access
- **User Profiles**: Name, email, avatar, timezone, fasting statistics
- **Two Admin Levels**: Super Admin and Admin (moderator)

### Group Fasts
- **Create Group Fasts**: Any approved user can create a fast
- **Fast Structure**:
  - Name, description, target duration (in hours)
  - Fixed start time (in creator's timezone)
  - Public visibility within the community
- **Flexible Participation**:
  - Users can join anytime (before or after start)
  - Can start their personal timer at any point
  - Can end early (marked as "quit early") or extend beyond target
  - Fast closes when last participant ends or admin closes it
- **Participation Limits**: One active group fast + one active personal fast per user simultaneously

### Fast Tracking
- **Personal & Group Tracking**: Users track both group and personal fasts
- **Data Points**: Start time, end time, target duration, actual duration, notes, how they felt
- **Fast History**: Complete history of all completed fasts
- **Progress Visualization**:
  - **Group Fast Page**: Horizontal progress bars comparing all participants
  - **Personal Fast Page**: Circular progress indicator
  - Rankings sorted by absolute hours fasted

### Group Chat
- **One Chat Per Group Fast**: Dedicated chat for each group fast
- **Archived After Completion**: Chats lock/archive when fast ends
- **Moderation**: Admins can delete messages and ban users from chat
- **Refresh-Based**: No real-time updates initially (page refresh required)

### Leaderboards & Gamification
- **Multiple Timeframes**: Monthly and all-time leaderboards
- **Metrics**:
  - Total hours fasted
  - Longest single fast
  - Most fasts completed
  - Current streak
- **Achievements/Badges**: Milestone-based rewards (24hr, 48hr, etc.)
- **Competition Elements**: Rankings visible to all community members

### Notifications (In-App Only)
- Someone joins your group fast
- Group fast starting soon
- Fast target completed
- New messages in group chat
- Admin announcements
- Milestone achievements (24hrs, 48hrs, etc.)
- New user registration requests (for admins)

### Admin Panel
- **User Management**: Approve/reject new registrations, manage user roles
- **Fast Management**: Create "featured" fasts, close fasts early, delete inappropriate fasts
- **Moderation**: Delete messages, ban users from chats
- **Notifications**: In-app alerts for new registrations and flagged content

### Profile Page
- Total fasting statistics (hours, longest fast, current streak)
- Complete history of all fasts (personal and group)
- Edit profile (avatar, bio, timezone)
- Current active fast(s) status
- GDPR compliance: Ability to delete all user data

## Technical Stack

### Frontend
- **Framework**: Nuxt 4 (Vue 3)
- **UI Library**: Nuxt UI (Tailwind CSS 4)
- **State Management**: Nuxt composables + Vue composables
- **Images**: @nuxt/image for optimized images
- **Validation**: Zod for schema validation
- **Icons**: Lucide icons via @iconify-json/lucide

### Backend & Infrastructure
- **BaaS**: Supabase (PostgreSQL, Auth, Storage, Real-time)
- **Authentication**: Supabase Auth with Google & Apple OAuth
- **Database**: PostgreSQL via Supabase
- **Migrations**: Supabase CLI for database migrations
- **File Storage**: Supabase Storage (user avatars)

### Project Architecture
- **Nuxt Layers Pattern**: Modular layer-based architecture
  - `base` layer: UI components, layouts, global styles
  - `auth` layer: Authentication composables and pages
  - Additional layers to be created: `fasting`, `admin`, `chat`

### Existing Project Structure
```
├── app/                    # Main app entry
│   └── app.vue
├── layers/                 # Nuxt layers
│   ├── auth/              # Authentication layer
│   │   ├── app/
│   │   │   ├── composables/
│   │   │   │   └── useAuth.ts
│   │   │   └── pages/
│   │   │       ├── sign-in.vue
│   │   │       └── sign-up.vue
│   │   ├── shared/
│   │   │   └── types/types.d.ts
│   │   └── nuxt.config.ts
│   └── base/              # Base UI layer
│       ├── app/
│       │   ├── assets/css/main.css
│       │   ├── components/
│       │   │   ├── AppHeader.vue
│       │   │   └── AppFooter.vue
│       │   └── layouts/
│       │       ├── default.vue
│       │       └── sign-up.vue
│       └── nuxt.config.ts
├── public/                # Static assets
│   ├── images/
│   └── favicon.ico
├── nuxt.config.ts        # Main Nuxt config
├── package.json
└── tsconfig.json
```

## Design System

### Brand Colors
Colors derived from "What I've Learned" YouTube channel thumbnails:
- Primary: (To be extracted from channel branding)
- Secondary: (To be extracted from channel branding)
- Accent: (To be extracted from channel branding)

### Design Approach
- **Platform Priority**: Equal focus on desktop and mobile
- **UI Inspiration**: Zero fasting app for progress indicators
- **Progress Bars**:
  - Horizontal bars for group comparison (list view)
  - Circular indicators for personal tracking
- **Modern, Sleek Design**: Clean, minimalist interface focused on usability

## Database Schema (High-Level)

### Core Tables
- `users`: Extended Supabase auth.users with profile data
- `user_profiles`: Avatar, bio, timezone, stats cache
- `user_roles`: Admin levels and permissions
- `group_fasts`: Fast metadata (name, description, start_time, target_duration, status)
- `fast_participants`: Join table linking users to group_fasts with personal times
- `personal_fasts`: Individual fasts not tied to groups
- `fast_logs`: Historical record of all fasts (completed/quit)
- `chat_messages`: Messages tied to group_fasts
- `chat_bans`: Moderation table for banned users
- `notifications`: In-app notification queue
- `achievements`: Badge/achievement definitions
- `user_achievements`: Join table for earned achievements

### Key Relationships
- One user can have ONE active group fast participation
- One user can have ONE active personal fast
- One group fast has many participants
- One group fast has one chat (with many messages)
- Users have many historical fasts (completed/quit)

## User Flows

### New User Registration
1. User visits site → redirected to sign-in
2. User clicks "Sign up" → OAuth (Google/Apple)
3. Complete profile (name, avatar, timezone)
4. Account enters "pending approval" state
5. Admin receives in-app notification
6. Admin approves → user gains access
7. User sees welcome message and can browse/join fasts

### Creating a Group Fast
1. Approved user navigates to "Group Fasts" page
2. Clicks "Create Fast" button
3. Fills form: name, description, target duration, start time
4. Submits → fast appears on group fasts list
5. Creator is automatically joined (optional: can start immediately)

### Joining a Group Fast
1. User browses active/upcoming group fasts
2. Clicks on a fast to see details (description, participants, leaderboard)
3. Clicks "Join Fast" button
4. User's personal timer can be started immediately or later
5. User appears on participant list and leaderboard

### During a Fast
1. User sees their progress (circular indicator on profile, horizontal on group page)
2. Can view group chat (refresh to see new messages)
3. Receives in-app notifications for milestones
4. Can end fast early, on-time, or extend
5. Can add notes about how they're feeling

### After a Fast
1. User marks fast as complete
2. Fast data saved to history
3. Stats updated (total hours, streaks, etc.)
4. Achievements/badges unlocked if thresholds met
5. Group chat archived when last person finishes (or admin closes)
6. Fast moves to "completed" section

## Security & Permissions

### Row-Level Security (RLS)
- Users can only read/write their own profile data
- Users can read all group fasts and public profiles
- Only admins can approve users and delete content
- Users can only modify their own fast participation records
- Chat messages visible to all fast participants
- Admins can see and modify all data

### Data Privacy
- User emails only visible to admins and the user themselves
- Progress and fasting data visible to all community members (no privacy settings v1)
- GDPR compliance: Users can request full data deletion
- Admin actions logged for accountability

## Future Enhancements (Post-v1)

### Real-Time Features
- Live progress bar updates without refresh
- Real-time chat messages
- Live notifications

### Advanced Fast Types
- Recurring fasts (weekly challenges)
- Different fast protocols (rolling start, water-only, etc.)

### Integrations
- Apple Health / Google Fit
- Export data to CSV/JSON
- API for third-party apps

### Community Features
- User-to-user messaging
- Friend/follow system
- Custom user groups
- Community guidelines and reporting

### Analytics
- Admin dashboard with community trends
- Personal detailed stats and charts
- Export personal fasting history

### Educational Content
- Fasting tips and science articles
- FAQ section
- Onboarding tutorials

## Development Approach

### Hybrid Development Workflow

This project uses a **hybrid local + remote development approach** for optimal developer experience:

#### Local Development (Primary)
- **What**: Database schema, migrations, business logic, UI components, composables
- **Tool**: Supabase CLI + Docker
- **Benefits**:
  - Instant feedback loop
  - Free (no quota usage)
  - Offline work capability
  - Version-controlled migrations
- **Commands**:
  ```bash
  supabase start          # Start local Supabase stack
  pnpm dev               # Run Nuxt with local DB
  supabase migration new  # Create migrations
  supabase db reset      # Apply migrations locally
  ```

#### Remote Staging (OAuth & Integration Testing)
- **What**: OAuth flows (Google/Apple login), Storage bucket, full integration testing
- **Tool**: Hosted Supabase project
- **Why**: Social auth providers require public callback URLs (can't use localhost easily)
- **Commands**:
  ```bash
  supabase link --project-ref <staging-id>
  supabase db push       # Push local migrations to staging
  # Use .env.staging for OAuth testing
  pnpm dev               # Test with remote staging
  ```

#### Migration Strategy
1. **Develop locally**: Create migrations, test schema changes
2. **Push to staging**: `supabase db push` to sync local → remote
3. **Test on staging**: Verify OAuth, integrations, full user flows
4. **Deploy to production**: Same migrations, battle-tested

#### Environment Management
- `.env` - Local Supabase (default for development)
- `.env.staging` - Remote staging (for OAuth testing)
- `.env.production` - Production (deployment only)

### Development Phases

### Phase 1: Foundation (Current)
- Set up Supabase project and database schema
- Implement OAuth with admin approval flow
- Create basic user profile system
- Build group fast creation and listing

### Phase 2: Core Fasting Features
- Implement fast participation and tracking
- Build progress visualization (bars and circles)
- Create fast history and personal tracking
- Add timezone support

### Phase 3: Social Features
- Implement group chat per fast
- Build leaderboard system
- Create notification system
- Add achievements/badges

### Phase 4: Admin & Polish
- Build admin panel
- Implement moderation tools
- Add user management features
- Polish UI/UX and fix bugs

### Phase 5: Testing & Launch
- User acceptance testing with community
- Performance optimization
- Deploy to production domain
- Onboard initial users

## Environment Variables

Required environment variables:
```bash
SUPABASE_URL=your_supabase_project_url
SUPABASE_KEY=your_supabase_anon_key
NUXT_SESSION_PASSWORD=random_32_char_string
```

## Development Commands

### Local Development (Default)
```bash
# Install dependencies
pnpm install

# Start local Supabase stack (requires Docker)
supabase start

# Run Nuxt development server (connects to local Supabase)
pnpm dev

# Stop local Supabase stack
supabase stop

# Build for production
pnpm build

# Preview production build
pnpm preview
```

### Database Migrations (Local First)
```bash
# Create a new migration
supabase migration new create_users_table

# Apply migrations locally (resets DB and applies all migrations)
supabase db reset

# Check migration status
supabase db diff

# Generate TypeScript types from local DB
supabase gen types typescript --local > types/database.ts
```

### Remote Staging (OAuth Testing)
```bash
# Link to remote staging project (one-time setup)
supabase link --project-ref <your-staging-project-ref>

# Push local migrations to remote staging
supabase db push

# Pull schema changes from remote (if needed)
supabase db pull

# Generate TypeScript types from remote
supabase gen types typescript --linked > types/database.ts

# Run Nuxt with staging environment
cp .env.staging .env
pnpm dev
```

### Switching Environments
```bash
# Use local Supabase (default)
cp .env.local .env  # or just use default .env
supabase start
pnpm dev

# Use remote staging (for OAuth testing)
cp .env.staging .env
pnpm dev

# Back to local
cp .env.local .env
pnpm dev
```

### Useful Supabase CLI Commands
```bash
# View local Supabase dashboard
supabase status  # Shows URLs and credentials

# Check local Supabase logs
supabase logs

# Restart local services
supabase stop && supabase start

# Unlink from remote
supabase unlink
```

## Deployment Strategy

1. **Development**: Local testing with Supabase staging project
2. **Staging**: Deploy to dev domain for Joseph and community testing
3. **Production**: Move to official What I've Learned domain after approval

## Success Metrics

- User engagement: Daily active users, fasts joined per user
- Completion rates: % of users who finish their target duration
- Social engagement: Messages sent, leaderboard views
- Retention: Weekly/monthly returning users
- Community growth: New approved users per week

---

**Project Start Date**: October 2025
**Target v1 Launch**: TBD
**Project Owner**: What I've Learned (Joseph)
**Lead Developer**: Krzysztof
