import 'dart:convert';
import 'dart:typed_data';

import '../../models/campus_item.dart';

/// A personal calendar copy; the selected duration is not an organizer end time.
class EventCalendar {
  static Uint8List encode(
    CampusItem event, {
    required Duration reservedTime,
    bool reminder = false,
    bool includeLink = true,
    DateTime? generatedAt,
  }) {
    if (reservedTime.inMinutes < 15 || reservedTime.inMinutes > 1440) {
      throw ArgumentError('Reserve between 15 minutes and 24 hours.');
    }
    final start = event.date('startsAt').toUtc();
    final url = Uri.https(
      'student-connect-ppsu-2026.web.app',
      '/events/${event.id}',
    );
    final description =
        '${event.text('description')}\n\n'
        'Personal calendar copy. The organizer has not supplied an end time; '
        '${reservedTime.inMinutes} minutes have been reserved in your calendar. '
        'This copy does not update automatically. Check Student Connect for changes.';
    final lines = [
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//Student Connect//Campus events//EN',
      'CALSCALE:GREGORIAN',
      'BEGIN:VEVENT',
      'UID:${Uri.encodeComponent(event.id)}@student-connect-ppsu-2026.web.app',
      'DTSTAMP:${_date(generatedAt ?? DateTime.now())}',
      'DTSTART:${_date(start)}',
      'DTEND:${_date(start.add(reservedTime))}',
      'SUMMARY:${_text(event.text('title'))}',
      'LOCATION:${_text(event.text('location'))}',
      'DESCRIPTION:${_text(description)}',
      if (includeLink) 'URL:$url',
      'CLASS:PRIVATE',
      if (reminder) ...[
        'BEGIN:VALARM',
        'TRIGGER:-PT30M',
        'ACTION:DISPLAY',
        'DESCRIPTION:Campus event starts in 30 minutes',
        'END:VALARM',
      ],
      'END:VEVENT',
      'END:VCALENDAR',
    ];
    return Uint8List.fromList(
      utf8.encode('${lines.map(_fold).join('\r\n')}\r\n'),
    );
  }

  static String _date(DateTime value) {
    final utc = value.toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${utc.year.toString().padLeft(4, '0')}${two(utc.month)}${two(utc.day)}T${two(utc.hour)}${two(utc.minute)}${two(utc.second)}Z';
  }

  static String _text(String value) => value
      .replaceAll('\\', r'\\')
      .replaceAll(RegExp(r'\r\n|\r|\n'), r'\n')
      .replaceAll(';', r'\;')
      .replaceAll(',', r'\,')
      .replaceAll(RegExp('[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]'), '');

  // RFC 5545 content lines are folded at 75 UTF-8 octets, never mid-codepoint.
  static String _fold(String line) {
    final output = StringBuffer();
    var length = 0;
    for (final rune in line.runes) {
      final character = String.fromCharCode(rune);
      final size = utf8.encode(character).length;
      if (length + size > 75) {
        output.write('\r\n ');
        length = 1;
      }
      output.write(character);
      length += size;
    }
    return output.toString();
  }
}
