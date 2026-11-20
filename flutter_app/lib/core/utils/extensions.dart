import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import 'date_utils.dart';

extension DateTimeExtensions on DateTime {
  DateTime get toUtcIso => AppDateUtils.toUtc(this);
  DateTime get toLocalUi => AppDateUtils.toLocal(this);
  String toFormattedDate({String pattern = 'MMM d, yyyy'}) =>
      AppDateUtils.formatDate(this, pattern: pattern);
  String toRelative({DateTime? base}) => AppDateUtils.formatRelative(this, base: base);

  bool isSameDay(DateTime other) {
    final localA = toLocalUi;
    final localB = other.toLocalUi;
    return localA.year == localB.year &&
        localA.month == localB.month &&
        localA.day == localB.day;
  }
}

extension StringExtensions on String {
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  double? toParsedCurrency() {
    final sanitized = replaceAll(RegExp(r'[\$,]'), '').trim();
    return double.tryParse(sanitized);
  }
}

extension BuildContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;

  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  bool get isCompact => screenWidth < DesignTokens.breakpointCompact;
  bool get isMedium =>
      screenWidth >= DesignTokens.breakpointCompact &&
      screenWidth < DesignTokens.breakpointMedium;
  bool get isExpanded => screenWidth >= DesignTokens.breakpointMedium;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
