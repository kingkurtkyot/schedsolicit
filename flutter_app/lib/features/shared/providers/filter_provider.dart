import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/filter_state.dart';

final filterProvider = StateNotifierProvider<FilterNotifier, FilterState>((ref) {
  return FilterNotifier();
});

class FilterNotifier extends StateNotifier<FilterState> {
  static const String _presetsKey = 'saved_filter_presets';

  FilterNotifier() : super(FilterState());

  void setScope(FilterScope scope) {
    state = state.copyWith(scope: scope);
  }

  void setGroupBy(GroupBy groupBy) {
    state = state.copyWith(groupBy: groupBy);
  }

  void setSortBy(SortBy sortBy, {SortOrder? order}) {
    state = state.copyWith(sortBy: sortBy, sortOrder: order ?? state.sortOrder);
  }

  void setSearchQuery(String? query) {
    final clean = (query != null && query.trim().isNotEmpty) ? query.trim() : null;
    state = state.copyWith(searchQuery: clean, clearSearchQuery: clean == null);
  }

  void toggleCategory(String category) {
    final updated = Set<String>.from(state.categories);
    if (updated.contains(category)) {
      updated.remove(category);
    } else {
      updated.add(category);
    }
    state = state.copyWith(categories: updated);
  }

  void toggleStatus(String status) {
    final updated = Set<String>.from(state.statuses);
    if (updated.contains(status)) {
      updated.remove(status);
    } else {
      updated.add(status);
    }
    state = state.copyWith(statuses: updated);
  }

  void togglePriority(String priority) {
    final updated = Set<String>.from(state.priorities);
    if (updated.contains(priority)) {
      updated.remove(priority);
    } else {
      updated.add(priority);
    }
    state = state.copyWith(priorities: updated);
  }

  /// Sets time filter mode: All, Day-to-Day, Month-to-Month, Year-to-Year
  void setTimeMode(TimeFilterMode mode, {DateTime? anchor}) {
    final targetAnchor = anchor ?? state.selectedTimeAnchor;
    DateTimeRange? computedRange;

    switch (mode) {
      case TimeFilterMode.all:
        computedRange = null;
        break;
      case TimeFilterMode.day:
        computedRange = DateTimeRange(
          start: DateTime(targetAnchor.year, targetAnchor.month, targetAnchor.day, 0, 0, 0),
          end: DateTime(targetAnchor.year, targetAnchor.month, targetAnchor.day, 23, 59, 59),
        );
        break;
      case TimeFilterMode.month:
        final lastDay = DateTime(targetAnchor.year, targetAnchor.month + 1, 0).day;
        computedRange = DateTimeRange(
          start: DateTime(targetAnchor.year, targetAnchor.month, 1, 0, 0, 0),
          end: DateTime(targetAnchor.year, targetAnchor.month, lastDay, 23, 59, 59),
        );
        break;
      case TimeFilterMode.year:
        computedRange = DateTimeRange(
          start: DateTime(targetAnchor.year, 1, 1, 0, 0, 0),
          end: DateTime(targetAnchor.year, 12, 31, 23, 59, 59),
        );
        break;
      case TimeFilterMode.custom:
        computedRange = state.dateRange;
        break;
    }

    state = state.copyWith(
      timeMode: mode,
      selectedTimeAnchor: targetAnchor,
      dateRange: computedRange,
      clearDateRange: computedRange == null,
    );
  }

  /// Navigate back by one time step (previous Day, Month, or Year)
  void previousTimeStep() {
    final anchor = state.selectedTimeAnchor;
    DateTime newAnchor;

    switch (state.timeMode) {
      case TimeFilterMode.day:
        newAnchor = anchor.subtract(const Duration(days: 1));
        break;
      case TimeFilterMode.month:
        newAnchor = DateTime(anchor.year, anchor.month - 1, 1);
        break;
      case TimeFilterMode.year:
        newAnchor = DateTime(anchor.year - 1, 1, 1);
        break;
      default:
        return;
    }

    setTimeMode(state.timeMode, anchor: newAnchor);
  }

  /// Navigate forward by one time step (next Day, Month, or Year)
  void nextTimeStep() {
    final anchor = state.selectedTimeAnchor;
    DateTime newAnchor;

    switch (state.timeMode) {
      case TimeFilterMode.day:
        newAnchor = anchor.add(const Duration(days: 1));
        break;
      case TimeFilterMode.month:
        newAnchor = DateTime(anchor.year, anchor.month + 1, 1);
        break;
      case TimeFilterMode.year:
        newAnchor = DateTime(anchor.year + 1, 1, 1);
        break;
      default:
        return;
    }

    setTimeMode(state.timeMode, anchor: newAnchor);
  }

  void jumpToToday() {
    setTimeMode(state.timeMode == TimeFilterMode.all ? TimeFilterMode.day : state.timeMode, anchor: DateTime.now());
  }

  void setDateRange(DateTime? start, DateTime? end) {
    if (start != null && end != null) {
      state = state.copyWith(
        timeMode: TimeFilterMode.custom,
        dateRange: DateTimeRange(start: start, end: end),
      );
    } else {
      state = state.copyWith(
        timeMode: TimeFilterMode.all,
        clearDateRange: true,
      );
    }
  }

  void reset() {
    state = FilterState(scope: state.scope);
  }

  Future<void> savePreset(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_presetsKey);
    final map = raw != null ? jsonDecode(raw) as Map<String, dynamic> : <String, dynamic>{};
    map[name] = state.toQueryParams();
    await prefs.setString(_presetsKey, jsonEncode(map));
  }

  Future<Map<String, dynamic>> loadPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_presetsKey);
    if (raw == null) return {};
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}
