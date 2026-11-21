import 'package:flutter/material.dart';

enum FilterScope { active, history, all }

enum GroupBy { none, date, month, category, status, priority }

enum SortBy { date, priority, title, createdAt }

enum SortOrder { asc, desc }

enum TimeFilterMode { all, day, month, year, custom }

class FilterState {
  final DateTimeRange? dateRange;
  final TimeFilterMode timeMode;
  final DateTime? _selectedTimeAnchor;
  DateTime get selectedTimeAnchor => _selectedTimeAnchor ?? DateTime.now();
  final Set<int> dayOfWeek;
  final int? month;
  final int? year;
  final Set<String> categories;
  final Set<String> statuses;
  final Set<String> priorities;
  final Set<String> locations;
  final Set<String> organizations;
  final bool? hasAttachment;
  final bool? hasReminder;
  final bool? recurringOnly;
  final DateTimeRange? createdDateRange;
  final DateTimeRange? givenDateRange;
  final FilterScope scope;
  final GroupBy groupBy;
  final SortBy sortBy;
  final SortOrder sortOrder;
  final String? searchQuery;

  const FilterState({
    this.dateRange,
    this.timeMode = TimeFilterMode.all,
    DateTime? selectedTimeAnchor,
    this.dayOfWeek = const {},
    this.month,
    this.year,
    this.categories = const {},
    this.statuses = const {},
    this.priorities = const {},
    this.locations = const {},
    this.organizations = const {},
    this.hasAttachment,
    this.hasReminder,
    this.recurringOnly,
    this.createdDateRange,
    this.givenDateRange,
    this.scope = FilterScope.active,
    this.groupBy = GroupBy.none,
    this.sortBy = SortBy.date,
    this.sortOrder = SortOrder.asc,
    this.searchQuery,
  }) : _selectedTimeAnchor = selectedTimeAnchor;

  bool get hasActiveFilters {
    return dateRange != null ||
        timeMode != TimeFilterMode.all ||
        categories.isNotEmpty ||
        statuses.isNotEmpty ||
        priorities.isNotEmpty ||
        locations.isNotEmpty ||
        organizations.isNotEmpty ||
        (searchQuery != null && searchQuery!.trim().isNotEmpty);
  }

  int get activeFilterCount {
    int count = 0;
    if (dateRange != null || timeMode != TimeFilterMode.all) count++;
    if (categories.isNotEmpty) count += categories.length;
    if (statuses.isNotEmpty) count += statuses.length;
    if (priorities.isNotEmpty) count += priorities.length;
    if (locations.isNotEmpty) count += locations.length;
    if (organizations.isNotEmpty) count += organizations.length;
    if (searchQuery != null && searchQuery!.trim().isNotEmpty) count++;
    return count;
  }

  FilterState copyWith({
    DateTimeRange? dateRange,
    bool clearDateRange = false,
    TimeFilterMode? timeMode,
    DateTime? selectedTimeAnchor,
    Set<int>? dayOfWeek,
    int? month,
    bool clearMonth = false,
    int? year,
    bool clearYear = false,
    Set<String>? categories,
    Set<String>? statuses,
    Set<String>? priorities,
    Set<String>? locations,
    Set<String>? organizations,
    bool? hasAttachment,
    bool clearHasAttachment = false,
    bool? hasReminder,
    bool clearHasReminder = false,
    bool? recurringOnly,
    bool clearRecurringOnly = false,
    DateTimeRange? createdDateRange,
    bool clearCreatedDateRange = false,
    DateTimeRange? givenDateRange,
    bool clearGivenDateRange = false,
    FilterScope? scope,
    GroupBy? groupBy,
    SortBy? sortBy,
    SortOrder? sortOrder,
    String? searchQuery,
    bool clearSearchQuery = false,
  }) {
    return FilterState(
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      timeMode: timeMode ?? this.timeMode,
      selectedTimeAnchor: selectedTimeAnchor ?? this.selectedTimeAnchor,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      month: clearMonth ? null : (month ?? this.month),
      year: clearYear ? null : (year ?? this.year),
      categories: categories ?? this.categories,
      statuses: statuses ?? this.statuses,
      priorities: priorities ?? this.priorities,
      locations: locations ?? this.locations,
      organizations: organizations ?? this.organizations,
      hasAttachment: clearHasAttachment ? null : (hasAttachment ?? this.hasAttachment),
      hasReminder: clearHasReminder ? null : (hasReminder ?? this.hasReminder),
      recurringOnly: clearRecurringOnly ? null : (recurringOnly ?? this.recurringOnly),
      createdDateRange: clearCreatedDateRange ? null : (createdDateRange ?? this.createdDateRange),
      givenDateRange: clearGivenDateRange ? null : (givenDateRange ?? this.givenDateRange),
      scope: scope ?? this.scope,
      groupBy: groupBy ?? this.groupBy,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
    );
  }

  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    if (searchQuery != null && searchQuery!.isNotEmpty) params['q'] = searchQuery!;
    if (categories.isNotEmpty) params['categories'] = categories.join(',');
    if (statuses.isNotEmpty) params['statuses'] = statuses.join(',');
    if (priorities.isNotEmpty) params['priorities'] = priorities.join(',');
    if (dateRange != null) {
      params['start_date'] = dateRange!.start.toIso8601String();
      params['end_date'] = dateRange!.end.toIso8601String();
    }
    params['scope'] = scope.name;
    params['time_mode'] = timeMode.name;
    params['sort_by'] = sortBy.name;
    params['sort_order'] = sortOrder.name;
    return params;
  }
}
