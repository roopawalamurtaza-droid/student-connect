import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/student_connect_app.dart';
import 'core/config.dart';
import 'services/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? startupError;
  final initialUri = kIsWeb ? Uri.base : await AppLinks().getInitialLink();
  final recovery = initialUri?.queryParameters['recovery'] == '1';
  if (AppConfig.supabaseEnabled) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabaseKey,
      );
    } catch (_) {
      startupError = 'Student Connect could not connect. Please reopen the app and try again.';
    }
  }
  if (AppConfig.firebaseEnabled) {
    try {
      await initializeFirebase();
    } catch (_) {
      debugPrint('Optional Firebase services could not start.');
    }
  }
  runApp(
    StudentConnectApp(startupError: startupError, initialRecovery: recovery),
  );
}
