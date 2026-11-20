class ConflictResolver {
  ConflictResolver._();

  /// Resolve conflict using Last-Write-Wins based on updatedAt
  static Map<String, dynamic> resolveLastWriteWins({
    required Map<String, dynamic> clientData,
    required Map<String, dynamic> serverData,
  }) {
    final clientUpdated = DateTime.tryParse(clientData['updated_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
    final serverUpdated = DateTime.tryParse(serverData['updated_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);

    if (clientUpdated.isAfter(serverUpdated)) {
      return Map<String, dynamic>.from(clientData);
    } else {
      return Map<String, dynamic>.from(serverData);
    }
  }

  /// Field-level merge: prefer non-null newer values, preserve client edits when server field didn't change
  static Map<String, dynamic> resolveFieldLevelMerge({
    required Map<String, dynamic> baseData,
    required Map<String, dynamic> clientData,
    required Map<String, dynamic> serverData,
  }) {
    final merged = Map<String, dynamic>.from(serverData);

    for (final key in clientData.keys) {
      final baseVal = baseData[key];
      final clientVal = clientData[key];
      final serverVal = serverData[key];

      // If client modified field and server didn't, keep client value
      if (clientVal != baseVal && serverVal == baseVal) {
        merged[key] = clientVal;
      }
    }

    merged['updated_at'] = DateTime.now().toUtc().toIso8601String();
    return merged;
  }
}
