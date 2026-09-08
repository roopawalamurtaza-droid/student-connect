import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/campus_item.dart';
import '../../repositories/campus_repository.dart';
import '../../widgets/common.dart';
import '../../theme/app_theme.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key, required this.repository, required this.me});
  final CampusRepository repository;
  final CampusItem me;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const PageHeading(
        'Make room for something good',
        'Be there. Be part of it.',
        'Workshops, meetups, and moments worth showing up for.',
      ),
      Items(
        repository: repository,
        path: 'events',
        builder: (items) => items.isEmpty
            ? const EmptyState(
                icon: Icons.event_outlined,
                title: 'Something good is on its way',
                body: 'New campus events will appear here.',
              )
            : LayoutBuilder(
                builder: (context, size) {
                  final width = size.maxWidth > 700
                      ? (size.maxWidth - 20) / 2
                      : size.maxWidth;
                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: items
                        .map(
                          (event) => SizedBox(
                            width: width,
                            child: EventCard(
                              repository: repository,
                              event: event,
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
      ),
    ],
  );
}

class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.repository, required this.event});
  final CampusRepository repository;
  final CampusItem event;
  @override
  Widget build(BuildContext context) {
    final date = event.date('startsAt');
    final ended = date.isBefore(DateTime.now());
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 130,
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppTheme.navy,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd\nMMM').format(date).toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.green,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const Icon(
                  Icons.bubble_chart_outlined,
                  color: AppTheme.green,
                  size: 70,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.text('title'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                Text(event.text('description')),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 17),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        DateFormat('EEE, d MMM · h:mm a').format(date),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 17),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.text('location'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Items(
                  repository: repository,
                  path: 'events/${event.id}/registrations',
                  builder: (items) {
                    final joined = items.any((p) => p.id == repository.uid);
                    return ActionButton(
                      label: ended
                          ? 'Registration closed'
                          : joined
                          ? 'Cancel registration'
                          : 'Count me in',
                      icon: joined ? Icons.check : Icons.north_east,
                      onPressed: ended
                          ? null
                          : () async {
                              await repository.mutate('registerEvent', {
                                'id': event.id,
                              });
                              if (context.mounted) {
                                showMessage(
                                  context,
                                  repository.isPreview
                                      ? 'Registration updated in this preview.'
                                      : joined
                                      ? 'Registration cancelled.'
                                      : 'You’re registered. An in-app reminder will appear before the event.',
                                );
                              }
                            },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
