import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routes/shared_content.dart';

import '../../models/campus_item.dart';
import '../../repositories/campus_repository.dart';

import '../../widgets/common.dart';

import 'post_editor.dart';

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
                    if (action == 'copyLink') {
                      await copyContentLink(context, 'posts', post.id);
                    } else if (action == 'openLink') {
                      context.go(ContentTarget('posts', post.id).path);
                    } else if (action == 'report') {
                      await reportItem(context, repository, 'posts', post.id);
                    } else if (action == 'save') {
                      await repository.mutate('savePost', {'id': post.id});
                      if (context.mounted) {
                        showMessage(context, 'Saved posts updated.');
                      }
                    } else if (action == 'block') {
                      await repository.mutate('blockUser', {
                        'id': post.text('authorId'),
                      });
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
                  if (!repository.isPreview) ...[
                    const PopupMenuItem(
                      value: 'openLink',
                      child: Text('Open post'),
                    ),
                    const PopupMenuItem(
                      value: 'copyLink',
                      child: Text('Copy post link'),
                    ),
                  ],
                  const PopupMenuItem(
                    value: 'save',
                    child: Text('Save / unsave post'),
                  ),
                  if (!repository.isPreview && post.text('authorId') != me.id)
                    const PopupMenuItem(
                      value: 'block',
                      child: Text('Block this student'),
                    ),
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
                  label: Text(
                    '${repository.isPreview
                        ? likes.length
                        : likes.isEmpty
                        ? 0
                        : likes.first.number('total')} likes',
                  ),
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
