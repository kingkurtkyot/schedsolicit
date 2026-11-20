class ShareLink {
  final String id;
  final String token;
  final String label;
  final String module; // schedule | solicitation | both
  final Map<String, dynamic> scope;
  final Map<String, dynamic> privacyControls;
  final DateTime? expiresAt;
  final int? viewLimit;
  final int viewCount;
  final bool allowExport;
  final bool isRevoked;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ShareLink({
    required this.id,
    required this.token,
    required this.label,
    this.module = 'both',
    this.scope = const {},
    this.privacyControls = const {},
    this.expiresAt,
    this.viewLimit,
    this.viewCount = 0,
    this.allowExport = true,
    this.isRevoked = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  factory ShareLink.fromJson(Map<String, dynamic> json) {
    return ShareLink(
      id: json['id'] as String,
      token: json['token'] as String,
      label: json['label'] as String,
      module: json['module'] as String? ?? 'both',
      scope: (json['scope'] as Map<String, dynamic>?) ?? const {},
      privacyControls: (json['privacy_controls'] as Map<String, dynamic>?) ?? const {},
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : null,
      viewLimit: json['view_limit'] as int?,
      viewCount: json['view_count'] as int? ?? 0,
      allowExport: json['allow_export'] as bool? ?? true,
      isRevoked: json['is_revoked'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'token': token,
      'label': label,
      'module': module,
      'scope': scope,
      'privacy_controls': privacyControls,
      'expires_at': expiresAt?.toIso8601String(),
      'view_limit': viewLimit,
      'view_count': viewCount,
      'allow_export': allowExport,
      'is_revoked': isRevoked,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
