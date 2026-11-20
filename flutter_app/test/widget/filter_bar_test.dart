import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedsolicit/features/shared/providers/filter_provider.dart';
import 'package:schedsolicit/features/shared/widgets/filter_bar.dart';

void main() {
  group('FilterBar Widget Tests', () {
    testWidgets('displays active chips and updates count badge', (tester) async {
      final container = ProviderContainer();
      container.read(filterProvider.notifier).toggleCategory('Work');
      container.read(filterProvider.notifier).toggleStatus('Active');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: FilterBar(resultCount: 15),
            ),
          ),
        ),
      );

      expect(find.text('Filters (15)'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Clear All'), findsOneWidget);

      // Tap clear all
      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();

      expect(container.read(filterProvider).hasActiveFilters, false);
    });
  });
}
