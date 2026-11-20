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

  FilterNotifier() : super(const FilterState());

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
    state = state.copyWith(searchQuery: query);
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

  void setDateRange(DateTime? start, DateTime? end) {
    if (start != null && end != null) {
      state = state.copyWith(dateRange: null).copyWith(
        clearDateRange: false,
      );
      state = FilterState(
        dateRange: DateTimeRange(start: start, end: end),
        dayOfWeek: state.dayOfWeek,
        month: state.month,
        year: state.year,
        categories: state.categories,
        statuses: state.statuses,
        priorities: state.priorities,
        locations: state.locations,
        organizations: state.organizations,
        hasAttachment: state.hasAttachment,
        hasReminder: state.hasReminder,
        recurringOnly: state.recurringOnly,
        createdDateRange: state.createdDateRange,
        givenDateRange: state.givenDateRange,
        scope: state.scope,
        groupBy: state.groupBy,
        sortBy: state.sortBy,
        sortOrder: state.sortOrder,
        searchQuery: state.searchQuery,
      );
    } else {
      state = state.copyWith(clearDateRange: true);
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
