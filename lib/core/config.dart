import 'package:flutter/foundation.dart';

class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static bool get supabaseEnabled =>
      supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
  static const allowPreview = bool.fromEnvironment('ENABLE_LOCAL_PREVIEW');
  static String get authRedirect => kIsWeb
      ? Uri.base.replace(path: '/', query: '', fragment: '').toString()
      : 'app.studentconnect://auth/callback';
  static const firebaseEnabled = bool.fromEnvironment('FIREBASE_ENABLED');
  static String get passwordRedirect =>
      Uri.parse(authRedirect)
          .replace(queryParameters: {'recovery': '1'})
          .toString();
  static const useEmulators = bool.fromEnvironment('USE_EMULATORS');
  static const emulatorHost = String.fromEnvironment(
    'EMULATOR_HOST',
    defaultValue: 'localhost',
  );
  static const emailDomains = String.fromEnvironment(
    'UNIVERSITY_EMAIL_DOMAINS',
    defaultValue: 'ppsu.ac.in',
  );
  static const recaptchaKey = String.fromEnvironment('RECAPTCHA_SITE_KEY');
  static const captchaBaseUrl = String.fromEnvironment(
    'CAPTCHA_BASE_URL',
    defaultValue: 'https://student-connect-ppsu-2026.web.app',
  );
  static const supportEmail = String.fromEnvironment('SUPPORT_EMAIL');
  static const vapidKey = String.fromEnvironment('FCM_VAPID_KEY');
  static bool isUniversityEmail(String email) =>
      emailDomains
          .split(',')
          .map((d) => d.trim().toLowerCase())
          .where((d) => d.isNotEmpty)
          .contains(email.trim().toLowerCase().split('@').last) &&
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.trim());
}
