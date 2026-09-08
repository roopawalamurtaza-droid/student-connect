import 'package:flutter/material.dart';

import '../../models/campus_item.dart';
import '../../repositories/campus_repository.dart';
import '../../widgets/common.dart';
import '../feed/feed_screen.dart';
import '../feed/post_editor.dart';
import '../events/events_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key, required this.repository, required this.me});
  final CampusRepository repository;
  final CampusItem me;
  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  String query = '', category = 'communities';
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const PageHeading(
        'Follow your curiosity',
        'There’s a place for you.',
        'Meet a collaborator. Find a club. Try something new.',
      ),
      TextField(
        onChanged: (text) => setState(() => query = text.toLowerCase()),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Search people, communities, events, and posts',
        ),
      ),
      const SizedBox(height: 18),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children:
            {
                  'communities': 'Communities & clubs',
                  'users': 'Students',
                  'events': 'Events',
                  'posts': 'Posts',
                }.entries
                .map(
                  (entry) => ChoiceChip(
                    label: Text(entry.value),
                    selected: category == entry.key,
                    onSelected: (_) => setState(() => category = entry.key),
                  ),
                )
                .toList(),
      ),
      const SizedBox(height: 8),
      const Text(
        'Searches the current results (up to 200 per category).',
        style: TextStyle(fontSize: 11),
      ),
      const SizedBox(height: 20),
      Items(
        repository: widget.repository,
        path: category,
        builder: (all) {
          final items = all
              .where(
                (item) => item.data.values
                    .whereType<String>()
                    .join(' ')
                    .toLowerCase()
                    .contains(query),
              )
              .toList();
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.search_off,
              title: 'Nothing here just yet',
              body: 'Try another search or check back as your campus grows.',
            );
          }
          return Column(
            children: items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: switch (category) {
                      'communities' => CommunityCard(
                        repository: widget.repository,
                        me: widget.me,
                        item: item,
                      ),
                      'events' => EventCard(
                        repository: widget.repository,
                        event: item,
                      ),
                      'posts' => PostCard(
                        repository: widget.repository,
                        me: widget.me,
                        post: item,
                      ),
                      _ => Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(18),
                          leading: PersonAvatar(item.name),
                          title: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${item.text('department')}\n${item.text('bio')}',
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            tooltip: 'Report user',
                            icon: const Icon(Icons.flag_outlined),
                            onPressed: () => reportItem(
                              context,
                              widget.repository,
                              'users',
                              item.id,
                            ),
                          ),
                          onTap: () => showDialog<void>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(item.name),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.text('department')),
                                  Text('Semester ${item.number('semester')}'),
                                  const SizedBox(height: 14),
                                  Text(item.text('bio')),
                                  const SizedBox(height: 14),
                                  Wrap(
                                    spacing: 8,
                                    children: item
                                        .strings('skills')
                                        .map((s) => Chip(label: Text(s)))
                                        .toList(),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    },
                  ),
                )
                .toList(),
          );
        },
      ),
    ],
  );
}

class CommunityCard extends StatelessWidget {
  const CommunityCard({
    super.key,
    required this.repository,
    required this.me,
    required this.item,
  });
  final CampusRepository repository;
  final CampusItem me, item;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.diversity_2_outlined),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      item.text('kind'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(item.text('description')),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              Items(
                repository: repository,
                path: 'communities/${item.id}/members',
                builder: (members) => ActionButton(
                  label: members.any((m) => m.id == me.id)
                      ? 'Leave community'
                      : 'Join community',
                  icon: Icons.group_add_outlined,
                  onPressed: () async {
                    await repository.mutate('joinCommunity', {'id': item.id});
                  },
                ),
              ),
              OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => Scaffold(
                      appBar: AppBar(title: Text(item.name)),
                      body: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Items(
                              repository: repository,
                              path: 'communities/${item.id}/members',
                              builder: (members) =>
                                  members.any((m) => m.id == me.id)
                                  ? PostEditor(
                                      repository: repository,
                                      communityId: item.id,
                                      onSaved: () => Navigator.pop(context),
                                    )
                                  : const Text(
                                      'Join this community to start a conversation.',
                                    ),
                            ),
                            const SizedBox(height: 24),
                            Items(
                              repository: repository,
                              path: 'posts',
                              builder: (posts) => Column(
                                children: posts
                                    .where(
                                      (p) => p.text('communityId') == item.id,
                                    )
                                    .map(
                                      (p) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        child: PostCard(
                                          repository: repository,
                                          me: me,
                                          post: p,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                child: const Text('Open community'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
