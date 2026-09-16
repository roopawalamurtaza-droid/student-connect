import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/campus_item.dart';
import '../../repositories/campus_repository.dart';
import '../../widgets/common.dart';

class EventRegistration extends StatefulWidget {
  const EventRegistration({
    super.key,
    required this.repository,
    required this.event,
  });
  final CampusRepository repository;
  final CampusItem event;
  @override
  State<EventRegistration> createState() => _EventRegistrationState();
}

class _EventRegistrationState extends State<EventRegistration> {
  Timer? timer;
  @override
  void initState() {
    super.initState();
    _scheduleClose();
  }

  void _scheduleClose() {
    timer?.cancel();
    final remaining = widget.event.date('startsAt').difference(DateTime.now());
    if (remaining > Duration.zero) {
      final delay = remaining > const Duration(days: 1)
          ? const Duration(days: 1)
          : remaining;
      timer = Timer(delay, () {
        if (mounted) {
          setState(() {});
          _scheduleClose();
        }
      });
    }
  }

  @override
  void didUpdateWidget(EventRegistration old) {
    super.didUpdateWidget(old);
    if (old.event.date('startsAt') != widget.event.date('startsAt')) {
      _scheduleClose();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Items(
    repository: widget.repository,
    path: 'events/${widget.event.id}/registrations',
    builder: (items) {
      final joined = items.any((p) => p.id == widget.repository.uid);
      final closed = !widget.event.date('startsAt').isAfter(DateTime.now());
      final scheme = Theme.of(context).colorScheme;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: joined
                  ? scheme.secondaryContainer
                  : scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  joined
                      ? Icons.check_circle_outline
                      : closed
                      ? Icons.schedule
                      : Icons.event_available_outlined,
                  size: 21,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        joined
                            ? 'You’re registered'
                            : closed
                            ? 'Registration closed'
                            : 'Registration open',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        closed
                            ? 'This event has started.'
                            : joined
                            ? 'Find this event in My registrations.'
                            : 'Register to add it to your campus plans.',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (!closed)
            ActionButton(
              label: joined ? 'Cancel registration' : 'Register for event',
              secondary: joined,
              icon: Icons.arrow_forward,
              onPressed: () async {
                if (joined) {
                  final cancel = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Cancel your registration?'),
                      content: Text(
                        'You’ll be removed from ${widget.event.text('title')}. You can register again before it starts. Remove any saved calendar copy separately.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Keep my place'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Yes, cancel'),
                        ),
                      ],
                    ),
                  );
                  if (cancel != true || !mounted) return;
                }
                await widget.repository.mutate('registerEvent', {
                  'id': widget.event.id,
                });
                if (mounted) {
                  showMessage(
                    this.context,
                    joined ? 'Registration cancelled.' : 'You’re registered. Find this event in My registrations.',
                  );
                }
              },
            ),
        ],
      );
    },
  );
}
