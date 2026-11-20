import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/design_tokens.dart';

class SummaryStrip extends StatelessWidget {
  final int totalCount;
  final double? totalGivenAmount;
  final double? totalRequestedAmount;
  final double? approvalRate;
  final Map<String, int> countPerStatus;

  const SummaryStrip({
    super.key,
    required this.totalCount,
    this.totalGivenAmount,
    this.totalRequestedAmount,
    this.approvalRate,
    this.countPerStatus = const {},
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.compactSimpleCurrency();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceMd,
        vertical: DesignTokens.spaceSm,
      ),
      color: theme.colorScheme.surfaceContainer,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatChip(
              context,
              label: 'Total Items',
              value: '$totalCount',
              icon: Icons.list_alt,
            ),
            if (totalGivenAmount != null) ...[
              const SizedBox(width: DesignTokens.spaceSm),
              _buildStatChip(
                context,
                label: 'Given',
                value: currencyFormat.format(totalGivenAmount),
                icon: Icons.card_giftcard,
                highlightColor: theme.colorScheme.primary,
              ),
            ],
            if (totalRequestedAmount != null) ...[
              const SizedBox(width: DesignTokens.spaceSm),
              _buildStatChip(
                context,
                label: 'Requested',
                value: currencyFormat.format(totalRequestedAmount),
                icon: Icons.request_quote_outlined,
              ),
            ],
            if (approvalRate != null) ...[
              const SizedBox(width: DesignTokens.spaceSm),
              _buildStatChip(
                context,
                label: 'Approval',
                value: '${(approvalRate! * 100).toStringAsFixed(0)}%',
                icon: Icons.thumb_up_outlined,
              ),
            ],
            for (final entry in countPerStatus.entries) ...[
              const SizedBox(width: DesignTokens.spaceSm),
              _buildStatChip(
                context,
                label: entry.key,
                value: '${entry.value}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required String label,
    required String value,
    IconData? icon,
    Color? highlightColor,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceMd,
        vertical: DesignTokens.spaceXs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: highlightColor ?? theme.colorScheme.primary),
            const SizedBox(width: DesignTokens.spaceXs),
          ],
          Text('$label: ', style: theme.textTheme.labelSmall),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: highlightColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
