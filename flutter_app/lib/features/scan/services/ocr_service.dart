import 'dart:io';
import 'package:dio/dio.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class RecognizedTextResult {
  final String fullText;
  final List<String> lines;
  final double confidence;
  final bool usedBackendFallback;

  const RecognizedTextResult({
    required this.fullText,
    required this.lines,
    this.confidence = 0.9,
    this.usedBackendFallback = false,
  });
}

class OcrService {
  final ApiClient? _apiClient;
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  OcrService({ApiClient? apiClient}) : _apiClient = apiClient;

  Future<RecognizedTextResult> recognizeText(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      final fullText = recognizedText.text;
      final lines = <String>[];

      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          lines.add(line.text);
        }
      }

      if (fullText.trim().isNotEmpty) {
        return RecognizedTextResult(
          fullText: fullText,
          lines: lines,
          confidence: 0.92,
          usedBackendFallback: false,
        );
      }
    } catch (_) {
      // Fallback to backend OCR
    }

    // Backend fallback
    if (_apiClient != null) {
      try {
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(imageFile.path, filename: 'scan.jpg'),
        });

        final res = await _apiClient!.post(
          ApiEndpoints.ocrParse,
          data: formData,
        );

        if (res.statusCode == 200 && res.data != null) {
          final data = res.data as Map<String, dynamic>;
          final text = data['text'] as String? ?? '';
          final lines = (data['lines'] as List<dynamic>?)?.cast<String>() ?? text.split('\n');
          final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.85;

          return RecognizedTextResult(
            fullText: text,
            lines: lines,
            confidence: confidence,
            usedBackendFallback: true,
          );
        }
      } catch (_) {
        // Fallback failed
      }
    }

    return const RecognizedTextResult(
      fullText: '',
      lines: [],
      confidence: 0.0,
      usedBackendFallback: true,
    );
  }

  void dispose() {
    _textRecognizer.close();
  }
}
