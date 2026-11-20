import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class SuggestionResult {
  final String? category;
  final String? priority;
  final double confidence;

  const SuggestionResult({this.category, this.priority, this.confidence = 0.8});
}

class Categorizer {
  final ApiClient? _apiClient;

  Categorizer({ApiClient? apiClient}) : _apiClient = apiClient;

  Future<SuggestionResult> suggestCategoryAndPriority({
    required String title,
    String? description,
    required String module,
  }) async {
    if (_apiClient != null) {
      try {
        final res = await _apiClient!.post(
          ApiEndpoints.mlSuggest,
          data: {
            'title': title,
            'description': description,
            'module': module,
          },
        );

        if (res.statusCode == 200 && res.data != null) {
          final data = res.data as Map<String, dynamic>;
          return SuggestionResult(
            category: data['category'] as String?,
            priority: data['priority'] as String?,
            confidence: (data['confidence'] as num?)?.toDouble() ?? 0.85,
          );
        }
      } catch (_) {}
    }

    // Local heuristic fallback
    final lower = '$title ${description ?? ""}'.toLowerCase();
    String cat = 'General';
    String prio = 'medium';

    if (lower.contains('urgent') || lower.contains('asap') || lower.contains('deadline')) {
      prio = 'urgent';
    } else if (lower.contains('sponsor') || lower.contains('fund') || lower.contains('grant')) {
      cat = 'Donation';
      prio = 'high';
    } else if (lower.contains('meeting') || lower.contains('conference') || lower.contains('review')) {
      cat = 'Work';
    }

    return SuggestionResult(category: cat, priority: prio, confidence: 0.70);
  }
}
