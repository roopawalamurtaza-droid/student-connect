import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_connect/features/events/calendar_export_dialog.dart';
import 'package:student_connect/features/events/event_calendar.dart';
import 'package:student_connect/features/events/event_registration.dart';
import 'package:student_connect/models/campus_item.dart';
import 'package:student_connect/repositories/preview_repository.dart';

void main() {
  final event = CampusItem('calendar-test', {
    'title': 'Design, code; café 🧑🏽‍💻',
    'description': '${List.filled(60, 'ગુજરાતી').join()}\r\nBEGIN:VEVENT',
    'location': r'Lab A\B',
    'startsAt': '2026-12-31T23:30:00+05:30',
  });
  test(
    'calendar export preserves instant, escapes text and folds UTF-8 safely',
    () {
      final data = utf8.decode(
        EventCalendar.encode(
          event,
          reservedTime: const Duration(minutes: 90),
          generatedAt: DateTime.utc(2026, 9, 16),
        ),
      );
      final unfolded = data.replaceAll('\r\n ', '');
      expect(
        unfolded,
        contains('DTSTART:20261231T180000Z\r\nDTEND:20261231T193000Z'),
      );
      expect(unfolded, contains(r'SUMMARY:Design\, code\; café 🧑🏽‍💻'));
      expect(unfolded, contains(r'LOCATION:Lab A\\B'));
      expect(unfolded, contains(r'\nBEGIN:VEVENT'));
      expect(
        unfolded.split('\r\n').where((line) => line == 'BEGIN:VEVENT').length,
        1,
      );
      expect(unfolded, contains('90 minutes have been reserved'));
      expect(unfolded, isNot(contains('VALARM')));
      for (final line in data.split('\r\n')) {
        expect(utf8.encode(line).length, lessThanOrEqualTo(75));
      }
      final reminder = utf8.decode(
        EventCalendar.encode(
          event,
          reservedTime: const Duration(minutes: 60),
          reminder: true,
        ),
      );
      expect(reminder, contains('TRIGGER:-PT30M'));
      expect(
        () => EventCalendar.encode(event, reservedTime: Duration.zero),
        throwsArgumentError,
      );
    },
  );

  for (final width in [320.0, 1440.0]) {
    testWidgets(
      'calendar options export chosen duration and reminder at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        String? exported;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => CalendarExportDialog(
                      event: event,
                      export: (bytes, origin) async {
                        exported = utf8.decode(bytes);
                        expect(origin.width, greaterThan(0));
                        return true;
                      },
                    ),
                  ),
                  child: const Text('Open calendar'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open calendar'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(DropdownButtonFormField<int>));
        await tester.tap(find.byType(DropdownButtonFormField<int>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('90 minutes').last);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(SwitchListTile));
        await tester.tap(find.byType(SwitchListTile));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Export calendar file'));
        await tester.tap(find.text('Export calendar file'));
        await tester.pumpAndSettle();
        expect(exported, contains('DTEND:20261231T193000Z'));
        expect(exported, contains('TRIGGER:-PT30M'));
        expect(find.text('Add to your calendar'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets('registration status and cancellation respect user choice', (
    tester,
  ) async {
    final repository = PreviewRepository();
    addTearDown(repository.dispose);
    final upcoming = (await repository.watch('events').first).first;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventRegistration(repository: repository, event: upcoming),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Registration open'), findsOneWidget);
    await tester.tap(find.text('Register for event'));
    await tester.pumpAndSettle();
    expect(find.text('You’re registered'), findsOneWidget);
    await tester.tap(find.text('Cancel registration'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep my place'));
    await tester.pumpAndSettle();
    expect(
      (await repository.watch('events/${upcoming.id}/registrations').first)
          .length,
      1,
    );
    await tester.tap(find.text('Cancel registration'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, cancel'));
    await tester.pumpAndSettle();
    expect(
      await repository.watch('events/${upcoming.id}/registrations').first,
      isEmpty,
    );
    expect(find.text('Registration open'), findsOneWidget);
    final past = CampusItem(upcoming.id, {
      ...upcoming.data,
      'startsAt': DateTime.now().subtract(const Duration(minutes: 1)),
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventRegistration(repository: repository, event: past),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Registration closed'), findsOneWidget);
    expect(find.text('Register for event'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
