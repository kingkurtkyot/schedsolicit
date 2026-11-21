import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'field_parser.dart';
import 'image_preprocessor.dart';

class RecognizedTextResult {
  final String fullText;
  final List<String> lines;
  final double confidence;
  final bool usedBackendFallback;
  final Map<String, dynamic> suggestedFields;

  const RecognizedTextResult({
    required this.fullText,
    required this.lines,
    this.confidence = 0.95,
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
    if (!kIsWeb && _textRecognizer != null) {
      String recognizedString = '';
      List<String> detectedLines = [];
      final tempDir = await getTemporaryDirectory();

      // -------------------------------------------------------------
      // Pass 1: Standard orientation-baked RGB pass
      // -------------------------------------------------------------
      File? tempFile1;
      try {
        tempFile1 = File('${tempDir.path}/ocr_pass1_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await tempFile1.writeAsBytes(imageBytes);

        final input1 = InputImage.fromFilePath(tempFile1.path);
        final res1 = await _textRecognizer!.processImage(input1);

        recognizedString = res1.text.trim();
        detectedLines = res1.blocks
            .expand((b) => b.lines)
            .map((l) => l.text.trim())
            .where((t) => t.isNotEmpty)
            .toList();
      } catch (e) {
        debugPrint('Pass 1 OCR error: $e');
      } finally {
        if (tempFile1 != null && await tempFile1.exists()) {
          tempFile1.delete().catchError((_) => tempFile1!);
        }
      }

      // -------------------------------------------------------------
      // Pass 2: High-contrast stretched pass (for faint cursive / metallic ink / gray font)
      // Triggered if Pass 1 found little or short text
      // -------------------------------------------------------------
      if (recognizedString.length < 25 || detectedLines.length < 3) {
        File? tempFile2;
        try {
          final enhancedBytes = await ImagePreprocessor.enhanceContrast(imageBytes);
          tempFile2 = File('${tempDir.path}/ocr_pass2_${DateTime.now().millisecondsSinceEpoch}.jpg');
          await tempFile2.writeAsBytes(enhancedBytes);

          final input2 = InputImage.fromFilePath(tempFile2.path);
          final res2 = await _textRecognizer!.processImage(input2);

          final pass2Text = res2.text.trim();
          final pass2Lines = res2.blocks
              .expand((b) => b.lines)
              .map((l) => l.text.trim())
              .where((t) => t.isNotEmpty)
              .toList();

          if (pass2Text.length > recognizedString.length || pass2Lines.length > detectedLines.length) {
            // Merge any unique lines discovered by Pass 1 that Pass 2 might have missed
            final merged = List<String>.from(pass2Lines);
            for (final line in detectedLines) {
              if (!merged.any((m) => m.toLowerCase().contains(line.toLowerCase()))) {
                merged.add(line);
              }
            }
            recognizedString = merged.join('\n');
            detectedLines = merged;
          }
        } catch (e) {
          debugPrint('Pass 2 OCR error: $e');
        } finally {
          if (tempFile2 != null && await tempFile2.exists()) {
            tempFile2.delete().catchError((_) => tempFile2!);
          }
        }
      }

      // -------------------------------------------------------------
      // Pass 3: Inverted pass for dark background cards / posters
      // -------------------------------------------------------------
      if (recognizedString.length < 20 || detectedLines.length < 2) {
        File? tempFile3;
        try {
          final invertedBytes = await ImagePreprocessor.enhanceInverted(imageBytes);
          tempFile3 = File('${tempDir.path}/ocr_pass3_${DateTime.now().millisecondsSinceEpoch}.jpg');
          await tempFile3.writeAsBytes(invertedBytes);

          final input3 = InputImage.fromFilePath(tempFile3.path);
          final res3 = await _textRecognizer!.processImage(input3);

          final pass3Text = res3.text.trim();
          if (pass3Text.length > recognizedString.length) {
            recognizedString = pass3Text;
            detectedLines = res3.blocks
                .expand((b) => b.lines)
                .map((l) => l.text.trim())
                .where((t) => t.isNotEmpty)
                .toList();
          }
        } catch (e) {
          debugPrint('Pass 3 OCR error: $e');
        } finally {
          if (tempFile3 != null && await tempFile3.exists()) {
            tempFile3.delete().catchError((_) => tempFile3!);
          }
        }
      }

      // Extract structured fields
      if (recognizedString.isNotEmpty) {
        final parsed = module == 'schedule'
            ? FieldParser.parseSchedule(recognizedString)
            : FieldParser.parseSolicitation(recognizedString);

        return RecognizedTextResult(
          fullText: recognizedString,
          lines: detectedLines,
          confidence: 0.96,
          usedBackendFallback: false,
          suggestedFields: parsed.fields,
        );
      }
    }

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
