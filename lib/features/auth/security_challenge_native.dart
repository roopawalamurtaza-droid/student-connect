import 'package:flutter/material.dart';
import 'package:flutter_turnstile/flutter_turnstile.dart';

import '../../core/config.dart';

class SecurityChallenge extends StatelessWidget {
  const SecurityChallenge({
    super.key,
    required this.compact,
    required this.onToken,
    required this.onExpired,
    required this.onError,
  });
  final bool compact;
  final ValueChanged<String> onToken;
  final VoidCallback onExpired, onError;

  @override
  Widget build(BuildContext context) => CloudFlareTurnstile(
    siteKey: AppConfig.recaptchaKey,
    baseUrl: AppConfig.captchaBaseUrl,
    options: TurnstileOptions(
      mode: TurnstileMode.managed,
      size: compact ? TurnstileSize.compact : TurnstileSize.normal,
      theme: Theme.of(context).brightness == Brightness.dark
          ? TurnstileTheme.dark
          : TurnstileTheme.light,
    ),
    onTokenReceived: onToken,
    onTokenExpired: onExpired,
    onError: (_) => onError(),
  );
}
