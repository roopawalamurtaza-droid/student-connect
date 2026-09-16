import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_connect/features/feed/campus_home.dart';
import 'package:student_connect/repositories/preview_repository.dart';
import 'package:student_connect/theme/app_theme.dart';

void main() {
  for (final width in [320.0, 1440.0]) {
    testWidgets('dashboard discovery and search at $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = PreviewRepository();
      addTearDown(repository.dispose);
      final me = (await repository.watch('users').first).firstWhere(
        (item) => item.id == repository.uid,
      );
      var eventsOpened = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(Brightness.dark),
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: CampusHome(
                repository: repository,
                me: me,
                onCreate: () {},
                onDiscover: () {},
                onUpdates: () {},
                onEvents: () => eventsOpened++,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Campus noticeboard'), findsOneWidget);
      expect(find.text('Coming up'), findsOneWidget);
      await tester.ensureVisible(find.text('My campus plans'));
      await tester.tap(find.text('My campus plans'));
      expect(eventsOpened, 1);
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'hackathon');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.textContaining('Looking for two teammates'), findsOneWidget);
      expect(find.textContaining('Good ideas start with'), findsNothing);
      await tester.enterText(find.byType(TextField), 'nothing-matches-this');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('No matching conversations'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
