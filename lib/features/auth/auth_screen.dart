import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../repositories/auth_repository.dart';
import '../../services/auth_service.dart';
import 'auth_view_model.dart';
import 'captcha_session.dart';
import 'security_challenge.dart';

import '../../core/config.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../profile/legal_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    this.onPreview,
    required this.onTheme,
    this.error,
  });
  final VoidCallback? onPreview;
  final VoidCallback onTheme;
  final String? error;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final email = TextEditingController(), password = TextEditingController();
  final form = GlobalKey<FormState>();
  late final AuthViewModel? model = AppConfig.supabaseEnabled
      ? AuthViewModel(
          AuthRepository(SupabaseAuthService(Supabase.instance.client)),
        )
      : null;
  int captchaGeneration = 0;
  final challenge = CaptchaSession();
  String? captchaError;
  @override
  void initState() {
    super.initState();
    model?.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  bool register = false, hidden = true;
  @override
  void dispose() {
    model?.removeListener(_changed);
    model?.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> authenticate() async {
    if (!form.currentState!.validate()) return;
    await _withCaptcha(
      (token) => model!.authenticate(
        email.text,
        password.text,
        register: register,
        captchaToken: token,
      ),
    );
  }

  Future<T> _withCaptcha<T>(Future<T> Function(String? token) request) async {
    if (challenge.busy) {
      throw StateError('Please wait for the current request.');
    }
    final required = AppConfig.recaptchaKey.isNotEmpty;
    if (required && !challenge.ready()) {
      throw StateError('Complete the security check below and try again.');
    }
    final result = challenge.run(request, required: required);
    setState(() {});
    try {
      return await result;
    } finally {
      if (mounted) {
        setState(() {});
        if (required) await _refreshCaptcha();
      }
    }
  }

  Future<void> _refreshCaptcha() async {
    challenge.clear();
    if (mounted) {
      setState(() {
        captchaGeneration++;
        captchaError = null;
      });
    }
  }

  Widget _securityCheck() {
    if (AppConfig.recaptchaKey.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 300;
          return Column(
            children: [
              Semantics(
                label: 'Security verification',
                child: Center(
                  child: SecurityChallenge(
                    key: ValueKey((
                      compact,
                      Theme.of(context).brightness,
                      captchaGeneration,
                    )),
                    compact: compact,
                    onToken: (token) {
                      if (mounted) {
                        setState(() {
                          challenge.receive(token);
                          captchaError = null;
                        });
                      }
                    },
                    onExpired: () {
                      if (mounted) {
                        setState(() {
                          challenge.clear();
                          captchaError =
                              'Security check expired. Please try it again.';
                        });
                      }
                    },
                    onError: () {
                      if (mounted) {
                        setState(() {
                          challenge.clear();
                          captchaError = 'Security check could not load. Check your connection and try again.';
                        });
                      }
                    },
                  ),
                ),
              ),
              if (captchaError != null) ...[
                const SizedBox(height: 8),
                Text(
                  captchaError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                TextButton(
                  onPressed: challenge.busy ? null : _refreshCaptcha,
                  child: const Text('Retry security check'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connected = AppConfig.supabaseEnabled && widget.error == null;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, size) => Row(
            children: [
              if (size.maxWidth >= 950 && size.maxHeight >= 700)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(48),
                    decoration: BoxDecoration(
                      color: AppTheme.navy,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.hub_rounded,
                              color: AppTheme.green,
                              size: 34,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'student connect',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Text(
                          'Your campus.\nYour people.\nYour next chapter.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 52,
                            height: 1.1,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -2,
                          ),
                        ),
                        const SizedBox(height: 26),
                        const Text(
                          'A place for the ideas, communities, and connections\nthat make student life yours.',
                          style: TextStyle(
                            color: Color(0xFFD1DDCB),
                            fontSize: 17,
                            height: 1.7,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children:
                              [
                                    'Find your people',
                                    'Share your ideas',
                                    'Make things happen',
                                  ]
                                  .map(
                                    (s) => Chip(
                                      label: Text(s),
                                      backgroundColor: AppTheme.green,
                                      side: BorderSide.none,
                                    ),
                                  )
                                  .toList(),
                        ),
                        const Spacer(),
                        const Text(
                          'A LITTLE MORE CONNECTED.',
                          style: TextStyle(
                            color: Color(0xFFC7D5C8),
                            letterSpacing: 3,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(size.maxWidth < 600 ? 24 : 52),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Icon(Icons.hub_rounded, size: 36),
                              IconButton(
                                tooltip: 'Toggle theme',
                                onPressed: widget.onTheme,
                                icon: const Icon(Icons.dark_mode_outlined),
                              ),
                            ],
                          ),
                          const SizedBox(height: 42),
                          Text(
                            model?.pendingEmail != null
                                ? 'Check your inbox'
                                : register
                                ? 'Find your place.'
                                : 'Welcome back.',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            model?.pendingEmail != null
                                ? 'Verify ${model!.pendingEmail} to join your campus.'
                                : register
                                ? 'Your university email is your way in.'
                                : 'Good to see you. Let’s see what’s happening on campus.',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 30),
                          if (model?.pendingEmail != null) ...[
                            _securityCheck(),
                            ActionButton(
                              label: 'Continue to sign in',
                              onPressed: () async {
                                model!.backToSignIn();
                                setState(() => register = false);
                              },
                            ),
                            const SizedBox(height: 12),
                            ActionButton(
                              label: 'Resend verification email',
                              secondary: true,
                              onPressed: challenge.busy
                                  ? null
                                  : () async {
                                      await _withCaptcha(
                                        (token) =>
                                            model!.resend(captchaToken: token),
                                      );
                                      if (context.mounted) {
                                        showMessage(
                                          context,
                                          'Verification email sent.',
                                        );
                                      }
                                    },
                            ),
                          ] else ...[
                            if (!connected)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  widget.error ?? 'Student Connect is not configured on this device. Contact your campus administrator.',
                                ),
                              ),
                            if (connected)
                              Form(
                                key: form,
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: email,
                                      enabled: !challenge.busy,
                                      textInputAction: TextInputAction.next,
                                      autocorrect: false,
                                      keyboardType: TextInputType.emailAddress,
                                      autofillHints: const [
                                        AutofillHints.email,
                                      ],
                                      decoration: const InputDecoration(
                                        labelText: 'University email',
                                      ),
                                      validator: (v) {
                                        if (v == null || !v.contains('@')) {
                                          return 'Enter your university email';
                                        }
                                        if (!AppConfig.isUniversityEmail(v)) {
                                          return 'Use an approved university email address';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: password,
                                      enabled: !challenge.busy,
                                      obscureText: hidden,
                                      autofillHints: [
                                        register
                                            ? AutofillHints.newPassword
                                            : AutofillHints.password,
                                      ],
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        suffixIcon: IconButton(
                                          tooltip: 'Show or hide password',
                                          onPressed: () =>
                                              setState(() => hidden = !hidden),
                                          icon: Icon(
                                            hidden
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                          ),
                                        ),
                                      ),
                                      validator: (v) =>
                                          v == null || v.length < 10
                                          ? 'Use at least 10 characters'
                                          : null,
                                    ),
                                    const SizedBox(height: 20),
                                    _securityCheck(),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ActionButton(
                                        label: register
                                            ? 'Create account'
                                            : 'Sign in',
                                        onPressed: challenge.busy
                                            ? null
                                            : authenticate,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: challenge.busy
                                          ? null
                                          : () => setState(
                                              () => register = !register,
                                            ),
                                      child: Text(
                                        register
                                            ? 'Already a member? Sign in'
                                            : 'New here? Create an account',
                                      ),
                                    ),
                                    ActionButton(
                                      label: 'Forgot password',
                                      secondary: true,
                                      onPressed: challenge.busy
                                          ? null
                                          : () async {
                                              if (!email.text.contains('@')) {
                                                throw StateError(
                                                  'Enter your email above first.',
                                                );
                                              }
                                              if (!AppConfig.isUniversityEmail(
                                                email.text,
                                              )) {
                                                throw StateError(
                                                  'Use an approved university email address.',
                                                );
                                              }
                                              await _withCaptcha(
                                                (token) => model!.forgot(
                                                  email.text,
                                                  captchaToken: token,
                                                ),
                                              );
                                              if (context.mounted) {
                                                showMessage(
                                                  context,
                                                  'If an account exists, a password reset email is on its way.',
                                                );
                                              }
                                            },
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 24),
                            if (widget.onPreview != null)
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: widget.onPreview,
                                  icon: const Icon(Icons.explore_outlined),
                                  label: const Text('Explore local preview'),
                                ),
                              ),
                          ],
                          const SizedBox(height: 32),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'Student Connect · A space to belong · ',
                                style: TextStyle(fontSize: 12),
                              ),
                              TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => const LegalScreen(),
                                  ),
                                ),
                                child: const Text('Privacy & safety'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
