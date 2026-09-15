import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../core/config.dart';

@JS('turnstile')
external _Turnstile get _turnstile;

extension type _Turnstile(JSObject _) implements JSObject {
  external String render(web.HTMLElement element, JSObject options);
  external void remove(String id);
}

Future<void>? _script;
Future<void> _loadScript() => _script ??= () async {
  final ready = Completer<void>();
  final script = web.HTMLScriptElement()
    ..src =
        'https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit'
    ..async = true;
  script.onload = ((web.Event event) => ready.complete()).toJS;
  script.onerror = ((web.Event event) {
    if (!ready.isCompleted) {
      ready.completeError(StateError('Security check unavailable'));
    }
  }).toJS;
  web.document.head!.append(script);
  try {
    await ready.future.timeout(const Duration(seconds: 25));
  } catch (_) {
    script.remove();
    _script = null;
    rethrow;
  }
}();

class SecurityChallenge extends StatefulWidget {
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
  State<SecurityChallenge> createState() => _SecurityChallengeState();
}

class _SecurityChallengeState extends State<SecurityChallenge> {
  String? widgetId;
  Timer? attachTimer;

  Future<void> attach(web.HTMLElement element, Brightness brightness) async {
    try {
      await _loadScript();
      if (!mounted) return;
      var attempts = 0;
      attachTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (!element.isConnected) {
          if (++attempts >= 200) {
            timer.cancel();
            widget.onError();
          }
          return;
        }
        timer.cancel();
        try {
          widgetId = _turnstile.render(
            element,
            {
                  'sitekey': AppConfig.recaptchaKey,
                  'theme': brightness == Brightness.dark ? 'dark' : 'light',
                  'size': widget.compact ? 'compact' : 'normal',
                  'callback': ((JSString token) {
                    if (mounted) widget.onToken(token.toDart);
                  }).toJS,
                  'expired-callback': (() {
                    if (mounted) widget.onExpired();
                  }).toJS,
                  'error-callback': ((JSString code) {
                    if (mounted) widget.onError();
                  }).toJS,
                }.jsify()!
                as JSObject,
          );
        } catch (_) {
          if (mounted) widget.onError();
        }
      });
    } catch (_) {
      if (mounted) widget.onError();
    }
  }

  @override
  void dispose() {
    attachTimer?.cancel();
    if (widgetId != null) _turnstile.remove(widgetId!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return SizedBox(
      width: widget.compact ? 150 : 300,
      height: widget.compact ? 140 : 65,
      child: HtmlElementView.fromTagName(
        tagName: 'div',
        onElementCreated: (element) =>
            unawaited(attach(element as web.HTMLElement, brightness)),
      ),
    );
  }
}
