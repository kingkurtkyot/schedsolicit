import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../shared/models/base_item.dart';
import '../../schedule/models/schedule_item.dart';

class IcsExporter {
  IcsExporter._();

  static Future<File> exportToIcs(List<BaseItem> items) async {
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//SchedSolicit//OwnerApp//EN');

    for (final item in items) {
      if (item is ScheduleItem) {
        final startIso = _formatIcsDate(item.eventDate);
        buffer.writeln('BEGIN:VEVENT');
        buffer.writeln('UID:${item.id}@schedsolicit.com');
        buffer.writeln('SUMMARY:${item.title}');
        if (item.description != null) buffer.writeln('DESCRIPTION:${item.description}');
        if (item.location != null) buffer.writeln('LOCATION:${item.location}');
        buffer.writeln('DTSTART:$startIso');
        buffer.writeln('DTEND:$startIso');
        buffer.writeln('STATUS:${item.status.toUpperCase()}');
        buffer.writeln('END:VEVENT');
      }
    }

    buffer.writeln('END:VCALENDAR');

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/export_${DateTime.now().millisecondsSinceEpoch}.ics');
    await file.writeAsString(buffer.toString());
    return file;
  }

  static String _formatIcsDate(DateTime dt) {
    final u = dt.toUtc();
    return '${u.year}${u.month.toString().padLeft(2, '0')}${u.day.toString().padLeft(2, '0')}T${u.hour.toString().padLeft(2, '0')}${u.minute.toString().padLeft(2, '0')}${u.second.toString().padLeft(2, '0')}Z';
  }
}
