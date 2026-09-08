import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/campus_item.dart';
import '../../repositories/campus_repository.dart';
import '../../widgets/common.dart';

class PostEditor extends StatefulWidget {
  const PostEditor({
    super.key,
    required this.repository,
    required this.onSaved,
    this.post,
    this.communityId = '',
  });
  final CampusRepository repository;
  final VoidCallback onSaved;
  final CampusItem? post;
  final String communityId;
  @override
  State<PostEditor> createState() => _PostEditorState();
}

class _PostEditorState extends State<PostEditor> {
  late final body = TextEditingController(text: widget.post?.text('body'));
  late String imagePath = widget.post?.text('imagePath') ?? '';
  Uint8List? bytes;
  @override
  void dispose() {
    body.dispose();
    super.dispose();
  }

  Future<void> publish() async {
    final text = body.text.trim();
    if (text.isEmpty || text.length > 3000) {
      throw StateError('Write a post between 1 and 3,000 characters.');
    }
    if (bytes != null) {
      final result = await widget.repository.mutate('uploadImage', {
        'base64': base64Encode(bytes!),
        'purpose': 'post',
      });
      imagePath = result['path'] as String;
    }
    final data = {
      'body': text,
      'imagePath': imagePath,
      'communityId': widget.post?.text('communityId') ?? widget.communityId,
    };
    await widget.repository.mutate(
      widget.post == null ? 'createPost' : 'editPost',
      widget.post == null ? data : {'id': widget.post!.id, 'post': data},
    );
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
                  onPressed: () => setState(() {
                    bytes = null;
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
                    onPressed: () async {
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
                      if (mounted) setState(() => bytes = data);
                    },
                  ),
                  ActionButton(
                    label: widget.post == null
                        ? 'Publish post'
                        : 'Save changes',
                    icon: Icons.arrow_upward,
                    onPressed: publish,
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
