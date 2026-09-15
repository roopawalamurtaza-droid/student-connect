# Student Connect release setup

## Android packages

Run `scripts/build-release.ps1` on this Windows account to build a signed APK and Google Play app bundle. The script loads the signing password from a Windows-protected file into the build process and clears its environment variables afterward. Release builds never fall back to the debug signing key.

Local signing material is outside the repository:

- `C:/Flutter/setup/student-connect-upload.jks`
- `C:/Flutter/setup/student-connect-signing-password.clixml`

Keep a secure backup of the keystore and its password before distributing releases. The encrypted password file depends on this Windows account and machine; copying that file alone to another computer is not a portable backup. Never commit either credential or upload them with the application source.

Outputs:

- `build/app/outputs/flutter-apk/app-release.apk`
- `build/app/outputs/bundle/release/app-release.aab`

Google Play account setup and publication remain separate. An APK signed with the release key cannot update an existing debug-signed installation; use a separate test device or explicitly remove the debug installation after preserving any needed local data.

## Verification email sender

Resend setup requires an account, a domain you control, and its DNS verification records. The proposed sender subdomain is `auth.<your-domain>`; the university login restriction remains `ppsu.ac.in`. A domain used to send email does not grant students from that domain access to the app.

After verifying the domain, configure Supabase Authentication → Email → SMTP:

| Setting | Value |
| --- | --- |
| Host | smtp.resend.com |
| Port | 465 |
| Username | resend |
| Password | Resend sending API key, entered only in Supabase |
| Sender name | Student Connect |
| Sender address | noreply@auth.<your-domain> |

Keep link tracking disabled for authentication messages. Preserve email confirmation, the university signup hook and all existing redirect URLs. Add exact production HTTPS redirects when web hosting is selected. Do not use a test sender to claim real university email delivery works.

References: [Resend with Supabase](https://resend.com/docs/send-with-supabase-smtp), [verified domains](https://resend.com/docs/dashboard/domains/introduction).

## Acceptance checks before student rollout

Use an authorized real university account to verify signup, confirmation, onboarding, logout/login, password recovery and account deletion. Use two verified accounts to test interactions and notification privacy. Verify push receipt on a device with permission enabled, plus a Crashlytics test report and Analytics event ingestion. Assign the first administrator only to the approved verified account. iOS signing and APNs still require Apple credentials and Xcode.

Follow the repeatable checklist in [ACCEPTANCE_TEST.md](ACCEPTANCE_TEST.md). The draft privacy, acceptable-use, reporting, and retention terms are in [CAMPUS_POLICIES.md](CAMPUS_POLICIES.md); complete its approval fields before broad rollout.

## CAPTCHA

The hosted pilot now has Turnstile enforcement enabled and verified. See [CAPTCHA.md](CAPTCHA.md) for the current rollout state and rotation instructions. Old APKs without the site key must be replaced with the refreshed build.

Student Connect is wired for Cloudflare Turnstile on registration, sign-in, resend, and password reset. Create a Turnstile widget for the production web domain and the configured native `CAPTCHA_BASE_URL`, add its public site key as `RECAPTCHA_SITE_KEY`, then enable Turnstile under Supabase Authentication → Attack Protection using the matching secret key. Enable backend enforcement only after a build containing the public key has been deployed, or authentication will stop working.
