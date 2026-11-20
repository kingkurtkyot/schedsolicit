import 'package:flutter_test/flutter_test.dart';
import 'package:schedsolicit/core/utils/date_utils.dart';

void main() {
  group('AppDateUtils Tests', () {
    test('UTC to Local conversions', () {
      final utc = DateTime.utc(2026, 11, 20, 10, 0);
      final local = AppDateUtils.toLocal(utc);
      expect(local.isUtc, false);

      final backToUtc = AppDateUtils.toUtc(local);
      expect(backToUtc.isUtc, true);
      expect(backToUtc.year, 2026);
    });

    test('relative date formatting', () {
      final now = DateTime(2026, 11, 20, 12, 0);
      final past = now.subtract(const Duration(minutes: 15));
      final future = now.add(const Duration(hours: 3));

      expect(AppDateUtils.formatRelative(past, base: now), '15 mins ago');
      expect(AppDateUtils.formatRelative(future, base: now), 'in 3 hours');
    });

    test('date line formatting', () {
      final created = DateTime(2026, 3, 3);
      final deadline = DateTime(2026, 3, 20);

      final line = AppDateUtils.formatDateLine(created: created, deadline: deadline);
      expect(line, 'Made Mar 3 · Due Mar 20');
    });

    test('safe months addition handles month end dates correctly', () {
      final jan31 = DateTime(2026, 1, 31);
      final feb = AppDateUtils.addSafeMonths(jan31, 1);
      expect(feb.month, 2);
      expect(feb.day, 28); // 2026 is non-leap year
    });
  });
}
