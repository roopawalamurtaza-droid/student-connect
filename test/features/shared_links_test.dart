import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_connect/app/student_connect_app.dart';
import 'package:student_connect/routes/shared_content.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'content links allow only supported destinations and safe identifiers',
    () {
      expect(
        ContentTarget.parse(Uri.parse('/posts/abc-123'))?.path,
        '/posts/abc-123',
      );
      expect(ContentTarget.parse(Uri.parse('/admin/abc')), isNull);
      expect(ContentTarget.parse(Uri.parse('/posts/a%2Fb')), isNull);
      expect(ContentTarget.parse(Uri.parse('/posts/abc/extra')), isNull);
      expect(
        const ContentTarget('events', 'abc').url,
        'https://student-connect-ppsu-2026.web.app/events/abc',
      );
    },
  );
  for (final entry in {
    '/communities/design': 'The Design Collective',
    '/events/local-4': 'The Friday design jam',
    '/posts/local-1': 'Good ideas start with',
  }.entries) {
    testWidgets('shared destination survives session entry: ${entry.key}', (
      tester,
    ) async {
      await tester.pumpWidget(
        StudentConnectApp(allowPreview: true, initialLocation: entry.key),
      );
      await tester.pumpAndSettle();
      expect(find.text('Welcome back.'), findsOneWidget);
      await tester.ensureVisible(find.text('Explore local preview'));
      await tester.tap(find.text('Explore local preview'));
      await tester.pumpAndSettle();
      expect(find.textContaining(entry.value), findsOneWidget);
      final context = tester.element(find.byType(SharedContentScreen));
      final router = GoRouter.of(context);
      expect(router.routeInformationProvider.value.uri.path, entry.key);
      router.go('/posts/missing');
      await tester.pumpAndSettle();
      expect(find.text('This content is unavailable'), findsOneWidget);
      router.go(entry.key);
      await tester.pumpAndSettle();
      expect(find.textContaining(entry.value), findsOneWidget);
      await tester.tap(find.byTooltip('Go to campus home'));
      await tester.pumpAndSettle();
      expect(find.text('The campus feed'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
