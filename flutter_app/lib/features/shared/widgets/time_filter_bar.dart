import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/filter_state.dart';
import '../providers/filter_provider.dart';

class TimeFilterBar extends ConsumerStatefulWidget {
  final String searchHint;

  const TimeFilterBar({
    super.key,
    this.searchHint = 'Search by title, location, category...',
  });

  @override
  ConsumerState<TimeFilterBar> createState() => _TimeFilterBarState();
}

class _TimeFilterBarState extends ConsumerState<TimeFilterBar> {
  late final TextEditingController _searchController;
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final currentQuery = ref.read(filterProvider).searchQuery ?? '';
    _searchController = TextEditingController(text: currentQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  bool _isSameYear(DateTime a, DateTime b) {
    return a.year == b.year;
  }

  String _formatAnchor(TimeFilterMode mode, DateTime anchor) {
    final now = DateTime.now();
    switch (mode) {
      case TimeFilterMode.day:
        final formatted = DateFormat('EEE, MMM d, yyyy').format(anchor);
        return _isSameDay(anchor, now) ? 'Today • $formatted' : formatted;
      case TimeFilterMode.month:
        final formatted = DateFormat('MMMM yyyy').format(anchor);
        return _isSameMonth(anchor, now) ? 'This Month • $formatted' : formatted;
      case TimeFilterMode.year:
        final formatted = DateFormat('yyyy').format(anchor);
        return _isSameYear(anchor, now) ? 'This Year • $formatted' : formatted;
      default:
        return 'All Dates';
    }
  }

  bool _isAnchorToday(TimeFilterMode mode, DateTime anchor) {
    final now = DateTime.now();
    switch (mode) {
      case TimeFilterMode.day:
        return _isSameDay(anchor, now);
      case TimeFilterMode.month:
        return _isSameMonth(anchor, now);
      case TimeFilterMode.year:
        return _isSameYear(anchor, now);
      default:
        return true;
    }
  }

  Future<void> _pickAnchorDate(BuildContext context, TimeFilterMode mode, DateTime currentAnchor) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentAnchor,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: mode == TimeFilterMode.day
          ? 'Select Day'
          : mode == TimeFilterMode.month
              ? 'Select Month'
              : 'Select Year',
    );

    if (picked != null) {
      HapticFeedback.selectionClick();
      ref.read(filterProvider.notifier).setTimeMode(mode, anchor: picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(filterProvider);
    final filterNotifier = ref.read(filterProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Sync search controller if cleared externally
    if (filter.searchQuery == null && _searchController.text.isNotEmpty) {
      _searchController.clear();
    }

    final isAll = filter.timeMode == TimeFilterMode.all;
    final isToday = _isAnchorToday(filter.timeMode, filter.selectedTimeAnchor);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Live Instant Search Bar
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surfaceContainerHigh : theme.colorScheme.surfaceContainerHighest.withOpacity(0.55),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.search, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: widget.searchHint,
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.65),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (text) {
                      filterNotifier.setSearchQuery(text);
                    },
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      filterNotifier.setSearchQuery(null);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(Icons.close, size: 18, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 2. Segmented Time Mode Tabs: [ All ] [ Day ] [ Month ] [ Year ]
          Row(
            children: [
              Expanded(
                child: SegmentedButton<TimeFilterMode>(
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: TimeFilterMode.all,
                      label: Text('All'),
                    ),
                    ButtonSegment(
                      value: TimeFilterMode.day,
                      label: Text('Day'),
                    ),
                    ButtonSegment(
                      value: TimeFilterMode.month,
                      label: Text('Month'),
                    ),
                    ButtonSegment(
                      value: TimeFilterMode.year,
                      label: Text('Year'),
                    ),
                  ],
                  selected: {
                    filter.timeMode == TimeFilterMode.custom ? TimeFilterMode.all : filter.timeMode
                  },
                  onSelectionChanged: (set) {
                    HapticFeedback.selectionClick();
                    filterNotifier.setTimeMode(set.first);
                  },
                ),
              ),
            ],
          ),

          // 3. Time Stepper Navigation (Active when Day, Month, or Year is selected)
          if (!isAll) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Previous Step (<)
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 24),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    tooltip: 'Previous ${filter.timeMode.name}',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      filterNotifier.previousTimeStep();
                    },
                  ),

                  // Center Date Badge / Picker Trigger
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _pickAnchorDate(context, filter.timeMode, filter.selectedTimeAnchor),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              filter.timeMode == TimeFilterMode.day
                                  ? Icons.today
                                  : filter.timeMode == TimeFilterMode.month
                                      ? Icons.calendar_month
                                      : Icons.calendar_today,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _formatAnchor(filter.timeMode, filter.selectedTimeAnchor),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Today Button (visible when not on current anchor)
                  if (!isToday)
                    Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          minimumSize: const Size(40, 28),
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          filterNotifier.jumpToToday();
                        },
                        child: const Text('Today', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),

                  // Next Step (>)
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 24),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    tooltip: 'Next ${filter.timeMode.name}',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      filterNotifier.nextTimeStep();
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
