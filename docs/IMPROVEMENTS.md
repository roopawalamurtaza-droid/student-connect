# Student Connect improvement backlog

## 1. Safer publishing — in progress
- [x] Keep a publishing lock across editor/tab changes.
- [x] Clear successful drafts even when the original editor has closed; preserve failed drafts.
- [x] Prevent edits and image changes during a submission.
- [x] Add a server-side idempotency key: retries of the same retained draft return the original result after a lost response. Private receipts are scoped to each account and survive post deletion.
- [x] Distinguish confirmed validation failures from an unknown publishing outcome; preserve the original payload for safe retries.
- [ ] Show image-upload progress.
- [x] Preview selected image attachments before publishing.
- [ ] Explain session-only draft retention beside the composer.

Retry protection applies while the session draft is retained. Reloading or signing out discards that draft; manually composing the same text again creates a new request. Future mutation migrations must preserve the public receipt wrapper and update the private `campus_mutate_without_receipt` implementation.

## 2. Better student discovery
- [x] Search names, skills, departments, and bio interests on the server before pagination.
- [x] Add My department and My semester filters with a clear reset action; exclude blocked/suspended profiles from discovery.
- [x] Show skills on student cards and make profile details scrollable on small screens.

## 3. Shareable links
- Current implementation focus: web links that retain their destination during sign-in, with unavailable-content handling.
- [x] Add web routes and copy-link controls for individual posts, events, and communities.
- [x] Preserve the requested route through the existing sign-in/profile gate and query content using normal visibility checks. Email verification callbacks use the approved home URL; return to the original shared-link tab to continue there.
- [ ] Verify browser back/forward, refresh, and Android deep links.

## 4. Personal campus feed
- [x] Filter to joined communities before pagination, combined with post search.
- [x] Preserve home feed scroll position, page, search, and filter when switching tabs during the session.
- [x] Add explicit feed refresh with loading/error states and guidance for an empty community feed.

## 5. Profile polish
- [ ] Display uploaded profile photos consistently with accessible initials fallback.
- [ ] Add profile-completion guidance without exposing private account details.
- [ ] Highlight skills and bio interests consistently in profile details to help students find teammates.

## 6. Event convenience
- [ ] Export calendar entries with correct timezone and event duration.
- [ ] Make registration status prominent and cancellation clear.
- [ ] Add student-controlled event reminder preferences.

## Release requirements carried forward
SMTP sender approval, two consenting student acceptance tests, physical Android CAPTCHA/push/crash checks, and Play testing remain separate rollout requirements. Completed work and verification belong in VALIDATION.md; unchecked items are not shipped features.

## 7. Campus opportunities board
- [ ] Dedicated listings for hackathon teams, project collaborators, competitions, and internships.
- [ ] Deadlines, open positions, and a positions-filled state.
- [ ] Reporting/moderation and visibility rules before rollout.

## 8. Lost-and-found
- [ ] Photos, campus location, date, and resolved status.
- [ ] A private response flow that does not publish phone numbers.
- [ ] Reporting and safe ownership verification.

## 9. Mobile polish and release alignment
- [ ] Review touch targets, dialogs, loading states, contrast, and keyboard/screen-reader use.
- [ ] Rebuild signed Android artifacts with the latest web features and complete physical-device acceptance.

All seven suggestions from the latest review are tracked above: sharing (3), profiles (5), events (6), opportunities (7), lost-and-found (8), posting (1), and mobile polish (9). Reliable email delivery and two-student acceptance remain rollout requirements.
