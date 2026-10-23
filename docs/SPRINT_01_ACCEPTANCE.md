# Sprint 01 acceptance tests

1. Create a new user, confirm email (if enabled), log in, refresh dashboard: session retained.
2. Unauthenticated visitor opens `/dashboard` or `/teams`: redirected to `/login`.
3. Owner creates `SBP Team` with valid slug, sees team membership with `owner` role.
4. Duplicate slug is rejected by unique constraint.
5. Owner generates a single-use, time-limited invite code; second user accepts it and sees team.
6. Reusing the invite fails; invalid token fails; expired token fails.
7. Member cannot generate invitation and cannot read records from an unrelated team (SQL/RLS test).
8. Another user cannot update a different user's profile or self-promote to admin.
9. UI works at mobile width (375px), tablet (768px), desktop (1440px).
10. `/api/health` returns JSON; `npm run typecheck`, `npm run lint`, `npm run build` pass with dependencies installed.

Manual integration tests require a provisioned Supabase backend and at least two accounts. They are not claimed as executed in this artifact.
