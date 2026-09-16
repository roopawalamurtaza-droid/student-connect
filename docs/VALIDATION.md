# Validation

## Release 1.1.0 — event planning and profile polish

- Calendar export creates an `.ics` file containing the event title, location, description, campus link, UTC start time, and user-chosen time reservation. Since the data model has no organizer end time, both the dialog and file explicitly state this limitation. Users may include a 30-minute calendar alarm; this is separate from in-app reminder preferences and registration.
- Event cards now present explicit registration status and confirm cancellation. Registration controls close at the scheduled start time. Calendar copies are static and cancellation guidance explains that saved calendar entries must be removed separately.
- Calendar encoding follows [RFC 5545](https://www.rfc-editor.org/rfc/rfc5545): stable UID, escaped text, CRLF separators, UTF-8-safe 75-octet folding, and UTC date/time values. File export uses the [share_plus platform integration](https://pub.dev/packages/share_plus) with a browser download fallback. Export does not claim to have imported an event into a calendar.
- Added automated checks for timezone conversion, reserved duration, text escaping/Unicode folding, optional alarms, calendar dialog controls at 320/1440 pixels, and registration/cancellation choices. Source version is 1.1.0+2 for upgrade ordering on Android.
- All 37 Flutter tests pass and the analyzer is clean. Version 1.1.0 web is published to Firebase Hosting and the hosted JavaScript SHA-256 matches the build. No database migration was required.
- Signed Android APK (57.7 MB) and app bundle (56.5 MB) rebuilt successfully with the existing release key. APK signature verification passes (v2, RSA-3072, CN=Student Connect); package inspection confirms versionName 1.1.0 and versionCode 2. Existing future Kotlin/Java compatibility warnings remain nonblocking.
- No phone or emulator was connected during the release check. Actual calendar import/share behavior and photo selection on a phone remain unverified; the native app-link, push/crash, and two-student acceptance requirements are still open.

## Profile photos and completion guidance

- Shared avatars load through the existing authenticated media repository in the workspace, profile/editor, student directory/details, posts (including saved/community posts), and comments. Loading, missing, or failed photos retain initials; changed requests cannot display a stale result. Initials use Unicode grapheme boundaries and avatars include a name-based accessibility label.
- Added an optional photo/bio/skills checklist that scrolls to the photo control or focuses the relevant field. Bio and skills progress reflects current edits with an explicit save reminder; photos save immediately. Background photo refresh preserves unsaved text. Saved bio and skills are visible on the profile header card.
- All 33 Flutter tests pass with a clean analyzer. New tests cover successful/failed/stale avatar loads, completion guidance/focus/save at 320 and 1440 pixels, and preservation of edits during profile refresh; author mapping includes avatar paths. No database migration or permission changes are needed.
- Physical-device photo selection and live multi-student acceptance remain pending; automated checks use local test images and the preview repository. Android binaries are not rebuilt in this web increment.
- The profile web release is now published on Firebase Hosting; hosted JavaScript SHA-256 matches the tested build.

## Shareable web content links

- Added path-based web routes for posts, events, and communities with copy-link actions, an unavailable-content state, and a return-home action. The session gate retains the route while signing in or completing a profile. Content reads filter by ID under existing row policies.
- Email verification and password-recovery callbacks continue to use the approved root URL. Following an email callback in a separate tab does not carry the shared destination; the original shared-link tab retains it.
- All 30 Flutter tests pass and the analyzer is clean. Tests cover supported/invalid link parsing, all three destinations through preview-session entry, unavailable IDs, route changes, return home, and existing navigation/publishing behavior. These do not substitute for live university-account verification/email acceptance.
- Native Android App Links, physical-device validation, and dedicated browser back/forward acceptance remain pending. No Android binary is rebuilt in this web increment.
- Web release published to Firebase Hosting. Hosted JavaScript SHA-256 matches the local build; direct HTTP requests for all three content paths return the Flutter shell successfully, confirming refresh/deep URL hosting rewrites.

## Personal campus feed

- Added All campus/My communities controls and explicit Refresh feed. Membership and post-text filters are sent together before pagination using existing relationships and row policies; no database migration is required.
- Home remains mounted while another workspace tab is shown, retaining search, filter, loaded page, and scroll position. Session exit still clears this state. Other tabs retain their existing lifecycle.
- All 26 Flutter tests pass. New checks cover the transport membership/search/pagination request and community filtering, refresh, and search/scroll retention across navigation. Existing mobile/desktop navigation and publishing tests also pass.
- Analyzer clean; web release published to Firebase Hosting and hosted JavaScript SHA-256 matches the build. Android binaries are unchanged. Live authenticated multi-student acceptance remains separate from these automated checks.

## 16 September 2026 student discovery

- Discovery searches name, department, skills, and bio interests before pagination; My department/My semester filters combine with search. Matches use literal case-insensitive substrings, including punctuation, and stable name/ID ordering.
- New invoker-rights search RPC retains row policies and explicitly excludes blocked/suspended profiles. The administrator directory keeps its existing query and moderation visibility.
- Student cards show up to three skills; profile dialogs scroll on small screens. Clear search resets text and both filters.
- All 24 Flutter tests and 12 database tests pass, with a clean analyzer. New widget tests cover skills, combined filters, empty states, and reset at 320/1440 pixels; SQL tests cover pagination, literal search, domain access, blocking, and suspension.
- Migration `202609160002_student_discovery.sql` applied to production and the web release published to Firebase Hosting. Hosted `main.dart.js` matches the local release by SHA-256. Android binaries have not been rebuilt for this update; authenticated live student acceptance remains pending.

## 16 September 2026 publishing receipts

- Server receipts prevent repeated create-post requests for the same account/request key, including retries after the post has been deleted. Concurrent requests with that key serialize in the database transaction.
- Client retains the request key and frozen payload after an unknown outcome; confirmed validation/permission failures allow correction. A successful result clears the draft and rotates the key. Drafts remain session-only.
- All 22 Flutter tests and 11 PostgreSQL/PGlite security tests pass; Flutter analyzer reports no issues. Tests cover key retention/rotation, receipt isolation, private-function denial, deletion replay, suspended accounts, and transaction failure recovery. Physical network-disconnection testing with two live students remains pending.
- Migration `202609160001_post_idempotency.sql` applied to production; subsequent dry run reports no pending migrations. Web release deployed to Firebase Hosting, and hosted `main.dart.js` SHA-256 matches the local release. Existing Android binaries have not been rebuilt for this update.

## Publishing reliability, first increment

- Session draft now owns a publishing lock across editor instances. Successful submission clears the draft even after the original editor stops listening; failure preserves text and image.
- Text/image controls are disabled while submitting, and publishing waits until image selection completes.
- Analyzer clean; all 21 Flutter tests pass. Three new tests cover overlapping submissions, failure recovery, and completion after the editor stops listening.
- This first increment was subsequently extended with server receipts described above.

## Campus dashboard update

- Replaced the oversized home welcome section with a campus dashboard, responsive shortcuts, expandable announcements, and upcoming events visible on mobile and desktop.
- Home post search uses the existing server-side query filtering. Added unread notification filtering, a live unread badge, and a bulk action explicitly limited to loaded updates.
- New-post drafts (text and selected image) survive navigation within the signed-in workspace and clear after publishing or leaving that workspace. Drafts are not written to persistent shared-device storage.
- All 18 Flutter tests pass and the analyzer is clean, including small-screen dashboard search, draft navigation/publishing, and notification filter/badge/bulk-read agreement. Authenticated multi-student live acceptance remains separate.

## 16 September 2026 CAPTCHA and usability update

- Cloudflare Turnstile created and Supabase Auth protection enabled. Live missing-token request is rejected with `captcha_failed`; a real browser token reaches ordinary credential validation for a nonexistent account. No account was created and no email was sent by this check.
- Replaced the broken package web iframe with direct official-script rendering. Live normal and compact widgets both show Success, including a 320-pixel viewport. Native challenge completion still needs a physical-device check.
- Authentication now consumes tokens once, expires them, prevents overlapping actions, regenerates challenges after requests, and offers recovery from load errors. Verification remains enforced by Supabase, independent of Flutter validation.
- Published searchable events, upcoming/past filters, own-registration filtering, and event detail copying. Server-side filters run before pagination; registration visibility continues to use existing RLS.
- Improved form boundaries/focus, secondary password-recovery action, smaller-window layout, understandable auth errors, and retry controls for failed data loads.
- Flutter analyzer is clean. All 15 Flutter tests and nine database security tests pass. New tests cover expired/used tokens, concurrent requests, search and own event plans at 320 and 1440 pixel widths.
- Firebase Hosting sends revalidation headers to reduce stale client caching. Rebuilt clients must be used for protected authentication; old APKs without the site key cannot sign in.
- Fresh two-student acceptance, SMTP delivery, physical push receipt, Crashlytics ingestion, and Play testing remain unverified external rollout requirements.

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
- Three verified users have completed profiles. The approved owner profile is now the first `super_admin`; Supabase persistence and the live Administration menu were both verified.
- No Android device or device token is currently available, so physical FCM receipt and Crashlytics ingestion cannot yet be verified.
- Google Play opened at developer-account registration; an account purchase and identity verification are required before internal-track upload.
- Both event-reminder and push-dispatch cron jobs report their latest run succeeded.
- This verifies live navigation with one existing account, not fresh sign-up, email receipt, a second user's permissions or real device push delivery. Those acceptance checks remain separate.
