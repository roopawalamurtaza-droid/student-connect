/// Keeps short-lived, single-use verification tokens out of concurrent requests.
class CaptchaSession {
  String? _token;
  DateTime? _receivedAt;
  bool busy = false;

  void receive(String token, {DateTime? now}) {
    _token = token;
    _receivedAt = now ?? DateTime.now();
  }

  void clear() {
    _token = null;
    _receivedAt = null;
  }

  bool ready({DateTime? now}) =>
      _token != null &&
      _token!.isNotEmpty &&
      _receivedAt != null &&
      (now ?? DateTime.now()).difference(_receivedAt!) <
          const Duration(minutes: 5);

  Future<T> run<T>(
    Future<T> Function(String? token) request, {
    required bool required,
  }) async {
    if (busy) throw StateError('Please wait for the current request.');
    if (required && !ready()) {
      clear();
      throw StateError('Complete the security check and try again.');
    }
    final token = required ? _token : null;
    clear();
    busy = true;
    try {
      return await request(token);
    } finally {
      busy = false;
    }
  }
}
