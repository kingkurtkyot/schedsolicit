import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'field_parser.dart';

class RecognizedTextResult {
  final String fullText;
  final List<String> lines;
  final double confidence;
  final bool usedBackendFallback;
  final Map<String, dynamic> suggestedFields;

  const RecognizedTextResult({
    required this.fullText,
    required this.lines,
    this.confidence = 0.9,
    this.usedBackendFallback = false,
    this.suggestedFields = const {},
  });
}

class OcrService {
  TextRecognizer? _textRecognizer;

  OcrService() {
    if (!kIsWeb) {
      try {
        _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      } catch (e) {
        debugPrint('Failed to initialize on-device TextRecognizer: $e');
        _textRecognizer = null;
      }
    }
  }

  Future<RecognizedTextResult> recognizeBytes(
    Uint8List imageBytes, {
    String? filePath,
    String fileName = 'scan.jpg',
    String module = 'schedule',
  }) async {
    // -------------------------------------------------------------
    // 1. Mobile Native: On-Device Google ML Kit (100% Offline & Instant)
    // -------------------------------------------------------------
    if (!kIsWeb && _textRecognizer != null) {
      File? tempFile;
      try {
        final InputImage inputImage;
        if (filePath != null && filePath.isNotEmpty && await File(filePath).exists()) {
          inputImage = InputImage.fromFilePath(filePath);
        } else {
          final tempDir = await getTemporaryDirectory();
          tempFile = File('${tempDir.path}/ocr_${DateTime.now().millisecondsSinceEpoch}.jpg');
          await tempFile.writeAsBytes(imageBytes);
          inputImage = InputImage.fromFilePath(tempFile.path);
        }

        final recognizedText = await _textRecognizer!.processImage(inputImage);

        // Clean up temp file if created
        if (tempFile != null) {
          tempFile.delete().catchError((_) => tempFile!);
        }

        final fullText = recognizedText.text.trim();
        if (fullText.isNotEmpty) {
          final lines = recognizedText.blocks
              .expand((b) => b.lines)
              .map((l) => l.text.trim())
              .where((t) => t.isNotEmpty)
              .toList();

          // Auto-parse fields on-device
          final parsed = module == 'schedule'
              ? FieldParser.parseSchedule(fullText)
              : FieldParser.parseSolicitation(fullText);

          return RecognizedTextResult(
            fullText: fullText,
            lines: lines,
            confidence: 0.95,
            usedBackendFallback: false,
            suggestedFields: parsed.fields,
          );
        }
      } catch (e) {
        debugPrint('On-device ML Kit recognition error: $e');
        if (tempFile != null) {
          tempFile.delete().catchError((_) => tempFile!);
        }
      }
    }

    // -------------------------------------------------------------
    // 2. No readable text found — return honest empty result (No dummy hallucinations)
    // -------------------------------------------------------------
    return const RecognizedTextResult(
      fullText: '',
      lines: [],
      confidence: 0.0,
      usedBackendFallback: false,
      suggestedFields: {},
    );
  }

  void dispose() {
    _textRecognizer?.close();
  }
}
