import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/design_tokens.dart';
import '../models/base_item.dart';
import '../models/filter_state.dart';
import 'item_card.dart';
import 'empty_state.dart';

class GroupedListView<T extends BaseItem> extends StatelessWidget {
  final List<T> items;
  final GroupBy groupBy;
  final DateTime Function(T item)? getItemDate;
  final Future<void> Function() onRefresh;
  final void Function(T item) onItemTap;
  final void Function(T item) onItemEdit;
  final void Function(T item) onItemDelete;

  const GroupedListView({
    super.key,
    required this.items,
    this.groupBy = GroupBy.none,
    this.getItemDate,
    required this.onRefresh,
    required this.onItemTap,
    required this.onItemEdit,
    required this.onItemDelete,
  });

  Map<String, List<T>> _groupItems() {
    final groups = <String, List<T>>{};
    for (final item in items) {
      String key = 'All Items';
      switch (groupBy) {
        case GroupBy.category:
          key = item.category ?? 'Uncategorized';
          break;
        case GroupBy.status:
          key = item.status;
          break;
        case GroupBy.priority:
          key = item.priority.toUpperCase();
          break;
        case GroupBy.date:
          if (getItemDate != null) {
            key = DateFormat('EEEE, MMM d, yyyy').format(getItemDate!(item));
          }
          break;
        case GroupBy.month:
          if (getItemDate != null) {
            key = DateFormat('MMMM yyyy').format(getItemDate!(item));
          }
          break;
        case GroupBy.none:
          key = 'All';
          break;
      }
      groups.putIfAbsent(key, () => []).add(item);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            EmptyState(message: 'No items match your filter criteria'),
          ],
        ),
      );
    }

    final grouped = _groupItems();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        slivers: [
          for (final group in grouped.entries) ...[
            if (groupBy != GroupBy.none)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.spaceLg,
                    DesignTokens.spaceLg,
                    DesignTokens.spaceLg,
                    DesignTokens.spaceSm,
                  ),
                  child: Text(
                    '${group.key} (${group.value.length})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            SliverList.builder(
              itemCount: group.value.length,
              itemBuilder: (context, index) {
                final item = group.value[index];
                return ItemCard(
                  item: item,
                  dateLine: getItemDate != null
                      ? DateFormat('MMM d, yyyy').format(getItemDate!(item))
                      : 'Active',
                  onTap: () => onItemTap(item),
                  onEdit: () => onItemEdit(item),
                  onDelete: () => onItemDelete(item),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
