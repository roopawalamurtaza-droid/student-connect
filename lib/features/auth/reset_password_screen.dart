import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';
import '../../repositories/auth_repository.dart';
import '../../widgets/common.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.onDone});
  final VoidCallback onDone;
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final password = TextEditingController(), confirm = TextEditingController();
  @override
  void dispose() {
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Choose a new password')),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: password,
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                decoration: const InputDecoration(labelText: 'New password'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirm,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                ),
              ),
              const SizedBox(height: 24),
              ActionButton(
                label: 'Update password',
                onPressed: () async {
                  if (password.text.length < 10) {
                    throw StateError('Use at least 10 characters.');
                  }
                  if (password.text != confirm.text) {
                    throw StateError('Passwords must match.');
                  }
                  await AuthRepository(
                    SupabaseAuthService(Supabase.instance.client),
                  ).reset(password.text);
                  await Supabase.instance.client.auth.signOut();
                  if (mounted) widget.onDone();
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
