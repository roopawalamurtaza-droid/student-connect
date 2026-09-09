import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';

class SupabaseAuthService {
  SupabaseAuthService(this.client);
  final SupabaseClient client;
  Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> register(String email, String password) async {
    await client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: AppConfig.authRedirect,
    );
  }

  Future<void> resend(String email) => client.auth.resend(
    type: OtpType.signup,
    email: email,
    emailRedirectTo: AppConfig.authRedirect,
  );
  Future<void> forgot(String email) => client.auth.resetPasswordForEmail(
    email,
    redirectTo: AppConfig.passwordRedirect,
  );
  Future<void> reset(String password) async {
    await client.auth.updateUser(UserAttributes(password: password));
  }

  Future<void> signOut() => client.auth.signOut();
  Future<bool> signInWithProvider(OAuthProvider provider) =>
      client.auth.signInWithOAuth(provider, redirectTo: AppConfig.authRedirect);
}
