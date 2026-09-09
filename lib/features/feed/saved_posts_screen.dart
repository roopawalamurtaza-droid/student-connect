import 'package:flutter/material.dart';

import '../../models/campus_item.dart';
import '../../repositories/campus_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/paged_items.dart';
import 'feed_screen.dart';

class SavedPostsScreen extends StatelessWidget {
  const SavedPostsScreen({
    super.key,
    required this.repository,
    required this.me,
  });
  final CampusRepository repository;
  final CampusItem me;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Saved posts')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: PagedItems(
        repository: repository,
        path: 'savedFeed',
        builder: (items) => items.isEmpty
            ? const EmptyState(
                icon: Icons.bookmark_border,
                title: 'Keep something for later',
                body: 'Save a post from its options menu to find it here.',
              )
            : Column(
                children: items
                    .map(
                      (post) =>
                          PostCard(repository: repository, me: me, post: post),
                    )
                    .toList(),
              ),
      ),
    ),
  );
}
