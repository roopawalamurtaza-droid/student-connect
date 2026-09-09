# Student Connect backend

Supabase is the only application database and identity provider. The project is `afbjuuppjlhiydvzrzdz` (Mumbai), in the existing Free Practice organization. No server credentials belong in Flutter or Git.

Apply migrations with `supabase db push --linked`. Review `supabase config diff` before `supabase config push`. Deploy the three Edge Functions using `supabase functions deploy NAME --use-api`. The gateway's legacy JWT check is disabled because each user function validates the bearer session using `auth.getUser()`; `dispatch-push` requires a separate server-only secret.

## Tests

- `node --test supabase/tests/security.test.mjs`: PostgreSQL schema, RLS, mutations, role boundaries, draft media, signup restrictions, reminders and privacy, run in PGlite. Auth identity is stubbed only inside tests. pg_cron is checked on the deployed database.
- `deno test --allow-read --allow-net=deno.land supabase/tests/image_test.ts`: actual PNG/JPEG decoding, resize and re-encoding; malformed and oversized input rejection.
- `node scripts/smoke-supabase.mjs`: live anonymous access denial, function authentication and rejected non-university signup. It creates no valid account and sends no email.

## Email and first administrator

The approved domain is `ppsu.ac.in`, enforced by the before-user-created Auth hook and database identity checks. Email confirmation stays enabled. Configure your SMTP service in Authentication → Email / SMTP in the Supabase dashboard. The default Supabase email service only delivers to project team members; it cannot onboard university students. Do not turn off email confirmation to bypass this.

After a real university account verifies its email and completes onboarding, a project owner can assign the first administrator from the SQL Editor. Use the verified account's exact UUID, never user-supplied role metadata:

```sql
begin;
update public.user_roles set role='super_admin',updated_at=now()
where user_id='REPLACE_WITH_VERIFIED_ACCOUNT_UUID'::uuid
and exists(select 1 from auth.users u join public.profiles p on p.id=u.id
 where u.id=user_id and u.email_confirmed_at is not null
 and lower(split_part(u.email,'@',2))='ppsu.ac.in' and not p.suspended);
commit;
```

All subsequent role changes use the checked `moderateUser` RPC through the admin screen. Students cannot directly write tables or assign roles. Faculty and moderators can moderate content; only admin/super_admin can manage roles, and only super_admin can manage administrator access.

## Media, notifications and privacy

The `campus-media` bucket is private. Uploads pass JWT verification, rate limiting, actual image decoding, a 3 MiB / 16 MP limit, JPEG re-encoding, and ownership checks. Images are resized to a maximum of 1600 pixels. Per-user storage is limited to 100 MiB. Draft/replaced uploads are private to their owner. Cancellation may leave an unattached asset; account deletion removes the owner's assets. A production retention policy for abandoned uploads should be agreed before broad rollout.

Clubs share `community_members` with their parent community; no duplicate club-member store exists. Notifications are private rows in PostgreSQL. Likes/comments create notifications transactionally. A database cron job runs every five minutes to create deduplicated reminders for registered events starting within an hour.

`dispatch-push` is deployed but remains disabled until both `PUSH_DISPATCH_SECRET` and `FCM_SERVICE_ACCOUNT` are securely installed as Edge Function secrets. Then schedule a server-only POST with that secret in the Authorization header (Supabase Vault + pg_net/cron, or a trusted scheduler). Never put it in Flutter. Delivery retries are bounded; delivery across multiple devices is at least once, so a successful device may receive a duplicate on retry. In-app notifications remain the source of truth.

Google/Apple OAuth service entry points are prepared but no login buttons are advertised before providers and native credentials are configured. Android and iOS callback scheme: `app.studentconnect://auth/callback`. Password recovery adds `?recovery=1`. Add the exact production HTTPS callback URLs when a hosting domain is selected; current web callbacks are localhost development URLs.
