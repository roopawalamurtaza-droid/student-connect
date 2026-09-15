import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:student_connect/features/auth/captcha_session.dart';

void main() {
  test('missing and expired tokens never reach authentication', () async {
    final session = CaptchaSession();
    var calls = 0;
    Future<void> request(String? token) async {
      calls++;
    }

    await expectLater(session.run(request, required: true), throwsStateError);
    session.receive(
      'expired',
      now: DateTime.now().subtract(const Duration(minutes: 6)),
    );
    await expectLater(session.run(request, required: true), throwsStateError);
    expect(calls, 0);
  });
  test('token consumed once and overlapping requests blocked', () async {
    final session = CaptchaSession()..receive('valid');
    final pending = Completer<void>();
    final result = session.run((token) {
      expect(token, 'valid');
      return pending.future;
    }, required: true);
    await expectLater(
      session.run((_) async {}, required: true),
      throwsStateError,
    );
    pending.complete();
    await result;
    await expectLater(
      session.run((_) async {}, required: true),
      throwsStateError,
    );
    expect(session.busy, false);
  });
  test('failed requests release the lock without reusing token', () async {
    final session = CaptchaSession()..receive('valid');
    await expectLater(
      session.run((_) async => throw StateError('offline'), required: true),
      throwsStateError,
    );
    expect(session.busy, false);
    expect(session.ready(), false);
    session.receive('fresh');
    expect(await session.run((token) async => token, required: true), 'fresh');
  });
}
