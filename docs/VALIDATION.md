# Validation — 9 September 2026

- Flutter 3.47.2 / Dart 3.13.2; strict analyzer clean.
- Seven Flutter tests passed: profile/post/report mapping, university domain matching, existing repository behavior, and mobile/desktop navigation/publishing layouts.
- Nine PostgreSQL/PGlite security tests passed: verification/domain gates, no role escalation, ownership, notifications, blocking, event permissions/registration privacy, suspension, private RPCs, draft media privacy, signup hook, administrator hierarchy and last-admin retention.
- Two Deno image tests passed: real PNG decode/resize/JPEG re-encode and unsafe input rejection. All three Edge Functions type-check.
- Live smoke checks passed for four anonymous table reads denied, three unauthenticated function calls denied, and non-university signup rejected. Live Auth user count remains zero; no fake verified accounts were created.
- Eight migrations applied to the real Mumbai Supabase project. The event reminder cron job is active every five minutes. Three Edge Functions are ACTIVE. Push delivery stays closed until credentials and scheduler are configured.
- Supabase security advisor: zero ERROR findings; two reviewed WARN findings for intentionally exposed checked SECURITY DEFINER mutation functions.
- Android debug APK and web build passed. Flutter Doctor reports no issues. Native dependency warnings about future Kotlin/Java changes remain nonblocking.
- App launched in Student_Connect_API_36. Dart/Flutter MCP connected, hot restart succeeded, and runtime-error check reported none.
- Browser visually checked: real sign-in and registration screens render correctly; required-field validation works; connected build has no preview button.
- Full email verification/reset delivery, authenticated multi-user live flows, FCM delivery and Crashlytics ingestion remain unverified until SMTP and Firebase authorization are supplied. iOS build/signing requires macOS/Xcode.
