import 'dart:io';
import 'package:flutter/material.dart';
import '../services/export_engine.dart';

class ExportPreviewScreen extends StatelessWidget {
  final Map<String, dynamic>? config;

  const ExportPreviewScreen({super.key, this.config});

  @override
  Widget build(BuildContext context) {
    final filePath = config?['file_path'] as String?;
    final format = config?['format'] as String? ?? 'file';
    final count = config?['items_count'] as int? ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Ready'),
        actions: [
          if (filePath != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => ExportEngine.shareFile(File(filePath)),
            ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                'Successfully Exported $count Items',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Format: ${format.toUpperCase()}'),
              if (filePath != null) ...[
                const SizedBox(height: 8),
                Text(
                  filePath,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('Share / Save File'),
                onPressed: filePath != null ? () => ExportEngine.shareFile(File(filePath)) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
