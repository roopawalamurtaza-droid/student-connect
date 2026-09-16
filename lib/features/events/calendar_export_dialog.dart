import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/campus_item.dart';
import '../../widgets/common.dart';
import 'event_calendar.dart';

typedef CalendarExport = Future<bool> Function(Uint8List data, Rect origin);

class CalendarExportDialog extends StatefulWidget {
  const CalendarExportDialog({
    super.key,
    required this.event,
    this.includeLink = true,
    this.export,
  });
  final CampusItem event;
  final bool includeLink;
  final CalendarExport? export;
  @override
  State<CalendarExportDialog> createState() => _CalendarExportDialogState();
}

class _CalendarExportDialogState extends State<CalendarExportDialog> {
  int minutes = 60;
  bool reminder = false;
  Future<bool> _export(Uint8List bytes, Rect origin) async {
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'text/calendar')],
        fileNameOverrides: ['student-connect-event.ics'],
        sharePositionOrigin: origin,
      ),
    );
    return result.status != ShareResultStatus.dismissed;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add to your calendar'),
    scrollable: true,
    content: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.event.text('title'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('EEE, d MMM yyyy · h:mm a')
                .format(widget.event.date('startsAt')),
          ),
          const SizedBox(height: 16),
          const Text(
            'The organizer hasn’t provided an end time. Choose how much time to reserve in your calendar.',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: minutes,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Time to reserve'),
            items: [30, 60, 90, 120, 180, 240]
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text('$value minutes'),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => minutes = value ?? 60),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Remind me 30 minutes before'),
            subtitle: const Text(
              'Included in the calendar file; supported calendars can use it.',
            ),
            value: reminder,
            onChanged: (value) => setState(() => reminder = value),
          ),
          const SizedBox(height: 12),
          const Text(
            'Open the exported .ics file in your calendar. Registration stays separate, and this calendar copy won’t update automatically.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Close'),
      ),
      Builder(
        builder: (buttonContext) => ActionButton(
          label: 'Export calendar file',
          icon: Icons.calendar_month_outlined,
          onPressed: () async {
            final box = buttonContext.findRenderObject()! as RenderBox;
            final exported = await (widget.export ?? _export)(
              EventCalendar.encode(
                widget.event,
                reservedTime: Duration(minutes: minutes),
                reminder: reminder,
                includeLink: widget.includeLink,
              ),
              box.localToGlobal(Offset.zero) & box.size,
            );
            if (context.mounted && exported) {
              Navigator.pop(context);
            }
          },
        ),
      ),
    ],
  );
}
