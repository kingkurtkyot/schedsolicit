import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../shared/models/base_item.dart';

class JsonExporter {
  JsonExporter._();

  static Future<File> exportToJson(List<BaseItem> items) async {
    final list = items.map((i) => i.toJson()).toList();
    final jsonStr = const JsonEncoder.withIndent('  ').convert({
      'version': '1.0',
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'items_count': items.length,
      'items': list,
    });

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/export_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonStr);
    return file;
  }
}
