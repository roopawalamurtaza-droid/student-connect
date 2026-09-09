import 'package:flutter/foundation.dart';

import '../../repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this.repository);
  final AuthRepository repository;
  String? pendingEmail;
  Future<void> authenticate(
    String email,
    String password, {
    required bool register,
  }) async {
    await repository.authenticate(email, password, register: register);
    if (register) {
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
