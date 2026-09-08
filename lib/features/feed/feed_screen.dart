import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/campus_item.dart';
import '../../repositories/campus_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'post_editor.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({
    super.key,
    required this.repository,
    required this.me,
    required this.onCreate,
    required this.onDiscover,
  });
  final CampusRepository repository;
  final CampusItem me;
  final VoidCallback onCreate, onDiscover;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeading(
                'Campus, connected',
                'Hey, ${me.name.split(' ').first}.',
                'Here’s what’s happening in your corner of campus.',
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppTheme.navy,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GOOD THINGS START HERE',
                      style: TextStyle(
                        color: AppTheme.green,
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Find your people.\nMake your mark.',
                      style: TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        letterSpacing: -.7,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Big ideas. Shared interests. A campus full of possibility.',
                      style: TextStyle(color: Color(0xFFD7E3D2)),
                    ),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.green,
                        foregroundColor: AppTheme.navy,
                      ),
                      onPressed: onDiscover,
                      icon: const Icon(Icons.north_east, size: 18),
                      label: const Text(
                        'Explore communities',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: onCreate,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        PersonAvatar(me.name),
                        const SizedBox(width: 14),
                        const Expanded(child: Text('Got something to share?')),
                        const Icon(Icons.edit_outlined, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              const Row(
                children: [
                  Expanded(
                    child: Text(
                      'The campus feed',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text('Latest', style: TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 16),
              Items(
                repository: repository,
                path: 'posts',
                builder: (posts) => posts.isEmpty
                    ? const EmptyState(
                        icon: Icons.forum_outlined,
                        title: 'Start the conversation',
                        body: 'Be the first to share an idea with your campus.',
                      )
                    : Column(
                        children: posts
                            .map(
                              (p) => Padding(
                                padding: const EdgeInsets.only(bottom: 18),
                                child: PostCard(
                                  repository: repository,
                                  me: me,
                                  post: p,
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
        if (size.maxWidth > 900) ...[
          const SizedBox(width: 26),
          SizedBox(
            width: 285,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.campaign_outlined, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Campus noticeboard',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Items(
                          repository: repository,
                          path: 'announcements',
                          builder: (items) => Column(
                            children: items
                                .take(3)
                                .map(
                                  (a) => Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          a.text('title'),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          a.text('body'),
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'On the horizon',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Items(
                          repository: repository,
                          path: 'events',
                          builder: (items) => Column(
                            children: items
                                .take(3)
                                .map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.only(bottom: 20),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 46,
                                          padding: const EdgeInsets.all(7),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEDF0DC),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Text(
                                            DateFormat('MMM\ndd')
                                                .format(e.date('startsAt'))
                                                .toUpperCase(),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: AppTheme.navy,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                e.text('title'),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                e.text('location'),
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'YOUR CAMPUS. YOUR COMMUNITY.',
                  style: TextStyle(fontSize: 10, letterSpacing: 1.5),
                ),
                const SizedBox(height: 8),
                const Text(
                  'A little more connected, every day.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.repository,
    required this.me,
    required this.post,
  });
  final CampusRepository repository;
  final CampusItem me, post;
  void comments(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: 500,
        child: Comments(repository: repository, post: post),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PersonAvatar(post.text('authorName')),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.text('authorName'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      post.text('department'),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Post options',
                onSelected: (action) async {
                  try {
                    if (action == 'report') {
                      await reportItem(context, repository, 'posts', post.id);
                    } else if (action == 'edit') {
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => Scaffold(
                              appBar: AppBar(title: const Text('Edit post')),
                              body: SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: PostEditor(
                                  repository: repository,
                                  post: post,
                                  onSaved: () => Navigator.pop(context),
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                    } else if (await confirmDelete(context, 'this post')) {
                      await repository.mutate('deletePost', {'id': post.id});
                    }
                  } catch (e) {
                    if (context.mounted) showMessage(context, readableError(e));
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'report',
                    child: Text('Report post'),
                  ),
                  if (post.text('authorId') == me.id)
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit post'),
                    ),
                  if (post.text('authorId') == me.id || me.isModerator)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete post'),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          SelectableText(
            post.text('body'),
            style: const TextStyle(height: 1.65),
          ),
          if (post.text('imagePath').isNotEmpty) ...[
            const SizedBox(height: 16),
            CampusImage(repository: repository, path: post.text('imagePath')),
          ],
          const Divider(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Items(
                repository: repository,
                path: 'posts/${post.id}/likes',
                builder: (likes) => TextButton.icon(
                  onPressed: () async {
                    try {
                      await repository.mutate('likePost', {'id': post.id});
                    } catch (e) {
                      if (context.mounted) {
                        showMessage(context, readableError(e));
                      }
                    }
                  },
                  icon: Icon(
                    likes.any((l) => l.id == me.id)
                        ? Icons.favorite
                        : Icons.favorite_outline,
                    size: 19,
                  ),
                  label: Text('${likes.length} likes'),
                ),
              ),
              TextButton.icon(
                onPressed: () => comments(context),
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('Comment'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class Comments extends StatefulWidget {
  const Comments({super.key, required this.repository, required this.post});
  final CampusRepository repository;
  final CampusItem post;
  @override
  State<Comments> createState() => _CommentsState();
}

class _CommentsState extends State<Comments> {
  final body = TextEditingController();
  @override
  void dispose() {
    body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        const Text(
          'The conversation',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Items(
              repository: widget.repository,
              path: 'posts/${widget.post.id}/comments',
              builder: (items) => items.isEmpty
                  ? const EmptyState(
                      icon: Icons.chat_bubble_outline,
                      title: 'Say hello',
                      body: 'Be the first to leave a comment.',
                    )
                  : Column(
                      children: items
                          .map(
                            (c) => ListTile(
                              leading: PersonAvatar(
                                c.text('authorName'),
                                radius: 18,
                              ),
                              title: Text(
                                c.text('authorName'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Text(c.text('body')),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ),
        ),
        TextField(
          controller: body,
          maxLength: 1000,
          decoration: const InputDecoration(
            hintText: 'Add to the conversation…',
          ),
        ),
        ActionButton(
          label: 'Post comment',
          onPressed: () async {
            if (body.text.trim().isEmpty) {
              throw StateError('Write a comment first.');
            }
            await widget.repository.mutate('comment', {
              'id': widget.post.id,
              'body': body.text.trim(),
            });
            body.clear();
          },
        ),
      ],
    ),
  );
}

Future<void> reportItem(
  BuildContext context,
  CampusRepository repository,
  String kind,
  String id,
) async {
  final controller = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Report a concern'),
      content: TextField(
        controller: controller,
        maxLength: 1000,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'What should the moderators know?',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ActionButton(
          label: 'Submit report',
          onPressed: () async {
            if (controller.text.trim().length < 5) {
              throw StateError(
                'Please describe the concern in a little more detail.',
              );
            }
            await repository.mutate('report', {
              'id': id,
              'kind': kind,
              'reason': controller.text.trim(),
            });
            if (context.mounted) {
              Navigator.pop(context);
              showMessage(
                context,
                repository.isPreview
                    ? 'Report recorded locally; no moderator is notified in preview.'
                    : 'Report sent to your moderators.',
              );
            }
          },
        ),
      ],
    ),
  );
  // Dialog route transitions can still reference its controller until the next frame.
  Future<void>.delayed(const Duration(seconds: 1), controller.dispose);
}
