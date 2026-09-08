import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import '../models/campus_item.dart';
import '../repositories/campus_repository.dart';
import '../routes/destination.dart';
import '../services/notification_service.dart';
import '../features/feed/feed_screen.dart';
import '../features/feed/post_editor.dart';
import '../features/discover/discover_screen.dart';
import '../features/events/events_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/admin/admin_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class Workspace extends StatefulWidget {
  const Workspace({
    super.key,
    required this.repository,
    required this.me,
    required this.onTheme,
    required this.onExit,
  });
  final CampusRepository repository;
  final CampusItem me;
  final VoidCallback onTheme;
  final Future<void> Function() onExit;
  @override
  State<Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<Workspace> {
  StreamSubscription<String>? notificationSubscription;
  @override
  void initState() {
    super.initState();
    notificationSubscription = NotificationService.listen(widget.repository);
  }

  @override
  void dispose() {
    notificationSubscription?.cancel();
    super.dispose();
  }

  int selected = 0;
  void go(int index) {
    setState(() => selected = index);
    if (!widget.repository.isPreview) {
      FirebaseAnalytics.instance
          .logScreenView(screenName: Destination.values[index].name)
          .catchError((Object _) {});
    }
  }

  void open(Widget child, String name) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      settings: RouteSettings(name: name),
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(name)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final r = widget.repository;
    final pages = [
      FeedScreen(
        repository: r,
        me: widget.me,
        onCreate: () => go(2),
        onDiscover: () => go(1),
      ),
      DiscoverScreen(repository: r, me: widget.me),
      PostEditor(repository: r, onSaved: () => go(0)),
      EventsScreen(repository: r, me: widget.me),
      ProfileScreen(repository: r, me: widget.me),
    ];
    return LayoutBuilder(
      builder: (context, size) {
        final wide = size.maxWidth >= 850;
        return Scaffold(
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: selected,
                  onDestinationSelected: go,
                  destinations: Destination.values
                      .map(
                        (d) => NavigationDestination(
                          key: ValueKey('nav-${d.name}'),
                          icon: Icon(d.icon),
                          label: d.label,
                        ),
                      )
                      .toList(),
                ),
          body: SafeArea(
            child: Row(
              children: [
                if (wide)
                  Container(
                    width: 238,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(
                        right: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.hub_rounded, size: 31),
                            SizedBox(width: 10),
                            Text(
                              'student\nconnect',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 44),
                        const Padding(
                          padding: EdgeInsets.only(left: 14, bottom: 16),
                          child: Text(
                            'YOUR CAMPUS',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        ...Destination.values.indexed.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 7),
                            child: Material(
                              color: Colors.transparent,
                              child: ListTile(
                                key: ValueKey('nav-${entry.$2.name}'),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                selected: selected == entry.$1,
                                selectedTileColor:
                                    Theme.of(context).brightness ==
                                        Brightness.light
                                    ? const Color(0xFFEAF0DB)
                                    : const Color(0xFF334732),
                                leading: Icon(entry.$2.icon),
                                title: Text(
                                  entry.$2.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onTap: () => go(entry.$1),
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppTheme.navy,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                color: AppTheme.green,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Better, together.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'There’s a community\nfor every curiosity.',
                                style: TextStyle(
                                  color: Color(0xFFCAD8C8),
                                  fontSize: 12,
                                ),
                              ),
                              TextButton(
                                onPressed: () => go(1),
                                child: const Text(
                                  'Find yours  →',
                                  style: TextStyle(color: AppTheme.green),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            PersonAvatar(widget.me.name),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.me.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    widget.me.role,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: wide ? 32 : 16,
                          vertical: 16,
                        ),
                        color: Theme.of(context).colorScheme.surface,
                        child: Row(
                          children: [
                            if (!wide) ...[
                              const Icon(Icons.hub_rounded),
                              const SizedBox(width: 10),
                            ],
                            Expanded(
                              child: Text(
                                wide ? 'A space to belong.' : 'Student Connect',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Notifications',
                              onPressed: () => open(
                                NotificationsScreen(repository: r),
                                'Notifications',
                              ),
                              icon: const Icon(
                                Icons.notifications_none_rounded,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Toggle theme',
                              onPressed: widget.onTheme,
                              icon: const Icon(Icons.dark_mode_outlined),
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'Account menu',
                              onSelected: (value) async {
                                if (value == 'admin') {
                                  open(
                                    AdminScreen(repository: r, me: widget.me),
                                    'Administration',
                                  );
                                  return;
                                }
                                try {
                                  if (value == 'push') {
                                    await NotificationService.enable(r);
                                    if (context.mounted) {
                                      showMessage(
                                        context,
                                        'Device notifications enabled.',
                                      );
                                    }
                                  } else {
                                    try {
                                      await NotificationService.unregister(r);
                                    } finally {
                                      // Network or push-token errors must never prevent logout.
                                      await widget.onExit();
                                    }
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    showMessage(context, readableError(e));
                                  }
                                }
                              },
                              itemBuilder: (_) => [
                                if (widget.me.isModerator ||
                                    widget.me.canManage)
                                  const PopupMenuItem(
                                    value: 'admin',
                                    child: Text('Administration'),
                                  ),
                                const PopupMenuItem(
                                  value: 'push',
                                  child: Text('Enable device notifications'),
                                ),
                                PopupMenuItem(
                                  value: 'exit',
                                  child: Text(
                                    r.isPreview ? 'Leave preview' : 'Sign out',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (r.isPreview)
                        Container(
                          width: double.infinity,
                          color: Theme.of(context)
                              .colorScheme
                              .secondaryContainer,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          child: const Text(
                            'LOCAL PREVIEW · Sample campus · Changes reset when you leave',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      Expanded(
                        child: SingleChildScrollView(
                          key: ValueKey(selected),
                          padding: EdgeInsets.all(wide ? 32 : 18),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1160),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: KeyedSubtree(
                                  key: ValueKey(selected),
                                  child: pages[selected],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
