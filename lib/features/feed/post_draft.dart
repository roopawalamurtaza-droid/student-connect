
import 'package:flutter/foundation.dart';

/// Session-only draft and submission lock shared across editor instances.
class PostDraft extends ChangeNotifier {
  String body = '';
  Uint8List? image;
  bool publishing = false;

  void clear() {
    body = '';
    image = null;
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
