class SmartDefaults {
  SmartDefaults._();

  static Map<String, dynamic> getDefaultsForCategory(String? category) {
    if (category == null) return {};

    switch (category.toLowerCase()) {
      case 'work':
        return {
          'location': 'Conference Room',
          'duration_minutes': 60,
          'priority': 'medium',
          'reminder_offsets': [3600],
        };
      case 'donation':
      case 'grant':
        return {
          'priority': 'high',
          'reminder_offsets': [86400, 3600],
        };
      default:
        return {
          'priority': 'medium',
          'reminder_offsets': [3600],
        };
    }
  }
}
