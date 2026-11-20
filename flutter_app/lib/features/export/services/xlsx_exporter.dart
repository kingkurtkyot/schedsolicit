import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../../shared/models/base_item.dart';

class XlsxExporter {
  XlsxExporter._();

  static Future<File> exportToXlsx(List<BaseItem> items) async {
    final excel = Excel.createExcel();
    final sheet = excel['Export'];
    excel.setDefaultSheet('Export');

    // Headers
    sheet.appendRow([
      TextCellValue('ID'),
      TextCellValue('Title'),
      TextCellValue('Status'),
      TextCellValue('Priority'),
      TextCellValue('Category'),
      TextCellValue('Created At'),
    ]);

    for (final item in items) {
      sheet.appendRow([
        TextCellValue(item.id),
        TextCellValue(item.title),
        TextCellValue(item.status),
        TextCellValue(item.priority),
        TextCellValue(item.category ?? ''),
        TextCellValue(item.createdAt.toIso8601String()),
      ]);
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/export_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }
    return file;
  }
}
