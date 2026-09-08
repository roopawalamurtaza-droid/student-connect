# Connect Student Connect to Firebase

No Firebase project, university email domain, cloud deployment, or real user account was created during this task. The app runs in a clearly labeled local preview until these steps are completed.

## 1. Create and register the project

Create a project in the Firebase console under your account. Select the appropriate billing plan for Cloud Functions, Storage, and scheduled reminders. Choose a Firestore/Storage location suitable for your university; the callable functions are currently configured in `asia-south1` (Mumbai).

Enable Email/Password Authentication, create Firestore in production mode, and create a Storage bucket. Add your deployed website to Authentication's authorized domains. Configure email templates and a minimum password policy of at least 10 characters. Registration in the application also enforces this minimum.

The command-line tools are installed:

```powershell
cd C:\Flutter\student_connect
firebase login
flutterfire configure --project YOUR_PROJECT_ID --platforms android,ios,web
```

Use the existing package/bundle IDs from the platform projects. Android is `app.studentconnect.student_connect`; verify the iOS bundle identifier in Xcode before registration. The CLI registers platform apps and writes their native configuration. Firebase client configuration values are public application identifiers, not administrative secrets. Never place service-account private keys or server credentials in Dart, web assets, or build defines.

This code uses build-time configuration, so generating `firebase_options.dart` alone does not enable it. Copy `config/firebase.example.json` to a platform-specific local file such as `config/firebase.web.json` or `config/firebase.android.json`, then replace every example value with that platform's Firebase app settings. `FIREBASE_APP_ID` and the API key may differ by platform. Keep the actual bucket name from the Firebase console.

## 2. University enrollment policy

Get approval for the exact university email domains; do not guess them. Enter the same comma-separated allowlist in:

- `UNIVERSITY_EMAIL_DOMAINS` in the Flutter configuration file.
- `backend/functions/.env.YOUR_PROJECT_ID` on the server side.

Example shape only:

```dotenv
UNIVERSITY_EMAIL_DOMAINS=students.your-university.edu,your-university.edu
```

Only exact email domains are accepted. Users must verify email before the backend creates a campus profile. The Firebase Auth service may initially contain an unverified account, but it has no campus database access.

## 3. App Check and native monitoring

Register the Android app with Play Integrity and the iOS app with App Attest/DeviceCheck. For local native debugging, register the Firebase App Check debug token printed by the official SDK in your Firebase project. Never add debug tokens to a production build.

Register the web app with reCAPTCHA v3 and set `RECAPTCHA_SITE_KEY` to its public site key. Include your development and production web hosts in the registration. The backend always enforces App Check for deployed callable requests. Configure enforcement for Firestore/Storage through Firebase after validating the registered platforms.

Run FlutterFire configuration again after enabling native Crashlytics to add the platform-specific Gradle/Xcode setup. Verify a deliberate test crash in a development build before relying on reporting. Review Analytics and Crashlytics collection settings for your university's policy. Screen events are wired only in connected mode.

## 4. Deploy services and run connected mode

Review the generated native changes, then deploy using your project ID:

```powershell
cd C:\Flutter\student_connect\backend\functions
$env:Path = 'C:\Flutter\tools\node-v22.23.2-win-x64;' + $env:Path
npm ci
cd C:\Flutter\student_connect
firebase deploy --project YOUR_PROJECT_ID --only "functions,firestore,storage"
flutter run -d chrome --dart-define-from-file=config/firebase.web.json
```

On first sign-in: register with an approved domain, verify email, press **I've verified my email**, and complete the profile. The first profile is always created with the `student` role. Use the trusted Firebase console to assign `administrator` to the intended verified account's `users/UID` document. Thereafter, the in-app administrator can manage other users. The client cannot promote itself.

Verify registration, email verification, password reset, sign-out/session persistence, denied unauthorized writes, an actual upload, and App Check on each live platform before launch.

Build and deploy the connected web app:

```powershell
flutter build web --dart-define-from-file=config/firebase.web.json
firebase deploy --project YOUR_PROJECT_ID --only hosting
```

A default `flutter build web` creates the local preview build. Use the connected configuration explicitly when preparing a real deployment.

## 5. Device notifications and iOS

For Android, verify FCM on a Google Play-capable emulator or a real device. In the app's account menu, choose **Enable device notifications**. Device tokens are stored through the server API and refreshed while the session is active. Registration for events enables persistent in-app reminders; opted-in mobile devices also receive a push reminder. Like/comment updates are in-app.

For iOS, use a Mac with Xcode, a signing team, and the intended bundle ID. Add Push Notifications and Background Modes/Remote notifications capabilities, and upload the APNs authentication key in Firebase. Configure App Check and Crashlytics through FlutterFire/Xcode, then test on a physical device. Photo-library usage text is already present. iOS binaries were not built on Windows.

Browser push needs a deployment-specific `firebase-messaging-sw.js`, Firebase initialization inside that worker, its scope/registration, and the public VAPID key. It is deliberately not presented as working until that setup is implemented and tested. The app currently shows a clear message when browser push is selected. Personal in-app notifications and announcements do not require a service worker.

## 6. Android release

The verified APK is a debug build. Before distributing through Play, choose final package identifiers, configure your release keystore and Gradle signing, configure the Firebase native apps/attestation, and build a signed app bundle. The generated release configuration still references a development signing key; do not treat it as a production release.

## Local backend tests without a cloud project

```powershell
cd C:\Flutter\student_connect\backend\functions
$env:Path = 'C:\Flutter\tools\node-v22.23.2-win-x64;C:\Program Files\Android\Android Studio\jbr\bin;C:\Flutter\tools\node_modules\.bin;' + $env:Path
npm test
firebase emulators:exec --project demo-student-connect --config ../../firebase.json --only "firestore,auth,storage" "node --test test/rules.integration.js test/api.integration.js"
```

The `demo-` project cannot reach real Firebase services. The automated API tests invoke the handler directly and use only emulated services. They bypass the HTTP App Check wrapper, so production attestation still needs live validation. The example domain used by those tests is test-only and does not authorize live enrollment.

Official references: [Firebase Flutter setup](https://firebase.google.com/docs/flutter/setup), [Flutter Android setup](https://docs.flutter.dev/platform-integration/android/setup).
