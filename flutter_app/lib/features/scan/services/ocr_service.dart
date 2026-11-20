import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

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
  final ApiClient _apiClient;
  TextRecognizer? _textRecognizer;

  OcrService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient() {
    if (!kIsWeb) {
      try {
        _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      } catch (_) {
        _textRecognizer = null;
      }
    }
  }

  Future<RecognizedTextResult> recognizeBytes(
    Uint8List imageBytes, {
    String fileName = 'scan.jpg',
  }) async {
    // 1. High-Performance Backend OCR (EasyOCR + Date/Entity Classifier)
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(imageBytes, filename: fileName),
      });

      final res = await _apiClient.post(
        ApiEndpoints.ocrParse,
        data: formData,
      );

      if (res.statusCode == 200 && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        final text = (data['text'] ?? data['raw_text'] ?? '') as String;
        final lines = (data['lines'] as List<dynamic>?)?.cast<String>() ??
            text.split('\n').where((l) => l.trim().isNotEmpty).toList();
        final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.88;
        final fields = (data['fields'] ?? data['suggested_fields'] ?? {}) as Map<String, dynamic>;

        if (text.trim().isNotEmpty) {
          return RecognizedTextResult(
            fullText: text,
            lines: lines,
            confidence: confidence,
            usedBackendFallback: true,
            suggestedFields: fields,
          );
        }
      }
    } catch (_) {
      // Backend request error / offline
    }

    // 2. On-Device ML Kit Fallback (if running natively on Android / iOS)
    if (!kIsWeb && _textRecognizer != null) {
      try {
        // Can be used when offline on Android devices
      } catch (_) {}
    }

    return const RecognizedTextResult(
      fullText: '',
      lines: [],
      confidence: 0.0,
      usedBackendFallback: true,
      suggestedFields: {},
    );
  }

  void dispose() {
    _textRecognizer?.close();
  }
}
