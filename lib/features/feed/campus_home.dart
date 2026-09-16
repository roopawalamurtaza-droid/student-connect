import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/campus_item.dart';
import '../../repositories/campus_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/paged_items.dart';
import 'feed_screen.dart';
import 'saved_posts_screen.dart';

class CampusHome extends StatefulWidget {
  const CampusHome({
    super.key,
    required this.repository,
    required this.me,
    required this.onCreate,
    required this.onDiscover,
    required this.onEvents,
    required this.onUpdates,
  });
  final CampusRepository repository;
  final CampusItem me;
  final VoidCallback onCreate, onDiscover, onEvents, onUpdates;
  @override
  State<CampusHome> createState() => _CampusHomeState();
}

class _CampusHomeState extends State<CampusHome> {
  final search = TextEditingController();
  Timer? debounce;
  String query = '';
  bool joinedOnly = false;
  int refreshVersion = 0;
  late final upcoming = Uri(
    path: 'events',
    queryParameters: {
      'from': DateTime.now().toUtc().toIso8601String(),
      'limit': '3',
    },
  ).toString();
  @override
  void dispose() {
    debounce?.cancel();
    search.dispose();
    super.dispose();
  }

  Widget _notices() => _Panel(
    title: 'Campus noticeboard',
    icon: Icons.campaign_outlined,
    child: Items(
      repository: widget.repository,
      path: 'announcements',
      builder: (items) => items.isEmpty
          ? const Text('No new announcements. You’re up to date.')
          : Column(
              children: items
                  .take(3)
                  .map(
                    (item) => ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(bottom: 16),
                      title: Text(
                        item.text('title'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SelectableText(item.text('body')),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
    ),
  );

  Widget _events() => _Panel(
    title: 'Coming up',
    icon: Icons.event_outlined,
    child: Items(
      repository: widget.repository,
      path: upcoming,
      builder: (items) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (items.isEmpty)
            const Text('Your next campus experience will appear here.'),
          for (final event in items.take(3))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 48,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  DateFormat('dd\nMMM').format(event.date('startsAt')),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ),
              title: Text(
                event.text('title'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                event.text('location'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: widget.onEvents,
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: widget.onEvents,
            child: const Text('Explore events →'),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final desktop = constraints.maxWidth > 900;
      final scheme = Theme.of(context).colorScheme;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeading(
            'Your campus, at a glance',
            'Hey, ${widget.me.name.split(' ').first}.',
            DateFormat('EEEE, d MMMM').format(DateTime.now()),
          ),
          Container(
            padding: EdgeInsets.all(constraints.maxWidth < 500 ? 22 : 30),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.navy, Color(0xFF276A67)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'A LITTLE MORE CONNECTED',
                  style: TextStyle(
                    color: AppTheme.green,
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your people. Your possibilities.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Ask a question, find a community, or make plans for your week.',
                  style: TextStyle(color: Color(0xFFE1EFEB)),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.green,
                        foregroundColor: AppTheme.navy,
                      ),
                      onPressed: widget.onCreate,
                      icon: const Icon(Icons.add),
                      label: const Text('Start a conversation'),
                    ),
                    TextButton(
                      onPressed: widget.onDiscover,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Find a community →'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, size) {
              final columns = size.maxWidth < 650 ? 2 : 4;
              final width = (size.maxWidth - 12 * (columns - 1)) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final action in [
                    (
                      Icons.explore_outlined,
                      'Discover',
                      'People & clubs',
                      widget.onDiscover,
                    ),
                    (
                      Icons.event_available_outlined,
                      'My campus plans',
                      'Events & registrations',
                      widget.onEvents,
                    ),
                    (
                      Icons.bookmark_outline,
                      'Saved posts',
                      'Keep ideas close',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => SavedPostsScreen(
                              repository: widget.repository,
                              me: widget.me,
                            ),
                          ),
                        );
                      },
                    ),
                    (
                      Icons.notifications_none,
                      'Your updates',
                      'Stay in the loop',
                      widget.onUpdates,
                    ),
                  ])
                    SizedBox(
                      width: width,
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: action.$4,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(action.$1, color: scheme.primary),
                                const SizedBox(height: 14),
                                Text(
                                  action.$2,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  action.$3,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          if (!desktop) ...[
            _events(),
            const SizedBox(height: 16),
            _notices(),
            const SizedBox(height: 24),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'The campus feed',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('All campus'),
                          selected: !joinedOnly,
                          onSelected: (_) => setState(() => joinedOnly = false),
                        ),
                        ChoiceChip(
                          label: const Text('My communities'),
                          selected: joinedOnly,
                          onSelected: (_) => setState(() => joinedOnly = true),
                        ),
                        TextButton.icon(
                          onPressed: () => setState(() => refreshVersion++),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh feed'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: search,
                      onChanged: (value) {
                        debounce?.cancel();
                        debounce = Timer(const Duration(milliseconds: 350), () {
                          if (mounted) setState(() => query = value.trim());
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Search campus conversations',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          tooltip: 'Clear feed search',
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            debounce?.cancel();
                            search.clear();
                            setState(() => query = '');
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    PagedItems(
                      key: ValueKey(refreshVersion),
                      repository: widget.repository,
                      path: Uri(
                        path: 'posts',
                        queryParameters: {
                          'q': query,
                          if (joinedOnly) 'joined': 'true',
                        },
                      ).toString(),
                      builder: (posts) => posts.isEmpty
                          ? EmptyState(
                              icon: Icons.forum_outlined,
                              title: query.isEmpty
                                  ? joinedOnly
                                        ? 'Your communities are quiet'
                                        : 'Start the conversation'
                                  : 'No matching conversations',
                              body: query.isEmpty
                                  ? joinedOnly
                                        ? 'Join a community in Discover or start a conversation in one you’ve joined.'
                                        : 'Share an idea or ask your campus a question.'
                                  : 'Try another phrase or clear the search.',
                            )
                          : Column(
                              children: posts
                                  .map(
                                    (post) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 18,
                                      ),
                                      child: PostCard(
                                        repository: widget.repository,
                                        me: widget.me,
                                        post: post,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                  ],
                ),
              ),
              if (desktop) ...[
                const SizedBox(width: 24),
                SizedBox(
                  width: 285,
                  child: Column(
                    children: [
                      _events(),
                      const SizedBox(height: 20),
                      _notices(),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    },
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    ),
  );
}
