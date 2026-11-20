import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/filter_state.dart';
import '../../shared/providers/filter_provider.dart';
import '../models/schedule_item.dart';

final scheduleListProvider = StateNotifierProvider<ScheduleListNotifier, AsyncValue<List<ScheduleItem>>>((ref) {
  return ScheduleListNotifier(ref);
});

class ScheduleListNotifier extends StateNotifier<AsyncValue<List<ScheduleItem>>> {
  final Ref ref;
  List<ScheduleItem> _allSchedules = [];

  ScheduleListNotifier(this.ref) : super(const AsyncValue.loading()) {
    // Listen to filter changes to re-evaluate filtered list
    ref.listen<FilterState>(filterProvider, (_, __) {
      _applyFilter();
    });
    _loadSampleData();
  }

  void _loadSampleData() {
    final now = DateTime.now();
    _allSchedules = [
      ScheduleItem(
        id: 'sch-1',
        title: 'Board Meeting & Sponsor Review',
        description: 'Quarterly review with primary campaign sponsors and partners.',
        eventDate: now.add(const Duration(hours: 3)),
        startTime: '10:00',
        endTime: '11:30',
        location: 'Main Conference Room B',
        category: 'Work',
        priority: 'urgent',
        status: 'Active',
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      ScheduleItem(
        id: 'sch-2',
        title: 'Community Fundraiser Gala',
        description: 'Annual charity dinner and donation presentation.',
        eventDate: now.add(const Duration(days: 2)),
        startTime: '18:00',
        endTime: '21:00',
        location: 'City Grand Hotel Ballroom',
        category: 'Donation',
        priority: 'high',
        status: 'Active',
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      ScheduleItem(
        id: 'sch-3',
        title: 'Volunteer Orientation Workshop',
        description: 'Introduction session for new solicitations volunteers.',
        eventDate: now.subtract(const Duration(days: 3)),
        startTime: '14:00',
        endTime: '15:30',
        location: 'Community Center Hall 1',
        category: 'Personal',
        priority: 'medium',
        status: 'Done',
        completedAt: now.subtract(const Duration(days: 3)),
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
    ];
    _applyFilter();
  }

  void _applyFilter() {
    final filter = ref.read(filterProvider);
    var filtered = _allSchedules.where((item) {
      if (item.isDeleted) return false;

      // Scope
      if (filter.scope == FilterScope.active && item.isDone) return false;
      if (filter.scope == FilterScope.history && !item.isDone) return false;

      // Status
      if (filter.statuses.isNotEmpty && !filter.statuses.contains(item.status)) return false;

      // Priority
      if (filter.priorities.isNotEmpty && !filter.priorities.contains(item.priority)) return false;

      // Category
      if (filter.categories.isNotEmpty && item.category != null && !filter.categories.contains(item.category)) {
        return false;
      }

      // Search Query
      if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
        final q = filter.searchQuery!.toLowerCase();
        final match = item.title.toLowerCase().contains(q) ||
            (item.description?.toLowerCase().contains(q) ?? false) ||
            (item.location?.toLowerCase().contains(q) ?? false);
        if (!match) return false;
      }

      // Date Range
      if (filter.dateRange != null) {
        if (item.eventDate.isBefore(filter.dateRange!.start) || item.eventDate.isAfter(filter.dateRange!.end)) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort
    filtered.sort((a, b) {
      switch (filter.sortBy) {
        case SortBy.date:
          return filter.sortOrder == SortOrder.asc
              ? a.eventDate.compareTo(b.eventDate)
              : b.eventDate.compareTo(a.eventDate);
        case SortBy.priority:
          return a.priority.compareTo(b.priority);
        case SortBy.title:
          return a.title.compareTo(b.title);
        case SortBy.createdAt:
          return a.createdAt.compareTo(b.createdAt);
      }
    });

    state = AsyncValue.data(filtered);
  }

  void addItem(ScheduleItem item) {
    _allSchedules.insert(0, item);
    _applyFilter();
  }

  void updateItem(ScheduleItem item) {
    final index = _allSchedules.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _allSchedules[index] = item;
      _applyFilter();
    }
  }

  void deleteItem(String id) {
    _allSchedules.removeWhere((i) => i.id == id);
    _applyFilter();
  }

  ScheduleItem? getById(String id) {
    return _allSchedules.where((i) => i.id == id).firstOrNull;
  }
}
