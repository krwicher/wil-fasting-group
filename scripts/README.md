# Scripts

This directory contains utility scripts for database seeding and maintenance.

## seed.js

Seeds the database with test data for development and testing.

### Prerequisites

1. User account created via the app (sign up first)
2. Environment variables set (see below)

### Usage

**Local development:**

```bash
# Get your service role key from Supabase CLI
supabase status

# Run the seed script
SUPABASE_URL=http://127.0.0.1:54321 \
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key \
ADMIN_EMAIL=your@email.com \
node scripts/seed.js
```

**Remote staging:**

```bash
# Get service role key from Supabase Dashboard → Settings → API
SUPABASE_URL=https://your-project.supabase.co \
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key \
ADMIN_EMAIL=your@email.com \
node scripts/seed.js
```

### What it does

1. **Promotes user to super_admin** - Updates the specified email to have super_admin role
2. **Creates sample group fasts:**
   - 48-Hour Weekend Challenge (upcoming)
   - 72-Hour Deep Fast (active)
   - 5-Day Extended Fast (upcoming)
   - 24-Hour Beginner Fast (completed)
3. **Joins admin to active fast** - Auto-joins the admin user to the 72-hour fast
4. **Creates personal fast** - Adds a completed personal fast to the admin's history

### Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `SUPABASE_URL` | Your Supabase project URL | `http://127.0.0.1:54321` |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role key (bypasses RLS) | `eyJhbGc...` |
| `ADMIN_EMAIL` | Email of user to promote | `admin@example.com` |

### Notes

- **Service role key** bypasses Row Level Security - use carefully!
- Run this script **only in development/staging**, never in production
- You must sign up via the app **before** running this script
- The script is idempotent for user promotion but will create duplicate fasts if run multiple times

### Resetting Data

To clear all test data and reseed:

```sql
-- Connect to your database
psql <your-connection-string>

-- Delete all data (careful!)
DELETE FROM public.group_fasts;
DELETE FROM public.personal_fasts;
DELETE FROM public.user_profiles WHERE id NOT IN (SELECT id FROM auth.users);

-- Then re-run the seed script
```
