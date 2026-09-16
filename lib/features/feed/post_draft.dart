import 'dart:math';

import 'package:flutter/foundation.dart';

/// Session-only draft and submission lock shared across editor instances.
class PostDraft extends ChangeNotifier {
  String body = '';
  Uint8List? image;
  bool publishing = false;
  String requestId = _newRequestId();
  Map<String, dynamic>? pendingPost;

  static String _newRequestId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  void clear() {
    body = '';
    image = null;
    pendingPost = null;
    requestId = _newRequestId();
  }

  Future<void> submit(Future<void> Function() publish) async {
    if (publishing) throw StateError('Your post is already being published.');
    publishing = true;
    notifyListeners();
    try {
      await publish();
      clear();
    } finally {
      publishing = false;
      notifyListeners();
    }
  }
}
