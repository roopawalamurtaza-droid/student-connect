import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_connect/app/student_connect_app.dart';
import 'package:student_connect/repositories/preview_repository.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('preview post ownership and reversible likes', () async {
    final repository = PreviewRepository();
    final initial = await repository.watch('posts').first;
    await expectLater(
      repository.mutate('deletePost', {'id': initial.first.id}),
      throwsStateError,
    );
    await repository.mutate('createPost', {
      'body': 'My campus idea',
      'communityId': '',
      'imagePath': '',
    });
    final posts = await repository.watch('posts').first;
    final post = posts.firstWhere((p) => p.text('body') == 'My campus idea');
    await repository.mutate('likePost', {'id': post.id});
    expect((await repository.watch('posts/${post.id}/likes').first).length, 1);
    await repository.mutate('likePost', {'id': post.id});
    expect(await repository.watch('posts/${post.id}/likes').first, isEmpty);
    await repository.mutate('editPost', {
      'id': post.id,
      'post': {'body': 'Edited idea'},
    });
    expect(
      (await repository.watch('posts').first).any(
        (p) => p.text('body') == 'Edited idea',
      ),
      isTrue,
    );
    await repository.mutate('deletePost', {'id': post.id});
    expect((await repository.watch('posts').first).length, initial.length);
    repository.dispose();
  });
  for (final size in [const Size(390, 844), const Size(1440, 1000)]) {
    testWidgets('preview navigation and publishing at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const StudentConnectApp(allowPreview: true));
      await tester.pumpAndSettle();
      expect(find.text('Welcome back.'), findsOneWidget);
      await tester.ensureVisible(find.text('Explore local preview'));
      await tester.tap(find.text('Explore local preview'));
      await tester.pumpAndSettle();
      expect(find.text('The campus feed'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('nav-discover')));
      await tester.pumpAndSettle();
      expect(find.text('There’s a place for you.'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Design');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('The Design Collective'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('nav-events')));
      await tester.pumpAndSettle();
      expect(find.text('Be there. Be part of it.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('nav-create')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).first,
        'A new campus conversation',
      );
      await tester.ensureVisible(find.text('Publish post'));
      await tester.tap(find.text('Publish post'));
      await tester.pumpAndSettle();
      expect(find.text('A new campus conversation'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('nav-profile')));
      await tester.pumpAndSettle();
      expect(find.text('Your details'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
}
