import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/campus_item.dart';
import '../../repositories/campus_repository.dart';
import '../../widgets/common.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.repository, required this.me});
  final CampusRepository repository;
  final CampusItem me;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const PageHeading(
        'Your corner',
        'Make yourself known.',
        'A little about you goes a long way.',
      ),
      Card(
        child: Column(
          children: [
            Container(
              height: 110,
              decoration: const BoxDecoration(
                color: AppTheme.navy,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const Center(
                child: Text(
                  'EVERY CONNECTION STARTS WITH YOU.',
                  style: TextStyle(
                    color: AppTheme.green,
                    letterSpacing: 3,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  PersonAvatar(me.name, radius: 36),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          me.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '${me.text('department')} · Semester ${me.number('semester')}',
                        ),
                        Text(
                          me.text('enrollment'),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      ProfileEditor(key: ValueKey(me.id), repository: repository, profile: me),
    ],
  );
}

class ProfileEditor extends StatefulWidget {
  const ProfileEditor({super.key, required this.repository, this.profile});
  final CampusRepository repository;
  final CampusItem? profile;
  @override
  State<ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<ProfileEditor> {
  final form = GlobalKey<FormState>();
  late final fields = {
    for (final key in [
      'name',
      'enrollment',
      'department',
      'semester',
      'bio',
      'skills',
    ])
      key: TextEditingController(
        text: key == 'semester'
            ? '${widget.profile?.number(key) ?? 1}'
            : key == 'skills'
            ? widget.profile?.strings(key).join(', ')
            : widget.profile?.text(key),
      ),
  };
  @override
  void dispose() {
    for (final controller in fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    await widget.repository.mutate('saveProfile', {
      'name': fields['name']!.text.trim(),
      'enrollment': fields['enrollment']!.text.trim(),
      'department': fields['department']!.text.trim(),
      'semester': int.parse(fields['semester']!.text),
      'bio': fields['bio']!.text.trim(),
      'skills': fields['skills']!.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
    });
    if (mounted) {
      showMessage(
        context,
        widget.repository.isPreview
            ? 'Profile updated in this preview.'
            : 'Profile saved.',
      );
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 22),
            if (widget.profile?.text('photoPath').isNotEmpty == true) ...[
              SizedBox(
                width: 120,
                child: CampusImage(
                  repository: widget.repository,
                  path: widget.profile!.text('photoPath'),
                  height: 120,
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (widget.profile != null) ...[
              ActionButton(
                label: 'Change profile photo',
                icon: Icons.add_a_photo_outlined,
                onPressed: () async {
                  final file = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                  );
                  if (file == null) return;
                  if (await file.length() > 3 * 1024 * 1024) {
                    throw StateError('Choose an image smaller than 3 MB.');
                  }
                  await widget.repository.mutate('uploadImage', {
                    'base64': base64Encode(await file.readAsBytes()),
                    'purpose': 'avatar',
                  });
                },
              ),
              const SizedBox(height: 20),
            ],
            ...fields.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: entry.value,
                  maxLines: entry.key == 'bio' ? 3 : 1,
                  keyboardType: entry.key == 'semester'
                      ? TextInputType.number
                      : TextInputType.text,
                  decoration: InputDecoration(
                    labelText: {
                      'name': 'Full name',
                      'enrollment': 'Enrollment number',
                      'department': 'Department',
                      'semester': 'Semester (1–12)',
                      'bio': 'About you',
                      'skills': 'Skills & interests (comma-separated)',
                    }[entry.key],
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (entry.key == 'semester') {
                      final n = int.tryParse(text);
                      return n == null || n < 1 || n > 12
                          ? 'Enter a semester from 1 to 12'
                          : null;
                    }
                    if ([
                          'name',
                          'enrollment',
                          'department',
                        ].contains(entry.key) &&
                        text.isEmpty) {
                      return 'This field is required';
                    }
                    final limit = entry.key == 'bio'
                        ? 500
                        : entry.key == 'enrollment'
                        ? 40
                        : entry.key == 'skills'
                        ? 500
                        : 80;
                    if (text.length > limit) {
                      return 'Use at most $limit characters';
                    }
                    if (entry.key == 'skills' &&
                        (text
                                    .split(',')
                                    .where((s) => s.trim().isNotEmpty)
                                    .length >
                                12 ||
                            text.split(',').any((s) => s.trim().length > 40))) {
                      return 'Use up to 12 skills, at most 40 characters each';
                    }
                    return null;
                  },
                ),
              ),
            ),
            ActionButton(
              label: 'Save profile',
              icon: Icons.check,
              onPressed: save,
            ),
          ],
        ),
      ),
    ),
  );
}
