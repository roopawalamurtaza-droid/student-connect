import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_connect/features/profile/profile_screen.dart';
import 'package:student_connect/models/campus_item.dart';
import 'package:student_connect/repositories/preview_repository.dart';
import 'package:student_connect/widgets/common.dart';

class PhotoRepository extends PreviewRepository {
  final Map<String, Future<Uint8List?>> photos = {};
  final List<String> requests = [];
  @override
  Future<Uint8List?> image(String path) {
    requests.add(path);
    return photos[path] ?? Future.value(null);
  }
}

void main() {
  testWidgets(
    'avatar loads privately, keeps initials on failure, and rejects stale results',
    (tester) async {
      final repo = PhotoRepository();
      addTearDown(repo.dispose);
      final photo = File('web/icons/Icon-192.png').readAsBytesSync();
      final pending = Completer<Uint8List?>();
      repo.photos['old'] = pending.future;
      Widget avatar(String path) => MaterialApp(
        home: PersonAvatar('Alex Morgan', repository: repo, photoPath: path),
      );
      await tester.pumpWidget(avatar('old'));
      expect(find.text('AM'), findsOneWidget);
      await tester.pumpWidget(avatar('missing'));
      pending.complete(photo);
      await tester.pumpAndSettle();
      expect(find.text('AM'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      repo.photos['good'] = Future.value(photo);
      await tester.pumpWidget(avatar('good'));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
      expect(
        find.bySemanticsLabel('Profile picture for Alex Morgan'),
        findsOneWidget,
      );
      await tester.pumpWidget(avatar('good'));
      expect(repo.requests.where((path) => path == 'good').length, 1);
      final denied = Completer<Uint8List?>();
      repo.photos['denied'] = denied.future;
      await tester.pumpWidget(avatar('denied'));
      denied.completeError(StateError('Private image unavailable'));
      await tester.pumpAndSettle();
      expect(find.text('AM'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final width in [320.0, 1440.0]) {
    testWidgets(
      'optional profile guidance focuses fields and preserves draft at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = PhotoRepository();
        addTearDown(repo.dispose);
        final saved = (await repo.watch('users').first).firstWhere(
          (p) => p.id == repo.uid,
        );
        var profile = CampusItem(saved.id, {
          ...saved.data,
          'bio': '',
          'skills': <String>[],
        });
        Widget screen() => MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileScreen(repository: repo, me: profile),
            ),
          ),
        );
        await tester.pumpWidget(screen());
        await tester.pumpAndSettle();
        expect(find.text('0 of 3 optional details added'), findsOneWidget);
        await tester.ensureVisible(find.text('Short bio'));
        await tester.tap(find.text('Short bio'));
        await tester.pumpAndSettle();
        final bio = find.widgetWithText(TextFormField, 'About you');
        expect(
          tester
              .widget<EditableText>(
                find.descendant(of: bio, matching: find.byType(EditableText)),
              )
              .focusNode
              .hasFocus,
          isTrue,
        );
        await tester.enterText(bio, 'Looking for robotics teammates.');
        await tester.pumpAndSettle();
        expect(find.text('1 of 3 optional details added'), findsOneWidget);
        // Simulates a background photo refresh while the text remains unsaved.
        profile = CampusItem(profile.id, {
          ...profile.data,
          'photoPath': 'new-photo',
        });
        await tester.pumpWidget(screen());
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextFormField>(bio).controller!.text,
          'Looking for robotics teammates.',
        );
        expect(find.text('2 of 3 optional details added'), findsOneWidget);
        await tester.ensureVisible(find.text('Skills & interests'));
        await tester.tap(find.text('Skills & interests'));
        await tester.pumpAndSettle();
        final skills = find.widgetWithText(
          TextFormField,
          'Skills & interests (comma-separated)',
        );
        expect(
          tester
              .widget<EditableText>(
                find.descendant(
                  of: skills,
                  matching: find.byType(EditableText),
                ),
              )
              .focusNode
              .hasFocus,
          isTrue,
        );
        await tester.enterText(skills, 'Robotics, Design');
        await tester.pumpAndSettle();
        expect(find.text('3 of 3 optional details added'), findsOneWidget);
        await tester.ensureVisible(find.text('Save profile'));
        await tester.tap(find.text('Save profile'));
        await tester.pumpAndSettle();
        final result = (await repo.watch('users').first).firstWhere(
          (p) => p.id == repo.uid,
        );
        expect(result.text('bio'), 'Looking for robotics teammates.');
        expect(result.strings('skills'), ['Robotics', 'Design']);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
