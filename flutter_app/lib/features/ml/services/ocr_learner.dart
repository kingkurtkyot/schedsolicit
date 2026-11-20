import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class OcrLearner {
  final ApiClient? _apiClient;
  static const String _correctionsKey = 'ocr_user_corrections';

  OcrLearner({ApiClient? apiClient}) : _apiClient = apiClient;

  Future<void> recordCorrection({
    required String rawText,
    required String fieldKey,
    required dynamic correctedValue,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_correctionsKey) ?? [];

    final item = {
      'text': rawText,
      'field': fieldKey,
      'corrected': correctedValue,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };

    rawList.add(jsonEncode(item));
    await prefs.setStringList(_correctionsKey, rawList);

    // Sync to backend if available
    if (_apiClient != null) {
      try {
        await _apiClient!.post(
          ApiEndpoints.mlFeedback,
          data: item,
        );
      } catch (_) {}
    }
  }
}
