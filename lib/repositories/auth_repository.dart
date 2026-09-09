import '../services/auth_service.dart';

class AuthRepository {
  AuthRepository(this.service);
  final SupabaseAuthService service;
  Future<void> authenticate(
    String email,
    String password, {
    required bool register,
  }) => register
      ? service.register(email.trim().toLowerCase(), password)
      : service.signIn(email.trim().toLowerCase(), password);
  Future<void> resend(String email) =>
      service.resend(email.trim().toLowerCase());
  Future<void> forgot(String email) =>
      service.forgot(email.trim().toLowerCase());
  Future<void> reset(String password) => service.reset(password);
}
