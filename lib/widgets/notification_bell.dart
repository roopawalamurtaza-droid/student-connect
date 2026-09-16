import 'package:flutter/material.dart';

import '../models/campus_item.dart';
import '../repositories/campus_repository.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({
    super.key,
    required this.repository,
    required this.onPressed,
  });
  final CampusRepository repository;
  final VoidCallback onPressed;
  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  late final updates = widget.repository.watch(
    'users/${widget.repository.uid}/notifications',
  );
  @override
  Widget build(BuildContext context) => StreamBuilder<List<CampusItem>>(
    stream: updates,
    builder: (context, snapshot) {
      final unread = snapshot.data?.any((item) => !item.flag('read')) ?? false;
      return IconButton(
        tooltip: unread ? 'Notifications · unread updates' : 'Notifications',
        onPressed: widget.onPressed,
        icon: Badge(
          isLabelVisible: unread,
          child: const Icon(Icons.notifications_none_rounded),
        ),
      );
    },
  );
}
