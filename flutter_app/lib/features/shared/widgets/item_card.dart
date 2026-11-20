import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/color_schemes.dart';
import '../models/base_item.dart';

class ItemCard extends StatelessWidget {
  final BaseItem item;
  final String dateLine;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String? subtitle;
  final String? extraAmount;
  final bool isOverdue;

  const ItemCard({
    super.key,
    required this.item,
    required this.dateLine,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.subtitle,
    this.extraAmount,
    this.isOverdue = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = AppColorSchemes.getStatusColor(item.status);
    final priorityColor = AppColorSchemes.getPriorityColor(item.priority);
    final priorityIcon = AppColorSchemes.getPriorityIcon(item.priority);

    return Semantics(
      label: '${item.title}, Status: ${item.status}, Priority: ${item.priority}',
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceMd,
          vertical: DesignTokens.spaceXs,
        ),
        child: Slidable(
          key: ValueKey(item.id),
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            children: [
              SlidableAction(
                onPressed: (_) => onEdit(),
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                icon: Icons.edit_outlined,
                label: 'Edit',
              ),
              SlidableAction(
                onPressed: (_) => onDelete(),
                backgroundColor: theme.colorScheme.errorContainer,
                foregroundColor: theme.colorScheme.onErrorContainer,
                icon: Icons.delete_outline,
                label: 'Delete',
              ),
            ],
          ),
          child: Material(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            elevation: DesignTokens.elevationLow,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              child: Container(
                constraints: const BoxConstraints(minHeight: 100),
                padding: const EdgeInsets.all(DesignTokens.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top row: Title + Priority + Status Chip
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: item.isDone ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: DesignTokens.spaceSm),
                        Icon(priorityIcon, size: 18, color: priorityColor),
                        const SizedBox(width: DesignTokens.spaceXs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.spaceSm,
                            vertical: DesignTokens.spaceXxs,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                            border: Border.all(color: statusColor.withOpacity(0.5)),
                          ),
                          child: Text(
                            item.status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: DesignTokens.spaceXs),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],

                    const SizedBox(height: DesignTokens.spaceSm),

                    // Bottom row: Date Line + Category + Amount
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            dateLine,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isOverdue ? DesignTokens.escalationDanger : theme.colorScheme.onSurfaceVariant,
                              fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (extraAmount != null) ...[
                          Text(
                            extraAmount!,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: DesignTokens.spaceSm),
                        ],
                        if (item.category != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DesignTokens.spaceSm,
                              vertical: DesignTokens.spaceXxs,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
                            ),
                            child: Text(
                              item.category!,
                              style: theme.textTheme.labelSmall,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
