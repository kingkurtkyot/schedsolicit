class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String authLogin = '/api/auth/login';
  static const String authRefresh = '/api/auth/refresh';
  static const String authMe = '/api/auth/me';

  // Schedules
  static const String schedules = '/api/schedules';
  static String scheduleDetail(String id) => '/api/schedules/$id';
  static String scheduleRestore(String id) => '/api/schedules/$id/restore';
  static String scheduleDuplicate(String id) => '/api/schedules/$id/duplicate';
  static const String schedulesBulk = '/api/schedules/bulk';

  // Solicitations
  static const String solicitations = '/api/solicitations';
  static String solicitationDetail(String id) => '/api/solicitations/$id';
  static String solicitationRestore(String id) => '/api/solicitations/$id/restore';
  static String solicitationDuplicate(String id) => '/api/solicitations/$id/duplicate';
  static const String solicitationsBulk = '/api/solicitations/bulk';

  // Sync
  static const String syncPush = '/api/sync/push';
  static const String syncPull = '/api/sync/pull';

  // ML & OCR
  static const String mlSuggest = '/api/ml/suggest';
  static const String mlDefaults = '/api/ml/defaults';
  static const String mlFeedback = '/api/ml/feedback';
  static const String ocrParse = '/api/ocr/parse';

  // Sharing
  static const String shareLinks = '/api/share-links';
  static String shareLinkDetail(String id) => '/api/share-links/$id';
  static String shareLinkRevoke(String id) => '/api/share-links/$id/revoke';
  static String shareLinkRegenerate(String id) => '/api/share-links/$id/regenerate';

  // Audit Logs
  static const String auditLogs = '/api/audit-logs';
  static String auditTimeline(String itemId) => '/api/audit-logs/timeline/$itemId';

  // Export
  static const String export = '/api/export';
}
