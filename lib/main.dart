import 'package:flutter/material.dart';

import 'app/student_connect_app.dart';
import 'core/config.dart';
import 'services/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? startupError;
  if (AppConfig.firebaseEnabled) {
    try {
      await initializeFirebase();
    } catch (_) {
      startupError = 'Student Connect could not connect. Check your network or contact your university support team.';
    }
  }
  runApp(StudentConnectApp(startupError: startupError));
}
