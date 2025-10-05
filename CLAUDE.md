# CLAUDE.md - Development Guidelines

**Purpose**: This document provides context and guidelines for AI assistants (Claude, Cursor, etc.) working on this project.

---

## Project Context

This is the **What I've Learned Fasting Group App** - a closed community application for tracking multi-day group fasts. Users from the "What I've Learned" YouTube channel community can create and join extended fasting periods (48hr, 72hr, 5-day, etc.), track their progress, compete on leaderboards, and chat with other participants.

Key characteristics:
- **Community-first**: Social accountability is central to the design
- **Multi-day fasts**: Not for interval fasting (16:8), but extended fasting periods
- **Admin-gated**: All users require approval from admins before accessing the app
- **Group-focused**: Emphasis on shared experiences rather than solo tracking

See `PROJECT.md` for comprehensive project overview and `TODO.md` for implementation roadmap.

---

## Tech Stack

### Core Technologies
- **Nuxt 4** (Vue 3) - Full-stack framework
- **Supabase** - Backend-as-a-Service (Auth, PostgreSQL, Storage)
- **Tailwind CSS 4** - Styling via @nuxt/ui
- **TypeScript** - Type safety throughout
- **pnpm** - Package manager

### Architecture Pattern
This project uses **Nuxt Layers** for modular architecture:
- `layers/base/` - UI components, layouts, global styles
- `layers/auth/` - Authentication logic and pages
- `layers/fasting/` - (to be created) Fast tracking features
- `layers/admin/` - (to be created) Admin panel
- `layers/chat/` - (to be created) Group chat features (optional separate layer)

Each layer is a self-contained Nuxt application with its own `nuxt.config.ts`.

---

## Code Conventions

### File Structure
```
layers/[layer-name]/
├── app/
│   ├── components/     # Vue components
│   ├── composables/    # Vue composables (useX functions)
│   ├── layouts/        # Nuxt layouts
│   ├── pages/          # Nuxt pages (file-based routing)
│   ├── middleware/     # Route middleware
│   ├── assets/         # CSS, images
│   └── utils/          # Utility functions
├── shared/
│   └── types/          # TypeScript types shared across layers
├── server/             # Server-only code (API routes, if needed)
└── nuxt.config.ts      # Layer-specific Nuxt config
```

### Naming Conventions
- **Components**: PascalCase (`GroupFastCard.vue`, `CircularProgress.vue`)
- **Composables**: camelCase with `use` prefix (`useGroupFasts.ts`, `useAuth.ts`)
- **Pages**: kebab-case (`sign-in.vue`, `fasts/[id].vue`)
- **Database tables**: snake_case (`group_fasts`, `fast_participants`)
- **TypeScript types**: PascalCase (`GroupFast`, `FastParticipant`)

### Component Structure
Use Composition API with `<script setup>`:
```vue
<script setup lang="ts">
// Props
const props = defineProps<{
  fastId: string
}>()

// Composables
const { user } = useAuth()

// State
const loading = ref(false)

// Computed
const isJoined = computed(() => {
  // ...
})

// Methods
async function joinFast() {
  // ...
}
</script>

<template>
  <!-- Template here -->
</template>
```

### Composables Pattern
Composables should:
- Return reactive values and methods
- Use `ref` for primitive values, `reactive` for objects (or `ref` for consistency)
- Export a clear interface

Example:
```ts
export const useGroupFasts = () => {
  const supabase = useSupabaseClient()
  const fasts = ref<GroupFast[]>([])
  const loading = ref(false)

  async function fetchFasts(status?: FastStatus) {
    loading.value = true
    try {
      const { data, error } = await supabase
        .from('group_fasts')
        .select('*')
        .eq('status', status ?? 'active')

      if (error) throw error
      fasts.value = data
    } catch (error) {
      console.error('Error fetching fasts:', error)
    } finally {
      loading.value = false
    }
  }

  return {
    fasts: readonly(fasts),
    loading: readonly(loading),
    fetchFasts,
  }
}
```

### TypeScript Guidelines
- **Always use TypeScript** for `.ts` and `.vue` files
- Define types in `shared/types/` for cross-layer sharing
- Use Zod for runtime validation (forms, API responses)
- Leverage Supabase generated types

Example type definition:
```ts
// layers/fasting/shared/types/fast.d.ts
export type FastStatus = 'upcoming' | 'active' | 'completed' | 'closed'

export interface GroupFast {
  id: string
  name: string
  description: string
  creator_id: string
  start_time: string // ISO timestamp
  target_duration_hours: number
  status: FastStatus
  created_at: string
  updated_at: string
}
```

---

## Database Guidelines

### Supabase CLI Workflow
Always use migrations for schema changes:

```bash
# Create a new migration
supabase migration new create_group_fasts_table

# Edit the generated file in supabase/migrations/
# Then apply it locally
supabase db reset

# Push to remote (production)
supabase db push
```

### Migrations Best Practices
- **One migration per logical change** (e.g., one table, one set of related changes)
- **Include rollback logic** when possible
- **Always add RLS policies** in the same migration as table creation
- **Use transactions** for multi-step migrations
- **Add comments** explaining complex logic

Example migration:
```sql
-- Create group_fasts table
create table public.group_fasts (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  creator_id uuid references auth.users(id) on delete cascade not null,
  start_time timestamptz not null,
  target_duration_hours integer not null check (target_duration_hours > 0),
  status text not null default 'upcoming' check (status in ('upcoming', 'active', 'completed', 'closed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Enable RLS
alter table public.group_fasts enable row level security;

-- RLS Policies
create policy "Anyone can view group fasts"
  on public.group_fasts for select
  to authenticated
  using (true);

create policy "Approved users can create group fasts"
  on public.group_fasts for insert
  to authenticated
  with check (
    exists (
      select 1 from auth.users
      where id = auth.uid()
      and raw_user_meta_data->>'role' in ('approved', 'admin', 'super_admin')
    )
  );

-- Indexes
create index group_fasts_creator_id_idx on public.group_fasts(creator_id);
create index group_fasts_status_idx on public.group_fasts(status);
create index group_fasts_start_time_idx on public.group_fasts(start_time);

-- Triggers
create trigger update_group_fasts_updated_at
  before update on public.group_fasts
  for each row
  execute function public.update_updated_at_column();
```

### Row-Level Security (RLS)
**Always enable RLS** on all tables. Common patterns:

```sql
-- Users can read their own data
create policy "Users can view own profile"
  on public.user_profiles for select
  to authenticated
  using (auth.uid() = id);

-- Users can update their own data
create policy "Users can update own profile"
  on public.user_profiles for update
  to authenticated
  using (auth.uid() = id);

-- Admins can do anything
create policy "Admins can manage all data"
  on public.user_profiles for all
  to authenticated
  using (
    exists (
      select 1 from auth.users
      where id = auth.uid()
      and raw_user_meta_data->>'role' in ('admin', 'super_admin')
    )
  );
```

### Supabase Queries
Use the Supabase client for all database operations:

```ts
// Good: Type-safe query
const { data, error } = await supabase
  .from('group_fasts')
  .select(`
    *,
    creator:users!creator_id (
      id,
      email,
      raw_user_meta_data
    )
  `)
  .eq('status', 'active')
  .order('start_time', { ascending: true })

// Handle errors properly
if (error) {
  console.error('Database error:', error)
  throw new Error('Failed to fetch group fasts')
}
```

---

## State Management

### Nuxt Composables (Preferred)
Use Nuxt's built-in composables for state:
- `useState()` for shared state across components
- `useFetch()` for server-side data fetching
- `useAsyncData()` for async operations

Example:
```ts
// composables/useGlobalState.ts
export const useNotificationCount = () => useState<number>('notificationCount', () => 0)

// In any component:
const notificationCount = useNotificationCount()
notificationCount.value = 5 // Updates globally
```

### Supabase Auth State
Access auth state via Supabase composables:
```ts
const user = useSupabaseUser() // Reactive user object
const supabase = useSupabaseClient() // Supabase client
```

---

## Routing & Middleware

### Protected Routes
Use middleware to protect routes:

```ts
// layers/auth/app/middleware/auth.ts
export default defineNuxtRouteMiddleware((to, from) => {
  const user = useSupabaseUser()

  if (!user.value) {
    return navigateTo('/sign-in')
  }
})

// In page:
<script setup lang="ts">
definePageMeta({
  middleware: 'auth'
})
</script>
```

### Admin Routes
```ts
// layers/admin/app/middleware/admin.ts
export default defineNuxtRouteMiddleware((to, from) => {
  const user = useSupabaseUser()
  const role = user.value?.user_metadata?.role

  if (!['admin', 'super_admin'].includes(role)) {
    return navigateTo('/')
  }
})
```

---

## Styling Guidelines

### Tailwind CSS
Use Nuxt UI components where possible:
```vue
<template>
  <UButton color="primary" @click="handleClick">
    Join Fast
  </UButton>
</template>
```

Custom styles:
```vue
<template>
  <div class="rounded-lg border border-gray-200 p-4 hover:shadow-md transition-shadow">
    <!-- Content -->
  </div>
</template>
```

### Responsive Design
Mobile-first approach:
```vue
<div class="flex flex-col md:flex-row gap-4">
  <!-- Stacks on mobile, side-by-side on desktop -->
</div>
```

---

## Time & Timezone Handling

### Critical Rules
1. **Store all times in UTC** in the database (use `timestamptz` in PostgreSQL)
2. **Convert to user's timezone** for display
3. **Always show timezone label** to avoid confusion

### Timezone Utilities
Create utility functions for time conversions:

```ts
// utils/time.ts
import { format, formatDistanceToNow, parseISO } from 'date-fns'
import { utcToZonedTime, zonedTimeToUtc } from 'date-fns-tz'

export function formatInUserTimezone(utcTime: string, userTimezone: string): string {
  const date = parseISO(utcTime)
  const zonedDate = utcToZonedTime(date, userTimezone)
  return format(zonedDate, 'MMM d, yyyy h:mm a')
}

export function calculateHoursFasted(startTime: string, endTime: string): number {
  const start = parseISO(startTime)
  const end = parseISO(endTime)
  return (end.getTime() - start.getTime()) / (1000 * 60 * 60)
}

export function getProgressPercentage(startTime: string, targetHours: number): number {
  const start = parseISO(startTime)
  const now = new Date()
  const elapsedHours = (now.getTime() - start.getTime()) / (1000 * 60 * 60)
  return Math.min((elapsedHours / targetHours) * 100, 100)
}
```

### Display Times
Always show timezone:
```vue
<template>
  <div>
    <p>Starts: {{ formatInUserTimezone(fast.start_time, userTimezone) }}</p>
    <p class="text-sm text-gray-500">{{ userTimezone }}</p>
  </div>
</template>
```

---

## Error Handling

### Client-Side Errors
```ts
try {
  const { data, error } = await supabase
    .from('group_fasts')
    .insert({ ... })

  if (error) throw error

  // Success feedback
  toast.success('Fast created successfully!')
  navigateTo(`/fasts/${data.id}`)

} catch (error) {
  console.error('Failed to create fast:', error)
  toast.error('Failed to create fast. Please try again.')
}
```

### Server-Side Errors
```ts
// server/api/fasts/[id].get.ts
export default defineEventHandler(async (event) => {
  try {
    const id = getRouterParam(event, 'id')
    const supabase = useSupabaseClient()

    const { data, error } = await supabase
      .from('group_fasts')
      .select('*')
      .eq('id', id)
      .single()

    if (error) throw error
    return data

  } catch (error) {
    throw createError({
      statusCode: 500,
      message: 'Failed to fetch fast'
    })
  }
})
```

---

## Testing Strategy

### Unit Tests (Vitest)
Test composables and utility functions:

```ts
// composables/__tests__/useAuth.test.ts
import { describe, it, expect } from 'vitest'
import { useAuth } from '../useAuth'

describe('useAuth', () => {
  it('should return authenticated state', () => {
    const { isAuthenticated } = useAuth()
    expect(isAuthenticated.value).toBe(false)
  })
})
```

### E2E Tests (Playwright)
Test critical user flows:

```ts
// e2e/fast-creation.spec.ts
import { test, expect } from '@playwright/test'

test('user can create a group fast', async ({ page }) => {
  await page.goto('/sign-in')
  // Sign in flow...

  await page.goto('/fasts/create')
  await page.fill('[name="name"]', '72-Hour Challenge')
  await page.fill('[name="description"]', 'Join us for a 3-day fast!')
  await page.fill('[name="target_duration_hours"]', '72')
  await page.click('button[type="submit"]')

  await expect(page).toHaveURL(/\/fasts\/[a-z0-9-]+/)
  await expect(page.locator('h1')).toContainText('72-Hour Challenge')
})
```

---

## Performance Considerations

### Database Optimization
- **Add indexes** on frequently queried columns (user_id, status, created_at)
- **Use database views** for complex leaderboard queries
- **Paginate** long lists (fasts, chat messages, history)
- **Cache** expensive queries (leaderboard, stats)

### Frontend Optimization
- **Lazy load** images and components
- **Code split** admin routes
- **Use `v-once`** for static content
- **Implement virtual scrolling** for long lists

### Supabase Best Practices
- **Select only needed columns** (don't use `select('*')` everywhere)
- **Use `.single()` when expecting one result**
- **Batch reads** when possible
- **Avoid N+1 queries** (use joins)

Example of good query:
```ts
const { data } = await supabase
  .from('fast_participants')
  .select(`
    id,
    started_at,
    ended_at,
    user:users!user_id (
      id,
      raw_user_meta_data
    )
  `)
  .eq('group_fast_id', fastId)
  .order('started_at', { ascending: false })
```

---

## Security Guidelines

### Authentication
- **Never expose Supabase service role key** to the client
- **Always use anon key** on the client
- **Verify user identity** server-side for sensitive operations

### Authorization
- **Rely on RLS policies** for data access control
- **Double-check permissions** in admin operations
- **Log admin actions** for audit trail

### Input Validation
- **Validate all user inputs** with Zod
- **Sanitize user-generated content** (especially chat messages)
- **Limit input lengths** to prevent abuse

Example validation:
```ts
import { z } from 'zod'

const createFastSchema = z.object({
  name: z.string().min(3).max(100),
  description: z.string().max(1000).optional(),
  target_duration_hours: z.number().int().min(1).max(336), // Max 14 days
  start_time: z.string().datetime(),
})

// In form handler
try {
  const validated = createFastSchema.parse(formData)
  // Proceed with creation
} catch (error) {
  // Show validation errors
}
```

---

## Common Patterns & Recipes

### Fetching User Profile
```ts
const { user } = useAuth()
const profile = ref<UserProfile | null>(null)

async function fetchProfile() {
  if (!user.value) return

  const { data } = await supabase
    .from('user_profiles')
    .select('*')
    .eq('id', user.value.id)
    .single()

  profile.value = data
}

onMounted(() => fetchProfile())
```

### Joining a Group Fast
```ts
async function joinFast(fastId: string) {
  const { user } = useAuth()

  const { data, error } = await supabase
    .from('fast_participants')
    .insert({
      group_fast_id: fastId,
      user_id: user.value.id,
      target_duration_hours: fast.value.target_duration_hours,
      status: 'active'
    })
    .select()
    .single()

  if (error) {
    if (error.code === '23505') { // Unique constraint violation
      toast.error('You are already participating in this fast')
    } else {
      toast.error('Failed to join fast')
    }
    return
  }

  toast.success('Successfully joined the fast!')
}
```

### Starting Fast Timer
```ts
async function startFastTimer(participantId: string) {
  const { error } = await supabase
    .from('fast_participants')
    .update({ started_at: new Date().toISOString() })
    .eq('id', participantId)

  if (error) {
    toast.error('Failed to start timer')
    return
  }

  toast.success('Fast timer started!')
}
```

### Calculating Progress
```ts
function calculateProgress(participant: FastParticipant): number {
  if (!participant.started_at) return 0

  const start = new Date(participant.started_at)
  const now = new Date()
  const elapsed = (now.getTime() - start.getTime()) / (1000 * 60 * 60)
  const target = participant.target_duration_hours

  return Math.min((elapsed / target) * 100, 100)
}
```

---

## Debugging Tips

### Supabase Debug
Enable query logging:
```ts
const supabase = useSupabaseClient()

// In development, log all queries
if (process.dev) {
  supabase.channel('debug').on('*', payload => {
    console.log('Supabase event:', payload)
  })
}
```

### Check RLS Policies
If queries return empty:
1. Check if RLS is enabled on the table
2. Verify policies allow the operation
3. Test with Supabase dashboard SQL editor

### Common Issues
- **"Row not found"**: Check RLS policies
- **"Unique constraint violation"**: User trying to join same fast twice
- **Timezone confusion**: Always convert to user's timezone for display
- **Stale data**: Remember to refresh queries after mutations

---

## When Adding New Features

### Checklist
1. [ ] Design database schema (tables, columns, relationships)
2. [ ] Write migration file
3. [ ] Add RLS policies
4. [ ] Create TypeScript types in `shared/types/`
5. [ ] Write composable for data fetching/mutations
6. [ ] Create UI components
7. [ ] Add page(s) and routing
8. [ ] Handle loading and error states
9. [ ] Add validation with Zod
10. [ ] Write unit tests for composables
11. [ ] Write E2E test for user flow
12. [ ] Update `TODO.md` to mark tasks complete

---

## Project-Specific Notes

### User Roles
- `pending`: Newly registered, awaiting approval
- `approved`: Can access app and all features
- `admin`: Can moderate content, manage users (cannot promote to super_admin)
- `super_admin`: Full access, can promote other admins

### Fast Participation Rules
- Users can have **ONE active group fast** at a time
- Users can have **ONE active personal fast** at a time
- Users can join a fast late (after start time)
- Users can end a fast early or extend beyond target
- Fasts close when last participant ends OR admin closes manually

### Notification Events
All notifications are **in-app only** (no push/email in v1):
- User joins your fast
- Fast starting in 1 hour
- Milestone reached (24hr, 48hr, 72hr)
- New chat message
- Achievement earned
- Admin approval/rejection
- New user registration (admins only)

### Leaderboard Logic
Rankings are by **absolute hours fasted**, not percentage of target:
- User A: 36 hours out of 48-hour fast → 36 hours rank
- User B: 24 hours out of 72-hour fast → 24 hours rank
- User A ranks higher than User B

---

## Resources

### Documentation
- [Nuxt 3 Docs](https://nuxt.com/docs)
- [Supabase Docs](https://supabase.com/docs)
- [Tailwind CSS Docs](https://tailwindcss.com/docs)
- [Nuxt UI Components](https://ui.nuxt.com/)

### Supabase CLI
```bash
# Install
brew install supabase/tap/supabase

# Initialize
supabase init

# Link to project
supabase link --project-ref your-project-ref

# Create migration
supabase migration new migration_name

# Apply migrations locally
supabase db reset

# Push to production
supabase db push

# Generate TypeScript types
supabase gen types typescript --local > types/supabase.ts
```

---

## Contact & Support

**Project Lead**: Krzysztof (Developer)
**Client**: Joseph (What I've Learned YouTube Channel)

For questions about project requirements or design decisions, refer to `PROJECT.md` or consult with Krzysztof.

---

**Last Updated**: October 4, 2025
