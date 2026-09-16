import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../models/campus_item.dart';
import '../../repositories/campus_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/paged_items.dart';
import '../../theme/app_theme.dart';
import '../../routes/shared_content.dart';
import 'calendar_export_dialog.dart';
import 'event_registration.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key, required this.repository, required this.me});
  final CampusRepository repository;
  final CampusItem me;
  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final search = TextEditingController();
  Timer? debounce;
  String filter = 'upcoming', query = '';
  late DateTime boundary = DateTime.now();

  @override
  void dispose() {
    debounce?.cancel();
    search.dispose();
    super.dispose();
  }

  void updateSearch(String value) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const PageHeading(
        'Make room for something good',
        'Be there. Be part of it.',
        'Workshops, meetups, and moments worth showing up for.',
      ),
      TextField(
        controller: search,
        onChanged: updateSearch,
        decoration: InputDecoration(
          labelText: 'Search campus events',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            tooltip: 'Clear event search',
            icon: const Icon(Icons.clear),
            onPressed: () {
              search.clear();
              debounce?.cancel();
              setState(() => query = '');
            },
          ),
        ),
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final entry in {
            'upcoming': 'Upcoming',
            'mine': 'My registrations',
            'past': 'Past events',
          }.entries)
            ChoiceChip(
              label: Text(entry.value),
              selected: filter == entry.key,
              onSelected: (_) => setState(() {
                filter = entry.key;
                boundary = DateTime.now();
              }),
            ),
        ],
      ),
      const SizedBox(height: 20),
      PagedItems(
        repository: widget.repository,
        path: Uri(
          path: 'events',
          queryParameters: {
            'q': query,
            if (filter == 'upcoming')
              'from': boundary.toUtc().toIso8601String(),
            if (filter == 'past') 'before': boundary.toUtc().toIso8601String(),
            if (filter == 'mine') 'mine': 'true',
          },
        ).toString(),
        builder: (items) => items.isEmpty
            ? EmptyState(
                icon: Icons.event_outlined,
                title: query.isNotEmpty
                    ? 'No matching events'
                    : filter == 'mine'
                    ? 'Your plans start here'
                    : filter == 'past'
                    ? 'No past events yet'
                    : 'Something good is on its way',
                body: query.isNotEmpty
                    ? 'Try another event title or clear the search.'
                    : filter == 'mine'
                    ? 'Choose an upcoming event and register. It will appear here.'
                    : 'Campus events will appear here as they are published.',
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
                              repository: widget.repository,
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
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.text('bannerPath').isNotEmpty)
            CampusImage(
              repository: repository,
              path: event.text('bannerPath'),
              height: 160,
            ),
          Container(
            height: 100,
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
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const Icon(
                  Icons.bubble_chart_outlined,
                  color: AppTheme.green,
                  size: 48,
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
                EventRegistration(repository: repository, event: event),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('Add to calendar'),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => CalendarExportDialog(
                      event: event,
                      includeLink: !repository.isPreview,
                    ),
                  ),
                ),
                if (!repository.isPreview)
                  TextButton.icon(
                    icon: const Icon(Icons.link),
                    label: const Text('Copy event link'),
                    onPressed: () =>
                        copyContentLink(context, 'events', event.id),
                  ),
                TextButton.icon(
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  label: const Text('Copy event details'),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(
                        text:
                            '${event.text('title')}\n${DateFormat('EEE, d MMM yyyy · h:mm a').format(date)}\n${event.text('location')}\n\n${event.text('description')}',
                      ),
                    );
                    if (context.mounted) {
                      showMessage(context, 'Event details copied.');
                    }
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
