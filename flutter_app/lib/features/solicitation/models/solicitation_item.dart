import '../../shared/models/base_item.dart';

class SolicitationItem extends BaseItem {
  final String? organization;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? purpose;
  final double? amountRequested;
  final String? quantityRequested;
  final DateTime? requestedDate;
  final DateTime? deadline;
  final DateTime? followUpDate;
  final String? location;
  final String? notes;

  // Fulfillment / Given fields
  final DateTime? givenDate;
  final double? givenAmount;
  final String? givenItem;
  final String? givenBy;
  final String? givenTo;
  final DateTime? sourceDate;

  const SolicitationItem({
    required super.id,
    required super.title,
    this.organization,
    this.contactPerson,
    this.phone,
    this.email,
    this.purpose,
    this.amountRequested,
    this.quantityRequested,
    this.requestedDate,
    this.deadline,
    this.followUpDate,
    required super.status,
    super.priority = 'medium',
    super.category,
    this.location,
    this.notes,
    this.givenDate,
    this.givenAmount,
    this.givenItem,
    this.givenBy,
    this.givenTo,
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
    if (isDone || deadline == null) return false;
    final now = DateTime.now();
    return deadline!.isBefore(DateTime(now.year, now.month, now.day));
  }

  factory SolicitationItem.fromJson(Map<String, dynamic> json) {
    return SolicitationItem(
      id: json['id'] as String,
      title: json['title'] as String,
      organization: json['organization'] as String?,
      contactPerson: json['contact_person'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      purpose: json['purpose'] as String?,
      amountRequested: (json['amount_requested'] as num?)?.toDouble(),
      quantityRequested: json['quantity_requested'] as String?,
      requestedDate: json['requested_date'] != null ? DateTime.parse(json['requested_date'] as String) : null,
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline'] as String) : null,
      followUpDate: json['follow_up_date'] != null ? DateTime.parse(json['follow_up_date'] as String) : null,
      status: json['status'] as String? ?? 'Draft',
      priority: json['priority'] as String? ?? 'medium',
      category: json['category'] as String?,
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      givenDate: json['given_date'] != null ? DateTime.parse(json['given_date'] as String) : null,
      givenAmount: (json['given_amount'] as num?)?.toDouble(),
      givenItem: json['given_item'] as String?,
      givenBy: json['given_by'] as String?,
      givenTo: json['given_to'] as String?,
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
      'organization': organization,
      'contact_person': contactPerson,
      'phone': phone,
      'email': email,
      'purpose': purpose,
      'amount_requested': amountRequested,
      'quantity_requested': quantityRequested,
      'requested_date': requestedDate?.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'follow_up_date': followUpDate?.toIso8601String(),
      'status': status,
      'priority': priority,
      'category': category,
      'location': location,
      'notes': notes,
      'given_date': givenDate?.toIso8601String(),
      'given_amount': givenAmount,
      'given_item': givenItem,
      'given_by': givenBy,
      'given_to': givenTo,
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
