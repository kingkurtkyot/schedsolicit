import '../../shared/models/base_item.dart';

class ScheduleItem extends BaseItem {
  final String? description;
  final DateTime eventDate;
  final String? startTime;
  final String? endTime;
  final bool allDay;
  final String? location;
  final String? repeatRule;
  final List<int> reminderOffsets;
  final String? notes;
  final DateTime? actualStart;
  final DateTime? actualEnd;
  final DateTime? sourceDate;

  const ScheduleItem({
    required super.id,
    required super.title,
    this.description,
    required this.eventDate,
    this.startTime,
    this.endTime,
    this.allDay = false,
    this.location,
    super.category,
    super.priority = 'medium',
    this.repeatRule,
    this.reminderOffsets = const [3600],
    required super.status,
    this.notes,
    this.actualStart,
    this.actualEnd,
    this.sourceDate,
    super.visibility = 'private',
    super.customFieldValues = const {},
    super.isDeleted = false,
    required super.createdAt,
    required super.updatedAt,
    super.completedAt,
  });

  @override
  bool get isOverdue {
    if (isDone) return false;
    final now = DateTime.now();
    return eventDate.isBefore(DateTime(now.year, now.month, now.day));
  }

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      eventDate: DateTime.parse(json['event_date'] as String),
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      allDay: json['all_day'] as bool? ?? false,
      location: json['location'] as String?,
      category: json['category'] as String?,
      priority: json['priority'] as String? ?? 'medium',
      repeatRule: json['repeat_rule'] as String?,
      reminderOffsets: (json['reminder_offsets'] as List<dynamic>?)?.cast<int>() ?? const [3600],
      status: json['status'] as String? ?? 'Active',
      notes: json['notes'] as String?,
      actualStart: json['actual_start'] != null ? DateTime.parse(json['actual_start'] as String) : null,
      actualEnd: json['actual_end'] != null ? DateTime.parse(json['actual_end'] as String) : null,
      sourceDate: json['source_date'] != null ? DateTime.parse(json['source_date'] as String) : null,
      visibility: json['visibility'] as String? ?? 'private',
      customFieldValues: (json['custom_field_values'] as Map<String, dynamic>?) ?? const {},
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'event_date': eventDate.toIso8601String(),
      'start_time': startTime,
      'end_time': endTime,
      'all_day': allDay,
      'location': location,
      'category': category,
      'priority': priority,
      'repeat_rule': repeatRule,
      'reminder_offsets': reminderOffsets,
      'status': status,
      'notes': notes,
      'actual_start': actualStart?.toIso8601String(),
      'actual_end': actualEnd?.toIso8601String(),
      'source_date': sourceDate?.toIso8601String(),
      'visibility': visibility,
      'custom_field_values': customFieldValues,
      'is_deleted': isDeleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}
