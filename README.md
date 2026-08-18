# QuizForge

A responsive, gamified Quiz Bowl practice app with daily drills, immediate
answer feedback, category training, XP, streaks, progress, and leaderboards.

## Run locally

```bash
npm install
npm run dev
```

Open `http://localhost:3000`. Progress is stored per user in Supabase, and the
app redirects signed-out visitors to the login screen.

## Supabase setup

1. Create a Supabase project and copy `.env.example` to `.env.local`.
2. Set the project URL and publishable key.
3. Run `supabase/migrations/202608170001_quizforge_auth_progress.sql` in the
   Supabase SQL editor.
4. Add `http://localhost:3000/auth/callback` to the allowed redirect URLs in
   Supabase Authentication settings.

The migration creates profiles, practice sessions, answer history, daily
progress, row-level security policies, and the atomic session-completion RPC.
XP, accuracy totals, and streak updates are validated server-side.
