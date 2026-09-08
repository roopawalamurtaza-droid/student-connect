class AppConfig {
  static const firebaseEnabled = bool.fromEnvironment('FIREBASE_ENABLED');
  static const useEmulators = bool.fromEnvironment('USE_EMULATORS');
  static const emulatorHost = String.fromEnvironment(
    'EMULATOR_HOST',
    defaultValue: 'localhost',
  );
  static const emailDomains = String.fromEnvironment(
    'UNIVERSITY_EMAIL_DOMAINS',
  );
  static const recaptchaKey = String.fromEnvironment('RECAPTCHA_SITE_KEY');
  static const vapidKey = String.fromEnvironment('FCM_VAPID_KEY');
  static bool isUniversityEmail(String email) =>
      emailDomains
          .split(',')
          .map((d) => d.trim().toLowerCase())
          .where((d) => d.isNotEmpty)
          .contains(email.trim().toLowerCase().split('@').last) &&
      email.contains('@');
}
