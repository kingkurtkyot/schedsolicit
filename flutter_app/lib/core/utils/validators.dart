class FormValidators {
  FormValidators._();

  static String? required(String? value, [String message = 'This field is required']) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? email(String? value, [String message = 'Invalid email address']) {
    if (value == null || value.trim().isEmpty) return null;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return message;
    }
    return null;
  }

  static String? phone(String? value, [String message = 'Invalid phone number']) {
    if (value == null || value.trim().isEmpty) return null;
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{7,20}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return message;
    }
    return null;
  }

  static String? url(String? value, [String message = 'Invalid URL']) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      return message;
    }
    return null;
  }

  static String? minLength(String? value, int min, [String? message]) {
    if (value == null || value.length < min) {
      return message ?? 'Must be at least $min characters';
    }
    return null;
  }

  static String? maxLength(String? value, int max, [String? message]) {
    if (value != null && value.length > max) {
      return message ?? 'Must be no more than $max characters';
    }
    return null;
  }

  static String? currency(String? value, [String message = 'Invalid currency amount']) {
    if (value == null || value.trim().isEmpty) return null;
    final sanitized = value.replaceAll(RegExp(r'[\$,]'), '').trim();
    if (double.tryParse(sanitized) == null) {
      return message;
    }
    return null;
  }

  static String? dateOrder(DateTime? start, DateTime? end, [String message = 'End must be after start']) {
    if (start != null && end != null && end.isBefore(start)) {
      return message;
    }
    return null;
  }
}
