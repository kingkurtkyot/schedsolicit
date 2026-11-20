enum FieldType {
  text,
  textarea,
  date,
  time,
  datetime,
  checkbox,
  dropdown,
  currency,
  phone,
  email,
  repeat,
  reminders,
}

enum FieldSection {
  basic,
  contact,
  timing,
  details,
  request,
  fulfillment,
  tracking,
  meta,
}

class FieldDefinition {
  final String key;
  final String label;
  final FieldType type;
  final bool required;
  final int? maxLength;
  final FieldSection section;
  final int? searchWeight;
  final List<String>? options;
  final dynamic defaultValue;
  final Map<String, dynamic>? dependsOn;
  final bool useCustomCategories;
  final bool readOnly;

  const FieldDefinition({
    required this.key,
    required this.label,
    required this.type,
    this.required = false,
    this.maxLength,
    required this.section,
    this.searchWeight,
    this.options,
    this.defaultValue,
    this.dependsOn,
    this.useCustomCategories = false,
    this.readOnly = false,
  });

  bool isVisible(Map<String, dynamic> formValues) {
    if (dependsOn == null || dependsOn!.isEmpty) return true;
    for (final entry in dependsOn!.entries) {
      final actual = formValues[entry.key];
      if (actual != entry.value) {
        return false;
      }
    }
    return true;
  }
}
