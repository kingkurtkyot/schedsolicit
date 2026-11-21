import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedsolicit/features/shared/models/filter_state.dart';
import 'package:schedsolicit/features/shared/providers/filter_provider.dart';
import 'package:schedsolicit/features/schedule/providers/schedule_provider.dart';
import 'package:schedsolicit/features/solicitation/providers/solicitation_provider.dart';

void main() {
  test('FilterNotifier time navigation: Day, Month, Year stepping', () {
    final container = ProviderContainer();
    final notifier = container.read(filterProvider.notifier);

    // Initial state
    expect(container.read(filterProvider).timeMode, TimeFilterMode.all);
    expect(container.read(filterProvider).dateRange, isNull);

    // Set Day mode with anchor Nov 21, 2026
    final testDate = DateTime(2026, 11, 21, 15, 30);
    notifier.setTimeMode(TimeFilterMode.day, anchor: testDate);

    var state = container.read(filterProvider);
    expect(state.timeMode, TimeFilterMode.day);
    expect(state.dateRange?.start, DateTime(2026, 11, 21, 0, 0, 0));
    expect(state.dateRange?.end, DateTime(2026, 11, 21, 23, 59, 59));

    // Next day -> Nov 22, 2026
    notifier.nextTimeStep();
    state = container.read(filterProvider);
    expect(state.dateRange?.start, DateTime(2026, 11, 22, 0, 0, 0));
    expect(state.dateRange?.end, DateTime(2026, 11, 22, 23, 59, 59));

    // Previous day twice -> Nov 20, 2026
    notifier.previousTimeStep();
    notifier.previousTimeStep();
    state = container.read(filterProvider);
    expect(state.dateRange?.start, DateTime(2026, 11, 20, 0, 0, 0));

    // Switch to Month mode -> Nov 2026
    notifier.setTimeMode(TimeFilterMode.month, anchor: testDate);
    state = container.read(filterProvider);
    expect(state.timeMode, TimeFilterMode.month);
    expect(state.dateRange?.start, DateTime(2026, 11, 1, 0, 0, 0));
    expect(state.dateRange?.end, DateTime(2026, 11, 30, 23, 59, 59));

    // Next month -> Dec 2026
    notifier.nextTimeStep();
    state = container.read(filterProvider);
    expect(state.dateRange?.start, DateTime(2026, 12, 1, 0, 0, 0));
    expect(state.dateRange?.end, DateTime(2026, 12, 31, 23, 59, 59));

    // Switch to Year mode -> 2026
    notifier.setTimeMode(TimeFilterMode.year, anchor: testDate);
    state = container.read(filterProvider);
    expect(state.timeMode, TimeFilterMode.year);
    expect(state.dateRange?.start, DateTime(2026, 1, 1, 0, 0, 0));
    expect(state.dateRange?.end, DateTime(2026, 12, 31, 23, 59, 59));

    // Search query
    notifier.setSearchQuery('Board Meeting');
    expect(container.read(filterProvider).searchQuery, 'Board Meeting');
  });

  test('Schedule & Solicitation providers react to search and time filters', () async {
    final container = ProviderContainer();
    final filterNotifier = container.read(filterProvider.notifier);

    // Initial load has samples
    final initialSchedules = container.read(scheduleListProvider).value!;
    expect(initialSchedules.isNotEmpty, true);

    // Search for non-existent text
    filterNotifier.setSearchQuery('NonExistentTitleXYZ');
    var filtered = container.read(scheduleListProvider).value!;
    expect(filtered.isEmpty, true);

    // Clear search
    filterNotifier.setSearchQuery(null);
    filtered = container.read(scheduleListProvider).value!;
    expect(filtered.isNotEmpty, true);

    // Search for "Board"
    filterNotifier.setSearchQuery('Board');
    filtered = container.read(scheduleListProvider).value!;
    expect(filtered.length, 1);
    expect(filtered.first.title.contains('Board'), true);

    // Clear search before testing solicitations
    filterNotifier.setSearchQuery(null);
    final initialSolicitations = container.read(solicitationListProvider).value!;
    expect(initialSolicitations.isNotEmpty, true);

    filterNotifier.setSearchQuery('Tech Education');
    final filteredSol = container.read(solicitationListProvider).value!;
    expect(filteredSol.length, 1);
    expect(filteredSol.first.title.contains('Tech'), true);
  });
}
