# SBP FIT — Stronger Every Day

Production-oriented Sprint 01 foundation for an internal team fitness challenge application.

## Requirements

- Node.js 20.9+ (22 LTS recommended)
- Supabase hosted project or Supabase CLI + Docker

## Quick start

```bash
npm install
cp .env.example .env.local
npm run dev
```

Fill `.env.local` with Supabase Project URL and publishable key. Apply `supabase/migrations/202610230001_foundation.sql` in Supabase SQL Editor, then configure `http://localhost:3000/auth/callback` in Authentication redirect URLs. Visit `http://localhost:3000` and sign up.

### Local backend

```bash
supabase start
supabase db reset
```

## Useful commands

```bash
npm run typecheck
npm run lint
npm run build
```

## Scope

Implemented: landing page, email/password authentication, auth callback, server-side session, team creation, memberships, single-use invitations, RLS, responsive shell.

Not yet implemented: challenge CRUD, activity tracking, XP, badges or real leaderboard; these belong to subsequent sprints.

See `docs/SPRINT_01_ACCEPTANCE.md` for detailed acceptance criteria.
