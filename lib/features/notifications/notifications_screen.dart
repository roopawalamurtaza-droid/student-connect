import 'package:flutter/material.dart';

import '../../repositories/campus_repository.dart';
import '../../widgets/common.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, required this.repository});
  final CampusRepository repository;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const PageHeading(
        'In the loop',
        'Your updates',
        'Conversations, reminders, and news from your campus.',
      ),
      Items(
        repository: repository,
        path: 'users/${repository.uid}/notifications',
        builder: (items) => items.isEmpty
            ? const EmptyState(
                icon: Icons.notifications_none,
                title: 'You’re all caught up',
                body: 'Likes, comments, and event reminders will appear here.',
              )
            : Column(
                children: items
                    .map(
                      (n) => Card(
                        child: ListTile(
                          leading: Icon(
                            n.flag('read')
                                ? Icons.notifications_none
                                : Icons.circle,
                            size: 18,
                          ),
                          title: Text(n.text('title')),
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
                                        showMessage(context, readableError(e));
                                      }
                                    }
                                  },
                                ),
                        ),
                      ),
                    )
                    .toList(),
              ),
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
