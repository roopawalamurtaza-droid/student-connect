import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:student_connect/features/feed/post_draft.dart';

void main() {
  test(
    'request key and frozen post survive lost response, rotate on success',
    () async {
      final draft = PostDraft()..body = 'One post';
      final key = draft.requestId;
      expect(
        key,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      draft.pendingPost = {'body': draft.body, 'requestId': key};
      await expectLater(
        draft.submit(() async => throw StateError('Response lost')),
        throwsStateError,
      );
      expect(draft.requestId, key);
      expect(draft.pendingPost!['body'], 'One post');
      await draft.submit(() async {});
      expect(draft.pendingPost, isNull);
      expect(draft.requestId, isNot(key));
      draft.dispose();
    },
  );
  test(
    'shared draft blocks overlapping submission and clears after success',
    () async {
      final draft = PostDraft()
        ..body = 'A campus idea'
        ..image = Uint8List.fromList([1, 2]);
      final pending = Completer<void>();
      var requests = 0;
      final first = draft.submit(() {
        requests++;
        return pending.future;
      });
      expect(draft.publishing, isTrue);
      await expectLater(
        draft.submit(() async {
          requests++;
        }),
        throwsStateError,
      );
      pending.complete();
      await first;
      expect(requests, 1);
      expect(draft.publishing, isFalse);
      expect(draft.body, isEmpty);
      expect(draft.image, isNull);
      draft.dispose();
    },
  );

  test('draft survives failure and releases its submission lock', () async {
    final bytes = Uint8List.fromList([1]);
    final draft = PostDraft()
      ..body = 'Keep this draft'
      ..image = bytes;
    await expectLater(
      draft.submit(() async => throw StateError('Offline')),
      throwsStateError,
    );
    expect(draft.body, 'Keep this draft');
    expect(draft.image, bytes);
    expect(draft.publishing, isFalse);
    draft.dispose();
  });

  test(
    'completion clears draft after the original editor stops listening',
    () async {
      final draft = PostDraft()..body = 'Published while away';
      final pending = Completer<void>();
      void listener() {}
      draft.addListener(listener);
      final result = draft.submit(() => pending.future);
      draft.removeListener(listener);
      pending.complete();
      await result;
      expect(draft.body, isEmpty);
      expect(draft.publishing, isFalse);
      draft.dispose();
    },
  );
}
