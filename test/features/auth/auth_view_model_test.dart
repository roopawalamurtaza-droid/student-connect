import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:student_connect/features/auth/auth_view_model.dart';
import 'package:student_connect/repositories/auth_repository.dart';

class PendingAuthRepository implements AuthRepository {
  final completion = Completer<void>();

  @override
  Future<void> authenticate(
    String email,
    String password, {
    required bool register,
    String? captchaToken,
  }) => completion.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('signup finishing after screen disposal does not notify', () async {
    final repository = PendingAuthRepository();
    final model = AuthViewModel(repository);
    final request = model.authenticate(
      'student@ppsu.ac.in',
      'password',
      register: true,
    );
    model.dispose();
    repository.completion.complete();
    await expectLater(request, completes);
    expect(model.pendingEmail, isNull);
  });

  test('active signup shows verification only after success', () async {
    final repository = PendingAuthRepository();
    final model = AuthViewModel(repository);
    addTearDown(model.dispose);
    var notifications = 0;
    model.addListener(() => notifications++);
    final request = model.authenticate(
      ' student@ppsu.ac.in ',
      'password',
      register: true,
    );
    expect(model.pendingEmail, isNull);
    repository.completion.complete();
    await request;
    expect(model.pendingEmail, 'student@ppsu.ac.in');
    expect(notifications, 1);
  });
}
