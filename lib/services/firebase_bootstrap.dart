import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../core/config.dart';

Future<void> initializeFirebase() async {
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
      appId: String.fromEnvironment('FIREBASE_APP_ID'),
      messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
      projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
      authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
      storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
      iosBundleId: 'app.studentconnect.studentConnect',
    ),
  );
  if (AppConfig.useEmulators) {
    await FirebaseAuth.instance.useAuthEmulator(AppConfig.emulatorHost, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(
      AppConfig.emulatorHost,
      8080,
    );
    FirebaseFunctions.instanceFor(region: 'asia-south1')
        .useFunctionsEmulator(AppConfig.emulatorHost, 5001);
    await FirebaseStorage.instance.useStorageEmulator(
      AppConfig.emulatorHost,
      9199,
    );
  }
  await FirebaseAppCheck.instance.activate(
    providerWeb: AppConfig.recaptchaKey.isEmpty
        ? null
        : ReCaptchaV3Provider(AppConfig.recaptchaKey),
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode
        ? const AppleDebugProvider()
        : const AppleAppAttestWithDeviceCheckFallbackProvider(),
  );
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android ||
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }
}
