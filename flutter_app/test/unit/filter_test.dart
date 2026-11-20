import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedsolicit/features/shared/models/filter_state.dart';

void main() {
  group('FilterState Unit Tests', () {
    test('initial state has no active filters', () {
      const state = FilterState();
      expect(state.hasActiveFilters, false);
      expect(state.activeFilterCount, 0);
    });

    test('setting filters correctly flags hasActiveFilters and activeFilterCount', () {
      final now = DateTime.now();
      final state = const FilterState().copyWith(
        categories: {'Work', 'Donation'},
        statuses: {'Active'},
        dateRange: DateTimeRange(start: now, end: now.add(const Duration(days: 7))),
      );

      expect(state.hasActiveFilters, true);
      // 2 categories + 1 status + 1 date range = 4
      expect(state.activeFilterCount, 4);
    });

    test('toQueryParams serializes all active query keys', () {
      final state = const FilterState().copyWith(
        searchQuery: 'grant',
        categories: {'Finance'},
        statuses: {'Pending'},
        priorities: {'urgent'},
        scope: FilterScope.active,
        sortBy: SortBy.priority,
      );

      final params = state.toQueryParams();
      expect(params['q'], 'grant');
      expect(params['categories'], 'Finance');
      expect(params['statuses'], 'Pending');
      expect(params['priorities'], 'urgent');
      expect(params['scope'], 'active');
      expect(params['sort_by'], 'priority');
    });

    test('clearing filters resets state correctly', () {
      final state = const FilterState().copyWith(
        categories: {'Work'},
        searchQuery: 'test',
      );
      expect(state.activeFilterCount, 2);

      final cleared = state.copyWith(
        categories: {},
        clearSearchQuery: true,
      );
      expect(cleared.hasActiveFilters, false);
    });
  });
}
