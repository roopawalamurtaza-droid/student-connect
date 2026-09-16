import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../features/discover/discover_screen.dart';
import '../features/events/events_screen.dart';
import '../features/feed/feed_screen.dart';
import '../models/campus_item.dart';
import '../repositories/campus_repository.dart';
import '../widgets/common.dart';

class ContentTarget {
  const ContentTarget(this.kind, this.id);
  final String kind, id;
  static const kinds = ['posts', 'events', 'communities'];
  static ContentTarget? parse(Uri uri) {
    final parts = uri.pathSegments;
    if (parts.length != 2 ||
        !kinds.contains(parts.first) ||
        !RegExp(r'^[a-zA-Z0-9-]{1,64}$').hasMatch(parts.last)) {
      return null;
    }
    return ContentTarget(parts.first, parts.last);
  }

  String get path => '/$kind/$id';
  String get url =>
      Uri.https('student-connect-ppsu-2026.web.app', path).toString();
}

Future<void> copyContentLink(
  BuildContext context,
  String kind,
  String id,
) async {
  await Clipboard.setData(ClipboardData(text: ContentTarget(kind, id).url));
  if (context.mounted) {
    showMessage(context, 'Link copied. Campus sign-in is required to open it.');
  }
}

class SharedContentScreen extends StatelessWidget {
  const SharedContentScreen({
    super.key,
    required this.repository,
    required this.me,
    required this.target,
  });
  final CampusRepository repository;
  final CampusItem me;
  final ContentTarget target;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Student Connect'),
      leading: IconButton(
        tooltip: 'Go to campus home',
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/'),
      ),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Items(
            key: ValueKey(target.path),
            repository: repository,
            path: Uri(
              path: target.kind,
              queryParameters: {'id': target.id},
            ).toString(),
            builder: (items) => items.isEmpty
                ? const EmptyState(
                    icon: Icons.link_off,
                    title: 'This content is unavailable',
                    body: 'It may have been removed or you may not have access. Return to campus home to keep exploring.',
                  )
                : switch (target.kind) {
                    'posts' => PostCard(
                      repository: repository,
                      me: me,
                      post: items.first,
                    ),
                    'events' => EventCard(
                      repository: repository,
                      event: items.first,
                    ),
                    _ => CommunityCard(
                      repository: repository,
                      me: me,
                      item: items.first,
                    ),
                  },
          ),
        ),
      ),
    ),
  );
}
