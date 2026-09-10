# Validation — 10 September 2026

- Flutter 3.47.2 / Dart 3.13.2; strict analyzer clean.
- Nine Flutter tests passed: profile/post/report mapping, university domain matching, existing repository behavior, mobile/desktop navigation/publishing layouts, and signup completion both before and after screen disposal.
- Nine PostgreSQL/PGlite security tests passed: verification/domain gates, no role escalation, ownership, notifications, blocking, event permissions/registration privacy, suspension, private RPCs, draft media privacy, signup hook, administrator hierarchy and last-admin retention.
- Two Deno image tests passed: real PNG decode/resize/JPEG re-encode and unsafe input rejection. All three Edge Functions type-check.
- Live smoke checks passed for four anonymous table reads denied, three unauthenticated function calls denied, and non-university signup rejected. A later check found one confirmed live account; the owner reports receiving the Supabase verification email. Custom SMTP remains unapproved, and delivery for other students remains unverified. The checks create no verified accounts.
- Nine migrations applied to the real Mumbai Supabase project. Event reminders run every five minutes; the private push scheduler runs every minute, skipping empty/ineligible queues. Both jobs are active. Three Edge Functions are ACTIVE. Server push credentials are installed in Supabase secrets and Vault; anonymous and authenticated clients cannot execute the dispatcher. Authenticated worker smoke check returned HTTP 200 with zero deliveries.
- Supabase security advisor: zero ERROR findings; two reviewed WARN findings for intentionally exposed checked SECURITY DEFINER mutation functions.
- Android debug APK and web build passed. Flutter Doctor reports no issues. Native dependency warnings about future Kotlin/Java changes remain nonblocking.
- App launched in Student_Connect_API_36. Dart/Flutter MCP connected, hot restart succeeded, and runtime-error check reported none.
- Browser visually checked: real sign-in and registration screens render correctly; required-field validation works; connected build has no preview button.
- Firebase platform configuration and Android build plugins are installed. Android logs confirm a Crashlytics session starts successfully. Firebase billing remains disabled. Google Analytics linkage to property 553447807 was approved and its dashboard verified.
- Android Studio's existing main.dart run configuration was missing the build-time connection arguments. It now loads config/supabase.local.json; a shared Student Connect - Connected run configuration preserves the fix for other checkouts. Web port 5173 matches the configured authentication redirects.
- Release APK and Google Play app bundle build with a dedicated RSA-3072 signing key; apksigner verification passed (v2 signature, CN=Student Connect). Signing credentials are outside Git, and release builds no longer use the debug key. The release artifacts have not yet undergone authenticated acceptance testing or store publication.
- Full email verification/reset delivery, authenticated multi-user live flows, actual FCM device delivery and Crashlytics crash ingestion remain unverified. SMTP is still required for university onboarding. iOS build/signing and APNs setup require macOS/Xcode and Apple credentials.

## Latest functional recheck

- Web release published to https://student-connect-ppsu-2026.web.app/ with explicit owner approval. Its sign-in and registration screens render, and blank sign-in fields show validation errors. Supabase's default site URL and exact HTTPS sign-in/recovery redirects are installed, preserving local/mobile redirects and undeclared settings.
- Signup completion no longer notifies a disposed screen model; two regression tests pass. Analyzer is clean. The existing local DWDS debug session failed hot restart with a debugger JSON error; hosted-release checks were performed independently and do not claim that debug session restarted successfully.

- All seven Flutter tests, nine PostgreSQL security tests, two real image-processing tests, and eight live access checks passed again.
- The existing signed-in browser session loads the feed, communities, events, profile, saved posts and notifications. Empty states render for collections without content, and saved-post back navigation works. No user content was posted or deleted during these checks.

## 11 September 2026 rollout pass

- Added optional Cloudflare Turnstile token handling to registration, sign-in, verification resend, and password recovery. It remains disabled until the owner creates a Turnstile site and installs the matching private key in Supabase.
- Added an in-app pilot privacy/safety notice, a public `/privacy.html` notice, acceptable-use rules, reporting/appeal steps, a proposed retention period, and a repeatable two-student acceptance checklist.
- Corrected the deployed department name from “Institue of Computer Science” to “Institute of Computer Science” and verified the corrected text in the live app.
- Flutter analysis reports no issues; all nine Flutter tests, nine database security tests, and four backend validation tests pass.
- Rebuilt the signed Android APK and AAB successfully and published the latest web build. The deployed `main.dart.js` SHA-256 matches the local release artifact.
- Three verified users have completed profiles, but all remain students. Administrator assignment awaits the required permission-change confirmation.
- No Android device or device token is currently available, so physical FCM receipt and Crashlytics ingestion cannot yet be verified.
- Google Play opened at developer-account registration; an account purchase and identity verification are required before internal-track upload.
- Both event-reminder and push-dispatch cron jobs report their latest run succeeded.
- This verifies live navigation with one existing account, not fresh sign-up, email receipt, a second user's permissions or real device push delivery. Those acceptance checks remain separate.
