# Student Connect CAPTCHA

Cloudflare Turnstile managed widget is configured for the production `student-connect-ppsu-2026.web.app`, alternate `student-connect-ppsu-2026.firebaseapp.com`, and `localhost` hostnames. No pre-clearance is enabled. Supabase Auth uses Turnstile with the matching secret in its server-side authentication settings.

The public site key belongs in `RECAPTCHA_SITE_KEY` in ignored `config/supabase.local.json` (legacy variable name). The secret must never be added to Flutter, Git, or Firebase Hosting. Obtain or rotate it through the owner's Cloudflare dashboard, then update Supabase Auth > Attack Protection.

Web uses the official Turnstile script directly, with Dart JS interop and a real attached DOM container. The old package's srcdoc web frame failed on the live site and is no longer used on web. Native builds retain the WebView implementation using the production HTTPS base URL. Physical Android challenge completion remains to be checked.

Each token is consumed once, expires after five minutes, and is cleared on errors/expiry. Authentication actions share a request lock. Each completed request creates a fresh challenge; disposed screens do not refresh widgets. Compact challenge sizing is used under 300 logical pixels of available width.

## Deployment order

1. Build and publish clients with the real site key.
2. Verify live challenge completion.
3. Enable the matching provider and secret in Supabase.
4. Confirm a request without a token is rejected as `captcha_failed`.
5. Confirm a valid challenge reaches ordinary credential validation using a nonexistent account, without creating users or sending email.

Older Android builds without the site key cannot perform protected authentication. Install the refreshed signed APK before testing. SMTP delivery limits are independent of CAPTCHA and still require an approved sender.

## Verified 16 September 2026

- Live challenge shows Success.
- Missing token rejected by Supabase with `captcha_failed`.
- Browser-submitted valid token reaches `invalid_credentials` for a nonexistent test account; challenge refreshes successfully afterward.
- No student accounts or content created or deleted during these checks.
