import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_connect/features/notifications/notifications_screen.dart';
import 'package:student_connect/models/campus_item.dart';
import 'package:student_connect/repositories/preview_repository.dart';
import 'package:student_connect/widgets/notification_bell.dart';

class _UpdatesRepository extends PreviewRepository {
  final updates = StreamController<void>.broadcast();
  final read = <String>{'old'};
  List<CampusItem> get notifications => ['new', 'old']
      .map(
        (id) => CampusItem(id, {
          'title': '$id update',
          'body': 'Campus activity',
          'read': read.contains(id),
        }),
      )
      .toList();
  @override
  Stream<List<CampusItem>> watch(String path) async* {
    if (!path.endsWith('/notifications')) {
      yield* super.watch(path);
      return;
    }
    yield notifications;
    yield* updates.stream.map((_) => notifications);
  }

  @override
  Future<Map<String, dynamic>> mutate(
    String action,
    Map<String, dynamic> data,
  ) async {
    if (action != 'readNotification') return super.mutate(action, data);
    read.add(data['id'] as String);
    updates.add(null);
    return {'ok': true};
  }

  @override
  void dispose() {
    unawaited(updates.close());
    super.dispose();
  }
}

void main() {
  testWidgets('unread filter, bulk read and badge agree', (tester) async {
    final repository = _UpdatesRepository();
    addTearDown(repository.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                NotificationBell(repository: repository, onPressed: () {}),
                NotificationsScreen(repository: repository),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Notifications · unread updates'), findsOneWidget);
    await tester.tap(find.text('Unread only'));
    await tester.pumpAndSettle();
    expect(find.text('old update'), findsNothing);
    expect(find.text('new update'), findsOneWidget);
    await tester.tap(find.text('Mark loaded updates as read'));
    await tester.pumpAndSettle();
    expect(find.text('You’re all caught up'), findsOneWidget);
    expect(find.byTooltip('Notifications'), findsOneWidget);
    expect(repository.read, containsAll(['new', 'old']));
    await tester.pumpWidget(const SizedBox());
  });
}
