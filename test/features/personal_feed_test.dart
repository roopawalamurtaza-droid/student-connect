import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_connect/app/workspace.dart';
import 'package:student_connect/repositories/preview_repository.dart';

void main() {
  testWidgets('home retains search, filter and scroll after tab navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
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
        home: Workspace(
          repository: repository,
          me: me,
          onTheme: () {},
          onExit: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('My communities'));
    await tester.tap(find.text('My communities'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Good ideas start with'), findsOneWidget);
    expect(find.textContaining('Looking for two teammates'), findsNothing);
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'design');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
    final offset = scroll.position.pixels;
    expect(offset, greaterThan(0));
    await tester.tap(find.byKey(const ValueKey('nav-events')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-home')));
    await tester.pumpAndSettle();
    expect(find.text('design'), findsOneWidget);
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'My communities'))
          .selected,
      isTrue,
    );
    expect(scroll.position.pixels, closeTo(offset, 1));
    await tester.ensureVisible(find.text('Refresh feed'));
    await tester.tap(find.text('Refresh feed'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Good ideas start with'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
