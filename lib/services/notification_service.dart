import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../core/config.dart';
import '../repositories/campus_repository.dart';

class NotificationService {
  static bool get nativeSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  static StreamSubscription<String>? listen(CampusRepository repository) {
    if (repository.isPreview || !nativeSupported || Firebase.apps.isEmpty) {
      return null;
    }
    _restore(repository);
    return FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      try {
        await repository.mutate('saveToken', {'token': token});
      } catch (_) {
        debugPrint(
          'Device notification registration will retry on next launch.',
        );
      }
    });
  }

  static Future<void> _restore(CampusRepository repository) async {
    try {
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await repository.mutate('saveToken', {'token': token});
        }
      }
    } catch (_) {
      debugPrint('Device notification registration will retry on next launch.');
    }
  }

  static Future<void> enable(CampusRepository repository) async {
    if (Firebase.apps.isEmpty) {
      throw StateError(
        'Push notifications are not connected yet. Your in-app notifications are available.',
      );
    }
    if (repository.isPreview) {
      throw StateError(
        'Push notifications require your connected university account.',
      );
    }
    if (!nativeSupported) {
      throw StateError(
        'Browser push requires the deployment service worker. In-app notifications are available.',
      );
    }
    final permission = await FirebaseMessaging.instance.requestPermission();
    if (permission.authorizationStatus == AuthorizationStatus.denied) {
      throw StateError('Notifications were not allowed in device settings.');
    }
    final token = await FirebaseMessaging.instance.getToken(
      vapidKey: AppConfig.vapidKey.isEmpty ? null : AppConfig.vapidKey,
    );
    if (token == null) {
      throw StateError('This device could not register for notifications.');
    }
    await repository.mutate('saveToken', {'token': token});
  }

  static Future<void> unregister(CampusRepository repository) async {
    if (repository.isPreview || !nativeSupported || Firebase.apps.isEmpty) {
      return;
    }
    final token = await FirebaseMessaging.instance.getToken();
    try {
      if (token != null) {
        await repository.mutate('removeToken', {'token': token});
      }
    } finally {
      await FirebaseMessaging.instance.deleteToken();
    }
  }
}
