import 'package:flutter/material.dart';

import '../../repositories/campus_repository.dart';
import '../../widgets/common.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.repository});
  final CampusRepository repository;
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool unreadOnly = false;
  CampusRepository get repository => widget.repository;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const PageHeading(
        'In the loop',
        'Your updates',
        'Conversations, reminders, and news from your campus.',
      ),
      FilterChip(
        label: const Text('Unread only'),
        selected: unreadOnly,
        onSelected: (value) => setState(() => unreadOnly = value),
      ),
      const SizedBox(height: 16),
      Items(
        repository: repository,
        path: 'users/${repository.uid}/notifications',
        builder: (all) {
          final unread = all.where((item) => !item.flag('read')).toList();
          final items = unreadOnly ? unread : all;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (unread.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ActionButton(
                    label: 'Mark loaded updates as read',
                    secondary: true,
                    icon: Icons.done_all,
                    onPressed: () async {
                      for (final item in unread) {
                        await repository.mutate('readNotification', {
                          'id': item.id,
                        });
                      }
                    },
                  ),
                ),
              items.isEmpty
                  ? const EmptyState(
                      icon: Icons.notifications_none,
                      title: 'You’re all caught up',
                      body: 'Likes, comments, and event reminders will appear here.',
                    )
                  : Column(
                      children: items
                          .map(
                            (n) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Card(
                                child: ListTile(
                                  leading: Icon(
                                    n.flag('read')
                                        ? Icons.notifications_none
                                        : Icons.circle,
                                    size: 18,
                                  ),
                                  title: Text(
                                    n.text('title'),
                                    style: TextStyle(
                                      fontWeight: n.flag('read')
                                          ? FontWeight.normal
                                          : FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(n.text('body')),
                                  trailing: n.flag('read')
                                      ? null
                                      : IconButton(
                                          tooltip: 'Mark as read',
                                          icon: const Icon(Icons.done),
                                          onPressed: () async {
                                            try {
                                              await repository.mutate(
                                                'readNotification',
                                                {'id': n.id},
                                              );
                                            } catch (e) {
                                              if (context.mounted) {
                                                showMessage(
                                                  context,
                                                  readableError(e),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ],
          );
        },
      ),
      const SizedBox(height: 24),
      const Text(
        'Campus announcements',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),
      Items(
        repository: repository,
        path: 'announcements',
        builder: (items) => Column(
          children: items
              .map(
                (a) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.campaign_outlined),
                    title: Text(a.text('title')),
                    subtitle: Text(a.text('body')),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    ],
  );
}
