import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/campus_item.dart';
import '../../repositories/campus_repository.dart';
import '../../widgets/common.dart';
import '../../theme/app_theme.dart';
import 'account_controls.dart';
import '../feed/saved_posts_screen.dart';
import 'profile_checklist.dart';

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
                  PersonAvatar(
                    me.name,
                    radius: 36,
                    repository: repository,
                    photoPath: me.text('photoPath'),
                  ),
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
            if (me.text('bio').trim().isNotEmpty ||
                me.strings('skills').isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (me.text('bio').trim().isNotEmpty) Text(me.text('bio')),
                    if (me.strings('skills').isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: me
                            .strings('skills')
                            .map((skill) => Chip(label: Text(skill)))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      ProfileEditor(key: ValueKey(me.id), repository: repository, profile: me),
      if (!repository.isPreview)
        TextButton.icon(
          icon: const Icon(Icons.bookmark_outline),
          label: const Text('Saved posts'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => SavedPostsScreen(repository: repository, me: me),
            ),
          ),
        ),
      if (!repository.isPreview) AccountControls(repository: repository),
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
  final photoKey = GlobalKey();
  final bioKey = GlobalKey();
  final skillsKey = GlobalKey();
  final bioFocus = FocusNode();
  final skillsFocus = FocusNode();
  late String photoPath = widget.profile?.text('photoPath') ?? '';
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
  void initState() {
    super.initState();
    fields['bio']!.addListener(_detailsChanged);
    fields['skills']!.addListener(_detailsChanged);
  }

  void _detailsChanged() => setState(() {});
  void _jumpTo(GlobalKey key, [FocusNode? focus]) {
    final target = key.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(target, alignment: 0.15);
      focus?.requestFocus();
    }
  }

  @override
  void didUpdateWidget(ProfileEditor old) {
    super.didUpdateWidget(old);
    if (old.profile?.text('photoPath') != widget.profile?.text('photoPath')) {
      photoPath = widget.profile?.text('photoPath') ?? '';
    }
  }

  @override
  void dispose() {
    bioFocus.dispose();
    skillsFocus.dispose();
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
            if (widget.profile != null) ...[
              ProfileChecklist(
                hasPhoto: photoPath.isNotEmpty,
                hasBio: fields['bio']!.text.trim().isNotEmpty,
                hasSkills: fields['skills']!.text
                    .split(',')
                    .any((s) => s.trim().isNotEmpty),
                onPhoto: () => _jumpTo(photoKey),
                onBio: () => _jumpTo(bioKey, bioFocus),
                onSkills: () => _jumpTo(skillsKey, skillsFocus),
              ),
              const SizedBox(height: 20),
              PersonAvatar(
                fields['name']!.text,
                repository: widget.repository,
                photoPath: photoPath,
                radius: 44,
              ),
              const SizedBox(height: 12),
              ActionButton(
                key: photoKey,
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
                  final bytes = await file.readAsBytes();
                  if (!mounted) return;
                  final result = await widget.repository.mutate('uploadImage', {
                    'base64': base64Encode(bytes),
                    'purpose': 'avatar',
                  });
                  if (mounted) {
                    setState(() => photoPath = result['path'] as String);
                    showMessage(this.context, 'Profile photo updated.');
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
            ...fields.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  key: entry.key == 'bio'
                      ? bioKey
                      : entry.key == 'skills'
                      ? skillsKey
                      : null,
                  focusNode: entry.key == 'bio'
                      ? bioFocus
                      : entry.key == 'skills'
                      ? skillsFocus
                      : null,
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
