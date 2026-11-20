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
          vertical: 5.0,
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
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              ),
              SlidableAction(
                onPressed: (_) => onDelete(),
                backgroundColor: theme.colorScheme.errorContainer,
                foregroundColor: theme.colorScheme.onErrorContainer,
                icon: Icons.delete_outline,
                label: 'Delete',
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
              ),
            ],
          ),
          child: Material(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            elevation: 1,
            shadowColor: Colors.black.withOpacity(0.08),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left status accent strip
                      Container(
                        width: 5,
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                      ),

                      // Card Content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
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
                                        fontSize: 15,
                                        decoration: item.isDone ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(priorityIcon, size: 16, color: priorityColor),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
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
                                const SizedBox(height: 4),
                                Text(
                                  subtitle!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],

                              const SizedBox(height: 10),

                              // Bottom row: Date Line + Category + Amount
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: isOverdue ? DesignTokens.escalationDanger : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      dateLine,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: isOverdue ? DesignTokens.escalationDanger : theme.colorScheme.onSurfaceVariant,
                                        fontWeight: isOverdue ? FontWeight.bold : FontWeight.w500,
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
                                    const SizedBox(width: 8),
                                  ],
                                  if (item.category != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        item.category!,
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
