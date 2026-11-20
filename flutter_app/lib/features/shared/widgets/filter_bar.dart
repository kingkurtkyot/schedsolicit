import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_tokens.dart';
import '../providers/filter_provider.dart';
import 'filter_sheet.dart';

class FilterBar extends ConsumerWidget {
  final int resultCount;
  final VoidCallback? onClearAll;

  const FilterBar({
    super.key,
    required this.resultCount,
    this.onClearAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(filterProvider);
    final theme = Theme.of(context);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Filter count chip / trigger
          ActionChip(
            avatar: Badge(
              label: Text('${filterState.activeFilterCount}'),
              isLabelVisible: filterState.hasActiveFilters,
              child: const Icon(Icons.filter_list, size: 18),
            ),
            label: Text('Filters (${resultCount})'),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => const FilterSheet(),
              );
            },
          ),
          const SizedBox(width: DesignTokens.spaceSm),

          // Active filter removable chips
          for (final cat in filterState.categories)
            Padding(
              padding: const EdgeInsets.only(right: DesignTokens.spaceSm),
              child: InputChip(
                label: Text(cat),
                onDeleted: () => ref.read(filterProvider.notifier).toggleCategory(cat),
              ),
            ),

          for (final status in filterState.statuses)
            Padding(
              padding: const EdgeInsets.only(right: DesignTokens.spaceSm),
              child: InputChip(
                label: Text(status),
                onDeleted: () => ref.read(filterProvider.notifier).toggleStatus(status),
              ),
            ),

          for (final priority in filterState.priorities)
            Padding(
              padding: const EdgeInsets.only(right: DesignTokens.spaceSm),
              child: InputChip(
                label: Text(priority),
                onDeleted: () => ref.read(filterProvider.notifier).togglePriority(priority),
              ),
            ),

          if (filterState.dateRange != null)
            Padding(
              padding: const EdgeInsets.only(right: DesignTokens.spaceSm),
              child: InputChip(
                label: const Text('Custom Dates'),
                onDeleted: () => ref.read(filterProvider.notifier).setDateRange(null, null),
              ),
            ),

          if (filterState.hasActiveFilters)
            TextButton(
              onPressed: () {
                ref.read(filterProvider.notifier).reset();
                onClearAll?.call();
              },
              child: const Text('Clear All'),
            ),
        ],
      ),
    );
  }
}
