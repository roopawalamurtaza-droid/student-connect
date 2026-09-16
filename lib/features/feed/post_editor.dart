import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/campus_item.dart';
import '../../repositories/campus_repository.dart';
import '../../widgets/common.dart';
import 'post_draft.dart';
export 'post_draft.dart';

class PostEditor extends StatefulWidget {
  const PostEditor({
    super.key,
    required this.repository,
    required this.onSaved,
    this.post,
    this.communityId = '',
    this.draft,
  });
  final CampusRepository repository;
  final VoidCallback onSaved;
  final CampusItem? post;
  final String communityId;
  final PostDraft? draft;
  @override
  State<PostEditor> createState() => _PostEditorState();
}

class _PostEditorState extends State<PostEditor> {
  late final body = TextEditingController(
    text: widget.post?.text('body') ?? widget.draft?.body,
  );
  late String imagePath = widget.post?.text('imagePath') ?? '';
  late Uint8List? bytes = widget.draft?.image;
  late final submission = widget.draft ?? PostDraft();
  bool choosingImage = false;
  @override
  void initState() {
    super.initState();
    body.addListener(_saveDraft);
    submission.addListener(_submissionChanged);
  }

  void _submissionChanged() {
    if (!mounted) return;
    if (!submission.publishing && widget.draft != null) {
      body.text = submission.body;
      bytes = submission.image;
    }
    setState(() {});
  }

  void _saveDraft() {
    widget.draft?.body = body.text;
  }

  @override
  void dispose() {
    submission.removeListener(_submissionChanged);
    body.dispose();
    super.dispose();
  }

  Future<void> publish() async {
    if (choosingImage) {
      throw StateError('Wait for your image to finish loading.');
    }
    final text = body.text.trim();
    if (text.isEmpty || text.length > 3000) {
      throw StateError('Write a post between 1 and 3,000 characters.');
    }
    await submission.submit(() async {
      if (bytes != null && submission.pendingPost == null) {
        final result = await widget.repository.mutate('uploadImage', {
          'base64': base64Encode(bytes!),
          'purpose': 'post',
        });
        imagePath = result['path'] as String;
      }
      final data =
          submission.pendingPost ??
          {
            'body': text,
            'imagePath': imagePath,
            'communityId':
                widget.post?.text('communityId') ?? widget.communityId,
            if (widget.post == null) 'requestId': submission.requestId,
          };
      if (widget.post == null) submission.pendingPost = Map.of(data);
      try {
        await widget.repository.mutate(
          widget.post == null ? 'createPost' : 'editPost',
          widget.post == null ? data : {'id': widget.post!.id, 'post': data},
        );
      } on PostgrestException catch (error) {
        if ([
          '22023',
          '23502',
          '23503',
          '23505',
          '23514',
          '42501',
          'P0002',
        ].contains(error.code)) {
          submission.pendingPost = null;
        }
        rethrow;
      }
    });
    if (mounted) {
      showMessage(
        context,
        widget.repository.isPreview
            ? 'Post saved in this local preview.'
            : 'Your post is live.',
      );
      widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      PageHeading(
        'Share something',
        widget.post == null ? 'What’s on your mind?' : 'Give it another look.',
        'An idea, a question, a small win. This is your space.',
      ),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.public, size: 18),
                  SizedBox(width: 8),
                  Expanded(child: Text('Visible to verified campus members')),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: body,
                enabled:
                    !submission.publishing && submission.pendingPost == null,
                maxLines: 8,
                maxLength: 3000,
                decoration: const InputDecoration(
                  hintText: 'Start a conversation…',
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 18),
              if (bytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(bytes!, height: 220, fit: BoxFit.cover),
                ),
              if (bytes == null && imagePath.isNotEmpty)
                CampusImage(repository: widget.repository, path: imagePath),
              if (bytes != null || imagePath.isNotEmpty)
                TextButton(
                  onPressed:
                      submission.publishing ||
                          choosingImage ||
                          submission.pendingPost != null
                      ? null
                      : () => setState(() {
                          bytes = null;
                          widget.draft?.image = null;
                          imagePath = '';
                        }),
                  child: const Text('Remove image'),
                ),
              const Divider(height: 32),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ActionButton(
                    label: 'Add image',
                    icon: Icons.image_outlined,
                    onPressed:
                        submission.publishing ||
                            choosingImage ||
                            submission.pendingPost != null
                        ? null
                        : () async {
                            setState(() => choosingImage = true);
                            try {
                              final file = await ImagePicker().pickImage(
                                source: ImageSource.gallery,
                              );
                              if (file == null) return;
                              if (await file.length() > 3 * 1024 * 1024) {
                                throw StateError(
                                  'Choose a JPEG, PNG, or WebP under 3 MB.',
                                );
                              }
                              final data = await file.readAsBytes();
                              if (mounted) {
                                setState(() {
                                  bytes = data;
                                  widget.draft?.image = data;
                                });
                              }
                            } finally {
                              if (mounted) {
                                setState(() => choosingImage = false);
                              }
                            }
                          },
                  ),
                  ActionButton(
                    label: submission.publishing
                        ? 'Publishing…'
                        : submission.pendingPost != null
                        ? 'Retry original post'
                        : widget.post == null
                        ? 'Publish post'
                        : 'Save changes',
                    icon: Icons.arrow_upward,
                    onPressed: submission.publishing || choosingImage
                        ? null
                        : publish,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (submission.pendingPost != null && !submission.publishing)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'We could not confirm the result. Retry to confirm the original post safely; its text and image are kept unchanged.',
                  ),
                ),
              if (widget.draft != null)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Draft stays with you while switching tabs. Leaving the app clears it.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              const Text(
                'Keep it kind. Respect your community and everyone in it.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
