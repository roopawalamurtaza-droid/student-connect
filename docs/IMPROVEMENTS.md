# Student Connect improvement backlog

## 1. Safer publishing — in progress
- [x] Keep a publishing lock across editor/tab changes.
- [x] Clear successful drafts even when the original editor has closed; preserve failed drafts.
- [x] Prevent edits and image changes during a submission.
- [x] Add a server-side idempotency key: retries of the same retained draft return the original result after a lost response. Private receipts are scoped to each account and survive post deletion.
- [x] Distinguish confirmed validation failures from an unknown publishing outcome; preserve the original payload for safe retries.
- [ ] Show image-upload progress.

Retry protection applies while the session draft is retained. Reloading or signing out discards that draft; manually composing the same text again creates a new request. Future mutation migrations must preserve the public receipt wrapper and update the private `campus_mutate_without_receipt` implementation.

## 2. Better student discovery
- [x] Search names, skills, departments, and bio interests on the server before pagination.
- [x] Add My department and My semester filters with a clear reset action; exclude blocked/suspended profiles from discovery.
- [x] Show skills on student cards and make profile details scrollable on small screens.

## 3. Shareable links
- [ ] Add routes for individual posts, events, and communities.
- [ ] Preserve destination through sign-in and honor normal visibility checks.
- [ ] Verify browser back/forward, refresh, and Android deep links.

## 4. Personal campus feed
- [ ] Filter to joined communities.
- [ ] Preserve scroll position and search when switching tabs.
- [ ] Add explicit refresh and informative loading states.

## 5. Profile polish
- [ ] Display uploaded profile photos consistently with accessible initials fallback.
- [ ] Add profile-completion guidance without exposing private account details.

## 6. Event convenience
- [ ] Export calendar entries with correct timezone and event duration.
- [ ] Make registration status prominent and cancellation clear.

## Release requirements carried forward
SMTP sender approval, two consenting student acceptance tests, physical Android CAPTCHA/push/crash checks, and Play testing remain separate rollout requirements. Completed work and verification belong in VALIDATION.md; unchecked items are not shipped features.
