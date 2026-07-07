import 'package:device_calendar/device_calendar.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class DeviceImportService {
  Future<List<Map<String, dynamic>>> fetchContacts() async {
    if (!await FlutterContacts.requestPermission()) return [];
    final contacts = await FlutterContacts.getContacts(withProperties: true);
    return contacts
        .where((c) => c.displayName.trim().isNotEmpty)
        .map(
          (c) => {
            'name': c.displayName.trim(),
            'external_id': c.id,
            'relationship': 'Contact',
            'popia_consent': false,
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchCalendarEvents({int daysAhead = 365}) async {
    final plugin = DeviceCalendarPlugin();
    final permitted = await plugin.hasPermissions();
    if (permitted.isSuccess && !permitted.data!) {
      final requested = await plugin.requestPermissions();
      if (!requested.isSuccess || !requested.data!) return [];
    }

    final calendarsResult = await plugin.retrieveCalendars();
    if (!calendarsResult.isSuccess || calendarsResult.data == null) return [];

    final now = DateTime.now();
    final end = now.add(Duration(days: daysAhead));
    final events = <Map<String, dynamic>>[];

    for (final cal in calendarsResult.data!) {
      final result = await plugin.retrieveEvents(
        cal.id,
        RetrieveEventsParams(startDate: now, endDate: end),
      );
      if (!result.isSuccess || result.data == null) continue;
      for (final event in result.data!) {
        if (event.title == null || event.title!.trim().isEmpty) continue;
        final start = event.start;
        if (start == null) continue;
        final type = _guessOccasionType(event.title!);
        events.add({
          'title': event.title!.trim(),
          'recipient_name': _extractRecipientName(event.title!),
          'date': start.toIso8601String(),
          'external_id': event.eventId ?? '',
          'type': type,
          'popia_consent': false,
        });
      }
    }
    return events;
  }

  String _guessOccasionType(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('birthday') || lower.contains('bday')) return 'birthday';
    if (lower.contains('anniversary')) return 'anniversary';
    return 'other';
  }

  String _extractRecipientName(String title) {
    final lower = title.toLowerCase();
    for (final prefix in ["birthday", "anniversary", "'s", "s "]) {
      if (lower.contains(prefix)) {
        return title.split(RegExp(r"['\-–:]")).first.trim();
      }
    }
    return title.trim();
  }
}