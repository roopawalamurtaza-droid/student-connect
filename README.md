# Student Connect

A Flutter campus community app for Android, iOS, and web. The application has been rebuilt from the supplied visual prototype, with feature-based Flutter code, real Firebase adapters, and a separately labeled local preview.

## Run now

Open a new PowerShell terminal so it receives the updated PATH:

```powershell
cd C:\Flutter\student_connect
flutter run -d chrome
```

If an already-open terminal has not picked up PATH:

```powershell
cd C:\Flutter\student_connect
& C:\Flutter\sdk\flutter\bin\flutter.bat run -d chrome
```

Select **Explore local preview**. Preview interactions are local and temporary; they reset when you leave or reload. It does not create accounts, send messages, or contact a university backend.

The built web preview is also served at http://localhost:5173 while the local preview server is running. Restart that server with:

```powershell
node C:\Flutter\student_connect\scripts\serve-preview.mjs
```

For Android:

```powershell
flutter emulators --launch Student_Connect_API_36
flutter run -d emulator-5554
```

If the emulator is already running, use only the second command. `flutter devices` shows its current device ID. The emulator created during setup runs without a visible window; launch it from Android Studio Device Manager when you want to see its screen.

## Architecture

```text
lib/
  main.dart               Startup and failure handling
  app/                    Session gate, responsive workspace, theme state
  core/                   Build-time Firebase and email-domain configuration
  models/                 Typed campus document envelope
  repositories/           Repository contract, Firebase and local preview adapters
  services/               Firebase bootstrap, App Check, Crashlytics, device messaging
  features/
    auth/                 Login, registration, email verification, password reset
    feed/                 Posts, images, likes, comments, reporting
    discover/             Communities, membership, community feeds, search, people
    events/               Event details and registration
    profile/              Profile and photo editing
    notifications/        Personal updates and campus announcements
    admin/                Events, communities, reports, user access, announcements
  routes/                 Main destination definitions
  theme/                  Shared light and dark Material themes
  widgets/                Async actions, streams, images, empty states, avatars
backend/
  functions/              Callable API, validation, event reminders, tests
  firestore.rules         Verified-member reads; client writes denied
  storage.rules           Verified-member reads; direct uploads denied
  firestore.indexes.json  TTL configuration for request counters
config/                   Firebase configuration example
scripts/                  Verification, local server, branding, admin bootstrap
assets/brand/             Editable Student Connect vector logo
```

State uses scoped Flutter state, Firebase Auth streams, and Firestore streams. The repository boundary isolates UI from storage and prevents the local preview from masquerading as live functionality. Queries are bounded to 200 documents per category; discover explicitly describes the scope of its search.

## Implemented

- Responsive Home, Discover, Create, Events, and Profile screens; desktop sidebar and mobile bottom navigation.
- Light/dark themes, saved theme preference, loading states, empty states, validation, error messages, and asynchronous action buttons.
- Firebase email/password registration and login, verification gate, resend verification, password reset, SDK-managed session persistence, logout, and profile onboarding.
- Server-approved university email domain allowlist. No domain has been assumed on your behalf.
- Student profile fields, skills, and validated profile-photo uploads.
- Campus and community posts, images, likes, comments, reports, own-post editing/deletion, and moderator deletion.
- Club, department, and community discovery; join/leave; community feeds.
- Events, date/time/location, create/edit/delete controls, registration/cancellation, persistent in-app reminders.
- Personal like/comment notifications, mark-as-read, announcements, and optional Android/iOS push registration with token refresh handling.
- Representative, moderator, and administrator controls backed by server-side role checks, suspension, session revocation, report resolution, and an access-change audit trail.
- App Check activation, native Crashlytics wiring, and Analytics screen events in connected mode.
- Brand icons for Android, iOS, web, and Windows.

The Firebase-backed features are implemented but require the external project setup below before they can be used live. The preview exposes student workflows only; it does not grant simulated administrator privileges.

## Security design

All changes use a callable Cloud Function with App Check enforcement. The server retrieves the Auth account, requires verified university email, checks the server-owned role and suspension fields, and applies a 30-request-per-minute user limit. Clients cannot directly write database documents or Storage objects. Profile input uses strict schemas so role fields cannot be injected during onboarding.

Images are limited to 3 MiB and 16 megapixels. The server decodes JPEG/PNG/WebP, resizes to at most 1600 pixels, removes metadata, and writes a newly encoded JPEG under the authenticated user. Flutter renders user content as text rather than HTML. Administrative actions require server-owned privileges. Students cannot enumerate other students' event registrations or read their personal notifications.

The initial administrator must be assigned through a trusted Firebase console/administrative environment. No admin password or service-account key is included. The optional bootstrap script is `scripts/bootstrap-admin.mjs` and requires external Application Default Credentials.

## External setup still required

Follow [docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md). You need to create a Firebase project, confirm your actual university email domains, register each platform app, enable Authentication/Firestore/Storage, configure App Check, and deploy the backend/rules. Firebase billable-service activation, account login, university approval, and store publishing have not been performed.

An iOS source project is included, but building/signing/testing it requires macOS, Xcode, and Apple signing credentials. APNs configuration, release signing, and live Crashlytics/App Check/push delivery also need account-specific setup. Windows desktop tooling is healthy and a platform scaffold is included; an actual Windows app build was outside the requested Android/web build checks.

## Validation

Verified on this Windows PC on 9 September 2026:

- Flutter Doctor: no issues; Android emulator, Chrome, Edge, and Windows detected.
- Flutter analyzer: no issues on the verified source.
- Flutter tests: repository behavior plus phone (390×844) and desktop (1440×1000) navigation/publishing flows.
- Backend: 4 validation tests and 7 Firebase emulator integration tests, run with Node.js 22.
- Integration coverage: authentication/verification/domain gates, role injection, author permissions, suspension, private notifications/registration, image decoding/re-encoding, event permissions, registration toggles, and comment/like persistence.
- Android debug APK and production web build succeeded. Android app installed and launched in the API 36 emulator.
- Browser check: desktop feed, local post publication, responsive phone layout, and dark theme.
- Backend dependency audit: zero vulnerabilities at the time checked. The UUID override pins a patched compatible CommonJS release for transitive consumers; keep it under review when updating Firebase Admin.

Logs are in `docs/`. Run `scripts/verify.ps1` to repeat analyzer, Flutter tests, Android/web builds, and Flutter Doctor. The Android build emits upstream FlutterFire/Kotlin migration notices and Java compatibility warnings; these did not block the successful build.

The backend integration tests call the function handler against local Auth/Firestore/Storage emulators. They do not prove production App Check attestation, real verification-email delivery, or device push delivery; those require the live project.

## Before a campus-wide launch

This is a tested foundation, not a deployed university service. In addition to Firebase connection and signed release testing, plan pagination/server-backed full-text search beyond the current 200-result window, orphaned-image cleanup, account/data deletion and retention, and a review of operational quotas and moderation policy. Browser push currently reports that its deployment service worker is required; in-app notifications remain available. Native push supports event reminders; likes/comments are in-app notifications. Event reminders are processed in bounded batches and should be load-tested for large events.

## Your original code

The supplied prototype is preserved in `docs/original-prototype.dart.txt`. Its simulated authentication and no-op buttons were not carried into live mode.
