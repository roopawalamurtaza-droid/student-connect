# Student Connect improvement backlog

## 1. Safer publishing — in progress
- [x] Keep a publishing lock across editor/tab changes.
- [x] Clear successful drafts even when the original editor has closed; preserve failed drafts.
- [x] Prevent edits and image changes during a submission.
- [ ] Add a server-side idempotency key so retrying after a lost response cannot create another post. Requires database migration and security tests before deployment.
- [ ] Show upload progress and distinguish a confirmed failure from an unknown outcome.

## 2. Better student discovery
- [ ] Search skills, departments, and interests with server-side filters before pagination.
- [ ] Add useful filters and clear reset controls, keeping blocked/suspended profiles excluded.

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
