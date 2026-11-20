import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import '../../shared/models/base_item.dart';
import '../../../core/theme/design_tokens.dart';
import '../widgets/export_card_template.dart';

class PngRenderer {
  PngRenderer._();

  static Future<File> renderToPng(
    List<BaseItem> items, {
    String title = 'SchedSolicit Export',
  }) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/export_${DateTime.now().millisecondsSinceEpoch}.png');

    // Create custom offscreen widget tree matching 1080px canvas
    final exportWidget = MediaQuery(
      data: const MediaQueryData(size: Size(DesignTokens.exportCanvasWidth, 1920)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Container(
          width: DesignTokens.exportCanvasWidth,
          color: DesignTokens.surfaceLight,
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: DesignTokens.colorEmerald,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.eco, size: 48, color: Colors.white),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Generated on ${DateTime.now().toLocal().toString().split(".")[0]}',
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              for (final item in items) ...[
                ExportCardTemplate(item: item),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );

    final repaintBoundary = RenderRepaintBoundary();
    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());

    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: exportWidget,
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();

    pipelineOwner.rootNode = repaintBoundary;
    repaintBoundary.layout(const BoxConstraints(maxWidth: DesignTokens.exportCanvasWidth));

    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final image = await repaintBoundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    await file.writeAsBytes(pngBytes);
    return file;
  }
}
