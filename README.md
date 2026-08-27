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
2. Set the project URL, publishable key, and `NEXT_PUBLIC_SITE_URL` to the
   canonical HTTPS URL where users access the app.
3. Run `supabase/migrations/202608170001_quizforge_auth_progress.sql` in the
   Supabase SQL editor.
4. In Supabase Authentication → URL Configuration, set **Site URL** to that
   same public URL and add `<NEXT_PUBLIC_SITE_URL>/auth/callback` to the
   allowed redirect URLs. Keep `http://localhost:3000/auth/callback` only as
   an additional development callback if local signup testing is needed.

The migration creates profiles, practice sessions, answer history, daily
progress, row-level security policies, and the atomic session-completion RPC.
XP, accuracy totals, and streak updates are validated server-side.

## Admin console

The MVP admin console is available at `/admin` and uses a separate sign-in
screen at `/admin/login`. Admins use their existing Supabase identity, but an
explicit staff role is required before any admin route or RPC can be accessed.

After applying `supabase/migrations/202608270001_admin_mvp.sql`, bootstrap the
first super admin from the Supabase SQL editor. Replace the username below with
the intended staff account:

```sql
insert into public.admin_user_roles (user_id, role_id)
select p.id, r.id
from public.profiles p
cross join public.admin_roles r
where p.username = 'YOUR_ADMIN_USERNAME'
  and r.key = 'super_admin'
on conflict (user_id, role_id) do nothing;
```

Additional `super_admin`, `content_admin`, and `support_admin` assignments can
then be managed from `/admin/settings`. All admin mutations are server-side,
capability checked in Postgres, and recorded in `admin_audit_logs`.

## Product enhancement services

`202608280001_product_enhancements.sql` adds timed attempts, live progress and
category aggregates, achievements, referrals, friendships, notification
preferences, XP events, and the trusted RPCs used by the learner experience.

Daily reminder delivery uses the hourly Vercel cron in `vercel.json`. Configure
`SUPABASE_SERVICE_ROLE_KEY`, `RESEND_API_KEY`, `REMINDER_FROM_EMAIL`, and
`CRON_SECRET` in the deployment environment. The service-role key is server-only
and must never use a `NEXT_PUBLIC_` prefix. Reminders remain opt-in, are skipped
after daily completion, and are deduplicated per user and local date.
