import '../services/auth_service.dart';

class AuthRepository {
  AuthRepository(this.service);
  final SupabaseAuthService service;
  Future<void> authenticate(
    String email,
    String password, {
    required bool register,
    String? captchaToken,
  }) => register
      ? service.register(
          email.trim().toLowerCase(),
          password,
          captchaToken: captchaToken,
        )
      : service.signIn(
          email.trim().toLowerCase(),
          password,
          captchaToken: captchaToken,
        );
  Future<void> resend(String email, {String? captchaToken}) =>
      service.resend(email.trim().toLowerCase(), captchaToken: captchaToken);
  Future<void> forgot(String email, {String? captchaToken}) =>
      service.forgot(email.trim().toLowerCase(), captchaToken: captchaToken);
  Future<void> reset(String password) => service.reset(password);
}
