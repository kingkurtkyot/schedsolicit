import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../shared/models/base_item.dart';

class CsvExporter {
  CsvExporter._();

  static Future<File> exportToCsv(List<BaseItem> items) async {
    final buffer = StringBuffer();
    // Headers
    buffer.writeln('ID,Title,Status,Priority,Category,Created At,Updated At');

    for (final item in items) {
      final safeTitle = item.title.replaceAll('"', '""');
      buffer.writeln(
        '"${item.id}","${safeTitle}","${item.status}","${item.priority}","${item.category ?? ""}","${item.createdAt.toIso8601String()}","${item.updatedAt.toIso8601String()}"',
      );
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/export_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(buffer.toString());
    return file;
  }
}
