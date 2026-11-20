import 'dart:io';
import 'package:share_plus/share_plus.dart';
import '../../shared/models/base_item.dart';
import 'csv_exporter.dart';
import 'json_exporter.dart';
import 'ics_exporter.dart';
import 'xlsx_exporter.dart';
import 'pdf_renderer.dart';
import 'png_renderer.dart';

enum ExportFormat { png, pdf, csv, xlsx, ics, json }

enum ExportLayout { list, grouped, calendar, poster }

enum ExportContentLevel { summary, full }

class ExportEngine {
  ExportEngine._();

  static Future<File> generateExport({
    required ExportFormat format,
    required List<BaseItem> items,
    ExportLayout layout = ExportLayout.list,
    ExportContentLevel contentLevel = ExportContentLevel.full,
    String title = 'SchedSolicit Export',
  }) async {
    switch (format) {
      case ExportFormat.csv:
        return CsvExporter.exportToCsv(items);
      case ExportFormat.json:
        return JsonExporter.exportToJson(items);
      case ExportFormat.ics:
        return IcsExporter.exportToIcs(items);
      case ExportFormat.xlsx:
        return XlsxExporter.exportToXlsx(items);
      case ExportFormat.pdf:
        return PdfRenderer.renderToPdf(items, title: title, contentLevel: contentLevel);
      case ExportFormat.png:
        return PngRenderer.renderToPng(items, title: title);
    }
  }

  static Future<void> shareFile(File file, {String subject = 'SchedSolicit Export'}) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: subject,
    );
  }
}
