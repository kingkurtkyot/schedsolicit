import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../models/base_item.dart';

class AgendaViewWidget<T extends BaseItem> extends StatelessWidget {
  final List<T> items;
  final String Function(T item) getItemTime;
  final bool Function(T item) isAllDay;
  final void Function(T item) onItemTap;

  const AgendaViewWidget({
    super.key,
    required this.items,
    required this.getItemTime,
    required this.isAllDay,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allDayItems = items.where(isAllDay).toList();
    final timedItems = items.where((it) => !isAllDay(it)).toList();

    return ListView(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      children: [
        if (allDayItems.isNotEmpty) ...[
          Text('ALL DAY', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: DesignTokens.spaceSm),
          for (final item in allDayItems)
            Card(
              margin: const EdgeInsets.only(bottom: DesignTokens.spaceSm),
              child: ListTile(
                title: Text(item.title),
                subtitle: Text(item.category ?? 'General'),
                trailing: const Icon(Icons.wb_sunny_outlined),
                onTap: () => onItemTap(item),
              ),
            ),
          const SizedBox(height: DesignTokens.spaceMd),
          const Divider(),
        ],

        Text('TIMED EVENTS', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: DesignTokens.spaceSm),
        for (final item in timedItems)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time Marker
              SizedBox(
                width: 70,
                child: Padding(
                  padding: const EdgeInsets.only(top: DesignTokens.spaceMd),
                  child: Text(
                    getItemTime(item),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              // Timeline vertical rule
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 70,
                    color: theme.colorScheme.outlineVariant,
                  ),
                ],
              ),
              const SizedBox(width: DesignTokens.spaceSm),
              // Item Details
              Expanded(
                child: Card(
                  margin: const EdgeInsets.only(bottom: DesignTokens.spaceSm),
                  child: ListTile(
                    title: Text(item.title),
                    subtitle: Text(item.status),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onItemTap(item),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
