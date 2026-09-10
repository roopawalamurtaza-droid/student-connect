import 'package:flutter/foundation.dart';

import '../../repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this.repository);
  final AuthRepository repository;
  String? pendingEmail;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> authenticate(
    String email,
    String password, {
    required bool register,
  }) async {
    await repository.authenticate(email, password, register: register);
    if (register && !_disposed) {
      pendingEmail = email.trim();
      notifyListeners();
    }
  }

  void backToSignIn() {
    pendingEmail = null;
    notifyListeners();
  }

  Future<void> resend() => repository.resend(pendingEmail!);
  Future<void> forgot(String email) => repository.forgot(email);
  Future<void> reset(String password) => repository.reset(password);
}
