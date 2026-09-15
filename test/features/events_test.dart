import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_connect/features/events/events_screen.dart';
import 'package:student_connect/repositories/preview_repository.dart';
import 'package:student_connect/theme/app_theme.dart';

void main() {
  test(
    'event filters include only own registrations and respect dates',
    () async {
      final repository = PreviewRepository();
      addTearDown(repository.dispose);
      final events = await repository.watch('events').first;
      expect(await repository.watch('events?mine=true').first, isEmpty);
      await repository.mutate('registerEvent', {'id': events.first.id});
      expect(
        (await repository.watch('events?mine=true').first).single.id,
        events.first.id,
      );
      final before = Uri(
        path: 'events',
        queryParameters: {'before': DateTime.now().toUtc().toIso8601String()},
      );
      expect(await repository.watch(before.toString()).first, isEmpty);
      await repository.mutate('registerEvent', {'id': events.first.id});
      expect(await repository.watch('events?mine=true').first, isEmpty);
    },
  );

  for (final size in [const Size(320, 640), const Size(1440, 900)]) {
    testWidgets('event search and personal plans at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = PreviewRepository();
      addTearDown(repository.dispose);
      final me = (await repository.watch('users').first).firstWhere(
        (p) => p.id == repository.uid,
      );
      final events = await repository.watch('events').first;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(Brightness.light),
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: EventsScreen(repository: repository, me: me),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(events.first.text('title')), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'no such event');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('No matching events'), findsOneWidget);
      await tester.tap(find.byTooltip('Clear event search'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('My registrations'));
      await tester.tap(find.text('My registrations'));
      await tester.pumpAndSettle();
      expect(find.text('Your plans start here'), findsOneWidget);
      await repository.mutate('registerEvent', {'id': events.first.id});
      await tester.pumpAndSettle();
      expect(find.text(events.first.text('title')), findsOneWidget);
      expect(find.text(events.last.text('title')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
