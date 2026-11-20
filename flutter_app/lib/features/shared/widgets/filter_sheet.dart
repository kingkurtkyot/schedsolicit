import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/color_schemes.dart';
import '../providers/filter_provider.dart';
import '../models/filter_state.dart';

class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({super.key});

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  final TextEditingController _presetController = TextEditingController();

  @override
  void dispose() {
    _presetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(filterProvider);
    final notifier = ref.read(filterProvider.notifier);
    final theme = Theme.of(context);

    final isMediumOrExpanded = MediaQuery.sizeOf(context).width >= DesignTokens.breakpointCompact;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        maxWidth: isMediumOrExpanded ? 500 : double.infinity,
      ),
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filter Items', style: theme.textTheme.titleLarge),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(),

          Expanded(
            child: ListView(
              children: [
                // Scope
                Text('Scope', style: theme.textTheme.titleSmall),
                const SizedBox(height: DesignTokens.spaceSm),
                SegmentedButton<FilterScope>(
                  segments: const [
                    ButtonSegment(value: FilterScope.active, label: Text('Active')),
                    ButtonSegment(value: FilterScope.history, label: Text('History')),
                    ButtonSegment(value: FilterScope.all, label: Text('All')),
                  ],
                  selected: {filter.scope},
                  onSelectionChanged: (set) => notifier.setScope(set.first),
                ),
                const SizedBox(height: DesignTokens.spaceLg),

                // Priorities
                Text('Priority', style: theme.textTheme.titleSmall),
                const SizedBox(height: DesignTokens.spaceSm),
                Wrap(
                  spacing: DesignTokens.spaceSm,
                  children: ['low', 'medium', 'high', 'urgent'].map((p) {
                    final isSelected = filter.priorities.contains(p);
                    final color = AppColorSchemes.getPriorityColor(p);
                    return FilterChip(
                      label: Text(p.toUpperCase()),
                      selected: isSelected,
                      avatar: Icon(AppColorSchemes.getPriorityIcon(p), size: 16, color: isSelected ? Colors.white : color),
                      onSelected: (_) => notifier.togglePriority(p),
                    );
                  }).toList(),
                ),
                const SizedBox(height: DesignTokens.spaceLg),

                // Common Statuses
                Text('Status', style: theme.textTheme.titleSmall),
                const SizedBox(height: DesignTokens.spaceSm),
                Wrap(
                  spacing: DesignTokens.spaceSm,
                  children: ['Active', 'Draft', 'Sent', 'Pending', 'Approved', 'Given', 'Done', 'Cancelled'].map((s) {
                    final isSelected = filter.statuses.contains(s);
                    return FilterChip(
                      label: Text(s),
                      selected: isSelected,
                      onSelected: (_) => notifier.toggleStatus(s),
                    );
                  }).toList(),
                ),
                const SizedBox(height: DesignTokens.spaceLg),

                // Date Range Button
                Text('Date Range', style: theme.textTheme.titleSmall),
                const SizedBox(height: DesignTokens.spaceSm),
                OutlinedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    filter.dateRange != null
                        ? '${filter.dateRange!.start.month}/${filter.dateRange!.start.day} - ${filter.dateRange!.end.month}/${filter.dateRange!.end.day}'
                        : 'Select Date Range',
                  ),
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      initialDateRange: filter.dateRange,
                    );
                    if (picked != null) {
                      notifier.setDateRange(picked.start, picked.end);
                    }
                  },
                ),
                const SizedBox(height: DesignTokens.spaceLg),

                // Group By & Sort By
                Text('Group & Sort', style: theme.textTheme.titleSmall),
                const SizedBox(height: DesignTokens.spaceSm),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<GroupBy>(
                        value: filter.groupBy,
                        decoration: const InputDecoration(labelText: 'Group By'),
                        items: GroupBy.values
                            .map((g) => DropdownMenuItem(value: g, child: Text(g.name.toUpperCase())))
                            .toList(),
                        onChanged: (g) => g != null ? notifier.setGroupBy(g) : null,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spaceMd),
                    Expanded(
                      child: DropdownButtonFormField<SortBy>(
                        value: filter.sortBy,
                        decoration: const InputDecoration(labelText: 'Sort By'),
                        items: SortBy.values
                            .map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase())))
                            .toList(),
                        onChanged: (s) => s != null ? notifier.setSortBy(s) : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          const SizedBox(height: DesignTokens.spaceMd),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    notifier.reset();
                  },
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: DesignTokens.spaceMd),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
