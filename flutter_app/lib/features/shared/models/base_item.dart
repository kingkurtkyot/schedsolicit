abstract class BaseItem {
  final String id;
  final String title;
  final String status;
  final String priority;
  final String? category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final bool isDeleted;
  final String visibility;
  final Map<String, dynamic> customFieldValues;

  const BaseItem({
    required this.id,
    required this.title,
    required this.status,
    this.priority = 'medium',
    this.category,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.isDeleted = false,
    this.visibility = 'private',
    this.customFieldValues = const {},
  });

  bool get isDone => status == 'Done' || status == 'Given';
  bool get isOverdue;

  Map<String, dynamic> toJson();
}
