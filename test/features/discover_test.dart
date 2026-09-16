import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_connect/features/discover/discover_screen.dart';
import 'package:student_connect/repositories/preview_repository.dart';

void main() {
  for (final width in [320.0, 1440.0]) {
    testWidgets('student skill search and combined filters at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = PreviewRepository();
      addTearDown(repository.dispose);
      final me = (await repository.watch('users').first).firstWhere(
        (p) => p.id == repository.uid,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DiscoverScreen(repository: repository, me: me),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Students'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Illustration');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Maya Patel'), findsOneWidget);
      expect(find.text('Noah Williams'), findsNothing);
      await tester.tap(find.text('My department'));
      await tester.pumpAndSettle();
      expect(find.text('No students match yet'), findsOneWidget);
      await tester.tap(find.text('Clear search and filters'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('My semester'));
      await tester.pumpAndSettle();
      expect(find.text('Maya Patel'), findsNothing);
      expect(find.text('Noah Williams'), findsOneWidget);
      await tester.tap(find.text('My department'));
      await tester.pumpAndSettle();
      expect(find.text('Alex Morgan'), findsOneWidget);
      expect(find.text('Noah Williams'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
