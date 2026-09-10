# Campus acceptance test

Use two consenting, verified `@ppsu.ac.in` accounts on separate devices. Do not use shared passwords or production administrator credentials.

## Identity and account lifecycle

- Register both accounts and complete the CAPTCHA.
- Confirm both verification emails and finish both profiles.
- Sign out and sign back in on each device.
- Request a password reset and confirm the old password no longer works.
- Delete the second test account and confirm its profile and uploaded media are unavailable.

## Campus interaction

- Account A creates a post. Account B likes, saves, and comments on it.
- Confirm Account A receives only its own notification and Account B can reopen the saved post.
- Account A creates a community, club, event, and announcement after receiving the appropriate administrator role.
- Account B joins the community and registers for the event.

## Safety and privacy

- Account B reports Account A's test post; verify a moderator can review and resolve it.
- Account B blocks Account A; verify blocked content disappears as designed.
- Confirm neither account can read the other's private notifications, saved posts, blocks, or device tokens.
- Confirm a normal student cannot assign roles or open administrator actions.

## Device services

- Install the signed Android build on a physical phone and enable device notifications in the account menu.
- Trigger a permitted notification and confirm it arrives without exposing private content on the lock screen.
- From a development-only build, send one controlled Crashlytics test error and verify it appears in Firebase. Remove the trigger before release.

Record the tester, device, date, result, and issue link for every failed check. All failures affecting identity, privacy, moderation, deletion, or recovery block wider rollout.
