import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';

class SupabaseAuthService {
  SupabaseAuthService(this.client);
  final SupabaseClient client;
  Future<void> signIn(
    String email,
    String password, {
    String? captchaToken,
  }) async {
    await client.auth.signInWithPassword(
      email: email,
      password: password,
      captchaToken: captchaToken,
    );
  }

  Future<void> register(
    String email,
    String password, {
    String? captchaToken,
  }) async {
    await client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: AppConfig.authRedirect,
      captchaToken: captchaToken,
    );
  }

  Future<void> resend(String email, {String? captchaToken}) =>
      client.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: AppConfig.authRedirect,
        captchaToken: captchaToken,
      );
  Future<void> forgot(String email, {String? captchaToken}) =>
      client.auth.resetPasswordForEmail(
        email,
        redirectTo: AppConfig.passwordRedirect,
        captchaToken: captchaToken,
      );
  Future<void> reset(String password) async {
    await client.auth.updateUser(UserAttributes(password: password));
  }

  Future<void> signOut() => client.auth.signOut();
  Future<bool> signInWithProvider(OAuthProvider provider) =>
      client.auth.signInWithOAuth(provider, redirectTo: AppConfig.authRedirect);
}
