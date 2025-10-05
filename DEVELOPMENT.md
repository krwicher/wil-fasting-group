# Development Workflow Guide

This document explains the hybrid local/remote development approach for the What I've Learned Fasting Group App.

---

## Overview

We use a **hybrid development approach**:
- **Local Supabase** for fast iteration, schema changes, and business logic development
- **Remote Staging** for OAuth testing (Google/Apple login) and Storage integration testing

---

## Environment Setup

### Prerequisites

1. **Docker Desktop** installed and running
2. **Supabase CLI** installed (`brew install supabase/tap/supabase`)
3. **pnpm** installed (`npm install -g pnpm`)

### Environment Files

We maintain two environment configurations:

- **`.env.local`** - Local Supabase configuration (default)
- **`.env.staging`** - Remote staging Supabase configuration
- **`.env`** - Active configuration (symlink/copy of one of the above)

---

## Daily Development Workflow

### Starting Local Development

```bash
# 1. Ensure Docker is running
# Check Docker Desktop app

# 2. Start local Supabase stack
supabase start

# 3. Ensure you're using local environment
cp .env.local .env

# 4. Start development server
pnpm dev
```

### Local Development (Default)

Use local development for:
- ✅ Creating database migrations
- ✅ Testing business logic and queries
- ✅ Building UI components
- ✅ Fast iteration on schema changes
- ✅ Offline work
- ✅ Testing without OAuth

**Local Supabase URLs:**
```
API URL: http://127.0.0.1:54321
Studio: http://127.0.0.1:54323
Database: postgresql://postgres:postgres@127.0.0.1:54322/postgres
```

### Switching to Remote Staging

Use remote staging for:
- ✅ Testing OAuth flows (Google/Apple login)
- ✅ Testing Storage bucket (avatar uploads)
- ✅ Full integration testing
- ✅ Sharing work with stakeholders

**To switch to staging:**
```bash
# 1. Copy staging environment
cp .env.staging .env

# 2. Restart dev server
pnpm dev

# Now your app connects to remote staging Supabase
```

**To switch back to local:**
```bash
# 1. Copy local environment
cp .env.local .env

# 2. Restart dev server
pnpm dev
```

---

## Database Migration Workflow

Always create and test migrations locally first, then push to remote.

### 1. Create Migration (Local)

```bash
# Ensure local Supabase is running
supabase start

# Create new migration
supabase migration new create_users_table

# This creates: supabase/migrations/YYYYMMDDHHMMSS_create_users_table.sql
```

### 2. Write Migration SQL

Edit the generated file in `supabase/migrations/`:

```sql
-- Example migration
create table public.users (
  id uuid primary key default gen_random_uuid(),
  email text not null unique,
  created_at timestamptz not null default now()
);

alter table public.users enable row level security;

create policy "Users can view own data"
  on public.users for select
  to authenticated
  using (auth.uid() = id);
```

### 3. Apply Migration Locally

**Option A: Apply just the new migration (recommended)**
```bash
# Apply new migrations without resetting
psql postgresql://postgres:postgres@127.0.0.1:54322/postgres \
  -f supabase/migrations/YYYYMMDDHHMMSS_migration_name.sql

# Verify in Supabase Studio
open http://127.0.0.1:54323
```

**Option B: Reset database (first time or when needed)**
```bash
# ⚠️ WARNING: This drops ALL data and redownloads Docker images
# Only use for first-time setup or when you need a clean slate
supabase db reset

# Verify in Supabase Studio
open http://127.0.0.1:54323
```

**Pro tip:** Use Option A to avoid redownloading Docker images on every change.

### 4. Test Locally

```bash
# Ensure using local env
cp .env.local .env

# Test your changes
pnpm dev

# Run tests if applicable
pnpm test
```

### 5. Push to Remote Staging

Once tested locally:

```bash
# Push migrations to remote staging
supabase db push

# Switch to staging environment to test
cp .env.staging .env
pnpm dev

# Test OAuth, Storage, full integration
```

### 6. Push to Production (Later)

```bash
# Link to production project
supabase link --project-ref <production-id>

# Push same migrations
supabase db push

# IMPORTANT: Always test on staging first!
```

---

## Common Commands

### Supabase CLI

```bash
# Start local Supabase
supabase start

# Stop local Supabase
supabase stop

# View connection details
supabase status

# Create new migration
supabase migration new <name>

# Reset local DB (applies all migrations)
supabase db reset

# Push migrations to remote
supabase db push

# Pull migrations from remote
supabase db pull

# Link to remote project
supabase link --project-ref <project-ref>

# Generate TypeScript types
supabase gen types typescript --local > types/supabase.ts
```

### Development Server

```bash
# Install dependencies
pnpm install

# Start dev server
pnpm dev

# Build for production
pnpm build

# Run tests
pnpm test
```

---

## Troubleshooting

### Local Supabase won't start

```bash
# Check if Docker is running
docker ps

# Stop and restart Supabase
supabase stop
supabase start

# Check logs
docker logs supabase_db_wil-fasting-group
```

### Migration fails

```bash
# Check migration syntax
cat supabase/migrations/YYYYMMDDHHMMSS_migration_name.sql

# Reset and try again
supabase db reset

# If still failing, check Supabase logs
docker logs supabase_db_wil-fasting-group
```

### OAuth not working locally

OAuth (Google/Apple login) will **not work** on local Supabase. This is expected.

**Solution:** Switch to remote staging for OAuth testing:
```bash
cp .env.staging .env
pnpm dev
```

### Can't access Supabase Studio

```bash
# Check if services are running
supabase status

# Open Studio
open http://127.0.0.1:54323

# If not working, restart
supabase stop && supabase start
```

### Environment confusion

```bash
# Check current environment
cat .env | grep SUPABASE_URL

# Local: http://127.0.0.1:54321
# Staging: https://ujgmthzlrfwjqvbkgcet.supabase.co

# Switch to local
cp .env.local .env

# Switch to staging
cp .env.staging .env

# Always restart dev server after switching
pnpm dev
```

---

## Best Practices

### DO ✅

- Always start with local development
- Test migrations locally before pushing to remote
- Use remote staging for OAuth and Storage testing only
- Commit migrations to git immediately after creating
- Document complex migrations with comments
- Keep `.env.local` and `.env.staging` in sync (except URLs/keys)

### DON'T ❌

- Don't edit the database manually in production
- Don't skip testing migrations locally
- Don't commit `.env` to git (it's in `.gitignore`)
- Don't use remote staging for every change (expensive)
- Don't forget to switch back to local after OAuth testing
- Don't run `supabase db push` without testing locally first

---

## OAuth Setup (Manual Steps)

OAuth must be configured manually on remote staging:

### Google OAuth

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create OAuth 2.0 credentials
3. Add authorized redirect URI: `https://ujgmthzlrfwjqvbkgcet.supabase.co/auth/v1/callback`
4. Copy Client ID and Client Secret
5. Add to Supabase Dashboard: Authentication → Providers → Google

### Apple OAuth

1. Go to [Apple Developer Console](https://developer.apple.com/)
2. Create App ID and Service ID
3. Configure Sign in with Apple
4. Add return URL: `https://ujgmthzlrfwjqvbkgcet.supabase.co/auth/v1/callback`
5. Generate key and get Team ID
6. Add to Supabase Dashboard: Authentication → Providers → Apple

---

## File Structure

```
wil-fasting-group/
├── .env                    # Active environment (git-ignored)
├── .env.local              # Local Supabase config (committed)
├── .env.staging            # Remote staging config (committed)
├── supabase/
│   ├── config.toml         # Supabase CLI config
│   ├── migrations/         # Database migrations (committed)
│   └── seed.sql            # Seed data (optional)
├── layers/
│   ├── base/               # Base UI layer
│   ├── auth/               # Auth layer
│   └── ...
└── DEVELOPMENT.md          # This file
```

---

## Quick Reference

| Task | Environment | Command |
|------|-------------|---------|
| Schema changes | Local | `supabase migration new <name>` → `supabase db reset` |
| Test business logic | Local | `cp .env.local .env && pnpm dev` |
| Test OAuth | Staging | `cp .env.staging .env && pnpm dev` |
| Push to staging | Staging | `supabase db push` |
| View local DB | Local | `open http://127.0.0.1:54323` |
| Check environment | Either | `cat .env \| grep SUPABASE_URL` |

---

**Last Updated:** October 5, 2025
