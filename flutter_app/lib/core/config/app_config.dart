class AppConfig {
  AppConfig._();

  static const String appName = 'SchedSolicit';
  static const String appVersion = '1.0.0';

  // Base API URL
  static const String defaultApiBaseUrl = 'http://127.0.0.1:8000';
  static const Duration apiTimeout = Duration(seconds: 15);
  static const int apiMaxRetries = 3;

  // Sync Configuration
  static const Duration syncInterval = Duration(minutes: 5);
  static const Duration syncDebounce = Duration(seconds: 2);
  static const int syncBatchSize = 50;

  // Reminders Defaults (offsets in seconds: 1 hour default)
  static const List<int> defaultScheduleReminderOffsets = [3600];
  static const List<int> defaultSolicitationReminderOffsets = [86400]; // 1 day before deadline

  // OCR and ML Confidence Thresholds
  static const double ocrConfidenceThreshold = 0.65;
  static const double mlConfidenceThreshold = 0.70;

  // Quiet Hours (22:00 to 07:00 default)
  static const int quietHoursStart = 22;
  static const int quietHoursEnd = 7;

  // Pagination
  static const int defaultPageSize = 25;
  static const int maxPageSize = 100;

  // Escaping / Escalation windows
  static const Duration escalationSafeWindow = Duration(hours: 1);
  static const Duration escalationWarningWindow = Duration(minutes: 15);
}
