# Student Connect campus policy pack

Status: pilot draft, prepared 10 September 2026. The university must approve the operator name, support contact, retention period and escalation contacts before a broad campus rollout.

## Privacy notice

Student Connect processes a verified university email address, profile details, user-created posts and comments, reactions, community memberships, event registrations, reports, blocks, personal notifications, and device notification tokens. These records are used to provide the campus community, protect accounts, moderate content, and deliver requested notifications.

Published profiles and posts are visible to authenticated campus members. Reports, block relationships, device tokens, and personal notifications are private. Authorized moderators may access reports and related content when investigating a complaint.

Supabase hosts authentication and application data. Firebase provides web hosting, diagnostics, analytics, and device messaging. Student Connect does not sell student data or allow advertisers to obtain individual student records.

Account data is retained while an account is active. Account deletion removes the profile, posts, comments, registrations, and uploaded media. De-identified moderation records and security logs may be retained for up to 24 months to investigate abuse and protect the service. The university should approve or replace this period before rollout.

Students can request access, correction, deletion, or support through the in-app account controls and the official support address. Set `SUPPORT_EMAIL` in production configuration before rollout.

## Acceptable-use rules

Members must use their own university identity and must not:

- harass, threaten, discriminate against, or impersonate another person;
- publish another person's private information without permission;
- post spam, scams, malware, unlawful content, or dangerous instructions;
- infringe copyright or other intellectual-property rights;
- bypass access controls, scrape private data, or disrupt the service;
- misuse event registrations, announcements, or administrator tools.

Moderators may remove content, suspend accounts, and preserve relevant records when these rules are violated. Serious or immediate threats should be escalated to university security or local emergency services.

## Reporting and appeal procedure

1. A member reports the relevant post or account in the app and supplies a short reason.
2. An authorized moderator reviews only the information needed to decide the case.
3. The moderator records the action and may dismiss the report, remove content, warn the member, or suspend an account.
4. The affected member may appeal through the official support contact.
5. An administrator reviews the appeal without relying only on the original moderator's decision.

Target response times for the pilot are one business day for safety threats and three business days for other reports. The university should supply an emergency contact and final response targets.

## Approval fields

- Service operator/legal name: **required**
- Official support email: **required**
- University safety/escalation contact: **required**
- Approved retention period: **required**
- Approval owner and date: **required**
