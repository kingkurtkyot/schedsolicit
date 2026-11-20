import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static DateTime toUtc(DateTime dt) => dt.isUtc ? dt : dt.toUtc();
  static DateTime toLocal(DateTime dt) => dt.isUtc ? dt.toLocal() : dt;

  static String formatDate(DateTime dt, {String pattern = 'MMM d, yyyy'}) {
    return DateFormat(pattern).format(toLocal(dt));
  }

  static String formatShortDate(DateTime dt) {
    return DateFormat('MMM d').format(toLocal(dt));
  }

  static String formatTime(DateTime dt, {bool is24Hour = false}) {
    return DateFormat(is24Hour ? 'HH:mm' : 'h:mm a').format(toLocal(dt));
  }

  static String formatDateTime(DateTime dt) {
    return DateFormat('MMM d, yyyy h:mm a').format(toLocal(dt));
  }

  static String formatRelative(DateTime target, {DateTime? base}) {
    final now = base ?? DateTime.now();
    final diff = target.difference(now);
    final isPast = diff.isNegative;
    final absDiff = diff.abs();

    if (absDiff.inSeconds < 60) {
      return isPast ? 'just now' : 'in a few seconds';
    } else if (absDiff.inMinutes < 60) {
      final m = absDiff.inMinutes;
      return isPast ? '$m min${m > 1 ? "s" : ""} ago' : 'in $m min${m > 1 ? "s" : ""}';
    } else if (absDiff.inHours < 24) {
      final h = absDiff.inHours;
      return isPast ? '$h hour${h > 1 ? "s" : ""} ago' : 'in $h hour${h > 1 ? "s" : ""}';
    } else if (absDiff.inDays < 7) {
      final d = absDiff.inDays;
      return isPast ? '$d day${d > 1 ? "s" : ""} ago' : 'in $d day${d > 1 ? "s" : ""}';
    } else if (absDiff.inDays < 30) {
      final w = (absDiff.inDays / 7).floor();
      return isPast ? '$w week${w > 1 ? "s" : ""} ago' : 'in $w week${w > 1 ? "s" : ""}';
    } else if (absDiff.inDays < 365) {
      final mo = (absDiff.inDays / 30).floor();
      return isPast ? '$mo month${mo > 1 ? "s" : ""} ago' : 'in $mo month${mo > 1 ? "s" : ""}';
    } else {
      final y = (absDiff.inDays / 365).floor();
      return isPast ? '$y year${y > 1 ? "s" : ""} ago' : 'in $y year${y > 1 ? "s" : ""}';
    }
  }

  static String formatGap(DateTime from, DateTime to, {String suffix = 'after'}) {
    final diffDays = to.difference(from).inDays.abs();
    if (diffDays == 0) return 'Same day';
    if (diffDays == 1) return '1 day $suffix';
    return '$diffDays days $suffix';
  }

  static String formatDateLine({
    required DateTime created,
    DateTime? eventDate,
    DateTime? deadline,
    DateTime? givenDate,
  }) {
    final createdStr = 'Made ${formatShortDate(created)}';
    if (givenDate != null) {
      return '$createdStr · Given ${formatShortDate(givenDate)}';
    }
    if (deadline != null) {
      return '$createdStr · Due ${formatShortDate(deadline)}';
    }
    if (eventDate != null) {
      return '$createdStr · On ${formatShortDate(eventDate)}';
    }
    return createdStr;
  }

  static DateTime addSafeMonths(DateTime dt, int months) {
    final rYear = dt.year + ((dt.month + months - 1) ~/ 12);
    final rMonth = ((dt.month + months - 1) % 12) + 1;
    final maxDaysInMonth = DateTime(rYear, rMonth + 1, 0).day;
    final rDay = dt.day > maxDaysInMonth ? maxDaysInMonth : dt.day;
    return DateTime(rYear, rMonth, rDay, dt.hour, dt.minute, dt.second);
  }
}
