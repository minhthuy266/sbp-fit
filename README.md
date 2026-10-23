# SBP FIT — Stronger Every Day

Production-oriented Sprint 01 foundation for an internal team fitness app built with Next.js 16, React 19, TypeScript, Tailwind CSS 4 and Supabase.

## Setup

```bash
npm install
cp .env.example .env.local
npm run dev
```

Configure your Supabase URL and publishable key in `.env.local`, run `supabase/migrations/202610230001_foundation.sql` in SQL Editor, and configure the Auth callback URL to `http://localhost:3000/auth/callback`.

To run local Supabase, use `supabase start` and `supabase db reset`. The source includes RLS policies, private team membership and invitation flows.

This is Sprint 01 foundation, not the complete challenges/activity tracker application. See `docs/SPRINT_01_ACCEPTANCE.md`.
