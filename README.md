# Student Connect

Existing Flutter campus app, continued in place and migrated to **Supabase** as its only identity and application-data backend. The original prototype and earlier Firebase implementation are preserved in Git checkpoint b24e08c and archival files; Firebase Auth/Firestore/Storage are no longer used or deployed.

## Run the connected app

Published web app: **https://student-connect-ppsu-2026.web.app/**. The sign-in and password-recovery redirects are configured for this address; localhost and Android/iOS callbacks are retained.

Open this folder in VS Code and select **Student Connect · Supabase**.

In Android Studio, open the project root `C:\Flutter\student_connect` and choose **Student Connect - Connected** in the Run dropdown. This shared configuration loads the local connection settings. The existing `main.dart` configuration on this PC also includes these arguments. If Android Studio was already open, reopen the project to reload its configurations, then stop and run again; hot reload cannot change build-time connection settings. Running `main.dart` without the configuration arguments intentionally shows the “not configured” screen. Web launches use port 5173 to match the registered authentication redirects.

From a terminal:

```powershell
cd C:\Flutter\student_connect
flutter run -d chrome --web-port 5173 --dart-define-from-file=config/supabase.local.json
flutter run -d emulator-5554 --dart-define-from-file=config/supabase.local.json
```

The ignored local config contains the Supabase URL and public publishable key only. For another checkout, copy config/supabase.example.json to config/supabase.local.json and enter those public values. Never use a service-role key in Flutter. The existing temporary preview is disabled by default; it is available only with ENABLE_LOCAL_PREVIEW=true for development and existing UI regression tests.

## Connected services

- Private backup: https://github.com/roopawalamurtaza-droid/student-connect
- Supabase project: https://supabase.com/dashboard/project/afbjuuppjlhiydvzrzdz (Student Connect, Mumbai, Free Practice organization).
- Dart/Flutter CLI, live MCP tooling, and plugin architecture/analysis/testing guidance are in use. Flutter SDK: C:\Flutter\sdk\flutter.
- GitHub and Figma accounts are connected. No Figma design file was supplied; the existing visual design is preserved.
- Firebase project: https://console.firebase.google.com/project/student-connect-ppsu-2026/overview (Spark, billing disabled). Android, iOS and web registrations and public configuration are included. The local build enables Firebase; Android Crashlytics initializes successfully. Supabase remains the only identity and application-data backend.
- No callable Product Design or Supabase/Firebase MCP integration was available; the official CLIs are used where applicable.

## Implemented in the existing UI

Responsive campus feed, profile onboarding, image posts, comments, likes, saved posts, community/club membership, events and registration, server search with pagination, notifications, reporting, blocking/unblocking, role management, suspension and moderation. Light/dark themes and app icons are preserved. Community images and event banners use the same checked upload path as profile and post photos.

Supabase email/password sign-in, signup and verification, resend verification, forgot/reset password, persisted/refreshed sessions, logout and password-confirmed account deletion are connected. Google/Apple provider entry points are prepared but disabled until their credentials are configured. Android/iOS recovery deep links and development web redirects are configured.

The exact approved email domain is ppsu.ac.in. The Auth signup hook rejects other domains, and PostgreSQL also verifies confirmed university identity on application access. Roles are student, club_admin, moderator, faculty, admin and super_admin. Normal clients cannot write tables or assign their own roles; checked transactional RPCs enforce permissions. See [the backend guide](supabase/README.md) for migrations, media policy, first administrator setup and notification delivery.

## What still needs account setup

1. **Email sender:** the Resend account is created; a verified sender domain or university SMTP relay is still needed. See [the university IT request](docs/UNIVERSITY_EMAIL_SETUP.md) and [release setup](docs/RELEASE.md). The default Supabase mailer only sends to project team members. Real student registration cannot complete until the sender is supplied; no email verification has been bypassed and no fake verified student was created.
2. **Telemetry and push validation:** the FCM-only sender is installed in Supabase secrets, with Vault-backed dispatch scheduled every minute when eligible jobs exist. The worker authenticated successfully with an empty queue. Real device delivery still needs a verified student and notification permission; iOS needs APNs credentials. Google Analytics is linked to property 553447807 in the existing Default Account for Firebase. Crash reporting hooks initialize, but crash ingestion is not yet verified.
3. **First administrator:** after a real university user verifies email and onboards, assign that exact user through the trusted SQL procedure in the backend guide. No administrator was invented from the sample email address.
4. **Release:** the web app is published on Firebase HTTPS hosting. Dedicated Android signing is configured and the release APK signature verifies. The key is stored outside Git with its password protected by Windows; preserve a secure backup before distribution. Privacy/retention policy and store accounts remain. iOS building and APNs validation require a Mac with Xcode and Apple credentials. See [release instructions](docs/RELEASE.md).

## Structure and checks

UI features are under lib/features; new authentication logic is in its view model and repository; services own Supabase transport, Firebase telemetry is optional; Supabase SQL migrations and Edge Functions are under supabase/. All active application data is normalized PostgreSQL with RLS. Clubs share the community membership table rather than duplicating it.

Run scripts/verify.ps1 for formatting, strict analyzer, Flutter tests, connected Android debug APK, web build and Flutter Doctor. Backend tests and live endpoint smoke checks are documented in supabase/README.md. Test fixtures are isolated from the live project. Current logs live under docs/.

Supabase's security advisor reports no ERROR findings. It flags the two intentionally exposed SECURITY DEFINER mutation RPCs for review; they use a fixed empty search path, verified identity, roles, ownership checks and rate limiting. Direct table writes remain denied. Full email and push delivery require the external setup above and have not been claimed as tested.
