import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'dart:convert';

import 'package:image_picker/image_picker.dart';

import '../../models/campus_item.dart';
import '../../repositories/campus_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/paged_items.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key, required this.repository, required this.me});
  final CampusRepository repository;
  final CampusItem me;
  Future<void> editor(BuildContext context, String kind, {CampusItem? item}) =>
      showDialog<void>(
        context: context,
        builder: (_) =>
            ManageEditor(repository: repository, kind: kind, item: item),
      );
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const PageHeading(
        'Campus stewardship',
        'Help your community thrive.',
        'Manage events, review concerns, and keep the conversation welcoming.',
      ),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          FilledButton(
            onPressed: () => editor(context, 'event'),
            child: const Text('Create event'),
          ),
          FilledButton(
            onPressed: () => editor(context, 'community'),
            child: const Text('Create community'),
          ),
          if (me.isModerator)
            FilledButton(
              onPressed: () => editor(context, 'announcement'),
              child: const Text('Publish announcement'),
            ),
        ],
      ),
      const SizedBox(height: 24),
      const Text(
        'Manage events',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      PagedItems(
        repository: repository,
        path: 'events',
        builder: (events) => Column(
          children: events
              .where((e) => e.text('ownerId') == me.id || me.isModerator)
              .map(
                (e) => ListTile(
                  title: Text(e.text('title')),
                  subtitle: Text(DateFormat.yMMMd().format(e.date('startsAt'))),
                  trailing: Wrap(
                    children: [
                      IconButton(
                        tooltip: 'Edit event',
                        onPressed: () => editor(context, 'event', item: e),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete event',
                        onPressed: () async {
                          try {
                            if (await confirmDelete(context, 'this event')) {
                              await repository.mutate('deleteEvent', {
                                'id': e.id,
                              });
                            }
                          } catch (error) {
                            if (context.mounted) {
                              showMessage(context, readableError(error));
                            }
                          }
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
      if (me.isModerator) ...[
        const Divider(height: 32),
        const Text(
          'Reports',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        PagedItems(
          repository: repository,
          path: 'reports',
          builder: (reports) => Column(
            children: reports
                .where((r) => r.text('status') == 'open')
                .map(
                  (r) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.text('reason')),
                          if (r.text('targetSummary').isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'Reported content: ${r.text('targetSummary')}',
                              ),
                            ),
                          Text(
                            '${r.text('kind')} · ${r.text('targetId')}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              ActionButton(
                                label: 'Resolve report',
                                onPressed: () async {
                                  await repository.mutate('resolveReport', {
                                    'id': r.id,
                                  });
                                },
                              ),
                              if (r.text('kind') == 'posts')
                                ActionButton(
                                  label: 'Remove reported post',
                                  onPressed: () async {
                                    if (await confirmDelete(
                                      context,
                                      'the reported post',
                                    )) {
                                      await repository.mutate('deletePost', {
                                        'id': r.text('targetId'),
                                      });
                                    }
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const Divider(height: 32),
        const Text(
          'Announcements',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Items(
          repository: repository,
          path: 'announcements',
          builder: (items) => Column(
            children: items
                .map(
                  (a) => ListTile(
                    title: Text(a.text('title')),
                    subtitle: Text(a.text('body')),
                    trailing: ActionButton(
                      label: 'Delete',
                      onPressed: () async {
                        if (await confirmDelete(context, 'this announcement')) {
                          await repository.mutate('deleteAnnouncement', {
                            'id': a.id,
                          });
                        }
                      },
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
      if (['admin', 'super_admin'].contains(me.role)) ...[
        const Divider(height: 32),
        const Text(
          'People & permissions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        PagedItems(
          repository: repository,
          path: 'users',
          builder: (users) => Column(
            children: users
                .map(
                  (user) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(user.role),
                          Wrap(
                            spacing: 10,
                            children: [
                              PopupMenuButton<String>(
                                tooltip: 'Assign role',
                                onSelected: (role) async {
                                  try {
                                    await repository.mutate('moderateUser', {
                                      'id': user.id,
                                      'role': role,
                                      'suspended': user.flag('suspended'),
                                    });
                                  } catch (e) {
                                    if (context.mounted) {
                                      showMessage(context, readableError(e));
                                    }
                                  }
                                },
                                itemBuilder: (_) =>
                                    [
                                          'student',
                                          'club_admin',
                                          'faculty',
                                          'moderator',
                                          'admin',
                                          if (me.role == 'super_admin')
                                            'super_admin',
                                        ]
                                        .map(
                                          (r) => PopupMenuItem(
                                            value: r,
                                            child: Text(r),
                                          ),
                                        )
                                        .toList(),
                                child: const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: Text('Change role'),
                                ),
                              ),
                              ActionButton(
                                label: user.flag('suspended')
                                    ? 'Restore access'
                                    : 'Suspend',
                                onPressed: user.id == me.id
                                    ? null
                                    : () async {
                                        await repository.mutate(
                                          'moderateUser',
                                          {
                                            'id': user.id,
                                            'role': user.role,
                                            'suspended': !user.flag(
                                              'suspended',
                                            ),
                                          },
                                        );
                                      },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    ],
  );
}

class ManageEditor extends StatefulWidget {
  const ManageEditor({
    super.key,
    required this.repository,
    required this.kind,
    this.item,
  });
  final CampusRepository repository;
  final String kind;
  final CampusItem? item;
  @override
  State<ManageEditor> createState() => _ManageEditorState();
}

class _ManageEditorState extends State<ManageEditor> {
  late final title = TextEditingController(text: widget.item?.text('title'));
  late final body = TextEditingController(
    text: widget.item?.text('description'),
  );
  late final location = TextEditingController(
    text: widget.item?.text('location'),
  );
  late DateTime date =
      widget.item?.date('startsAt') ??
      DateTime.now().add(const Duration(days: 1));
  String kind = 'Club';
  String? imagePath;
  @override
  void dispose() {
    title.dispose();
    body.dispose();
    location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('${widget.item == null ? 'Create' : 'Edit'} ${widget.kind}'),
    content: SizedBox(
      width: 480,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.repository.isPreview &&
                widget.kind != 'announcement') ...[
              ActionButton(
                label: imagePath == null ? 'Add image' : 'Replace image',
                icon: Icons.image_outlined,
                onPressed: () async {
                  final image = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1600,
                    maxHeight: 1600,
                    imageQuality: 85,
                  );
                  if (image == null) return;
                  if (await image.length() > 3 * 1024 * 1024) {
                    throw StateError('Choose an image smaller than 3 MB.');
                  }
                  final result = await widget.repository.mutate('uploadImage', {
                    'purpose': widget.kind == 'event' ? 'event' : 'community',
                    'base64': base64Encode(await image.readAsBytes()),
                  });
                  if (mounted) {
                    setState(() => imagePath = result['path'] as String);
                  }
                },
              ),
              if (imagePath != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: CampusImage(
                    repository: widget.repository,
                    path: imagePath!,
                    height: 120,
                  ),
                ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: title,
              maxLength: 100,
              decoration: const InputDecoration(labelText: 'Title / name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: body,
              maxLength: widget.kind == 'community' ? 600 : 3000,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            if (widget.kind == 'event') ...[
              const SizedBox(height: 12),
              TextField(
                controller: location,
                maxLength: 160,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              TextButton.icon(
                icon: const Icon(Icons.calendar_month),
                label: Text(DateFormat('d MMM yyyy · h:mm a').format(date)),
                onPressed: () async {
                  final day = await showDatePicker(
                    context: context,
                    initialDate: date.isBefore(DateTime.now())
                        ? DateTime.now()
                        : date,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (day == null || !context.mounted) return;
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(date),
                  );
                  if (time != null && mounted) {
                    setState(
                      () => date = DateTime(
                        day.year,
                        day.month,
                        day.day,
                        time.hour,
                        time.minute,
                      ),
                    );
                  }
                },
              ),
            ],
            if (widget.kind == 'community')
              DropdownButton<String>(
                value: kind,
                isExpanded: true,
                items: ['Club', 'Department', 'Community']
                    .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                    .toList(),
                onChanged: (value) => setState(() => kind = value!),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      ActionButton(
        label: 'Save',
        onPressed: () async {
          if (title.text.trim().isEmpty || body.text.trim().isEmpty) {
            throw StateError('Add a title and description.');
          }
          if (widget.kind == 'event') {
            if (location.text.trim().isEmpty || date.isBefore(DateTime.now())) {
              throw StateError('Choose a location and future date.');
            }
            final result = await widget.repository.mutate('saveEvent', {
              'id': widget.item?.id,
              'event': {
                'title': title.text.trim(),
                'description': body.text.trim(),
                'location': location.text.trim(),
                'startsAt': date.millisecondsSinceEpoch,
                'communityId': widget.item?.text('communityId') ?? '',
              },
            });
            if (imagePath != null) {
              await widget.repository.mutate('attachMedia', {
                'id': widget.item?.id ?? result['id'],
                'kind': 'event',
                'path': imagePath,
              });
            }
          } else if (widget.kind == 'community') {
            final result = await widget.repository.mutate('saveCommunity', {
              'name': title.text.trim(),
              'description': body.text.trim(),
              'kind': kind,
            });
            if (imagePath != null) {
              await widget.repository.mutate('attachMedia', {
                'id': result['id'],
                'kind': 'community',
                'path': imagePath,
              });
            }
          } else {
            await widget.repository.mutate('announce', {
              'title': title.text.trim(),
              'body': body.text.trim(),
            });
          }
          if (context.mounted) Navigator.pop(context);
        },
      ),
    ],
  );
}
