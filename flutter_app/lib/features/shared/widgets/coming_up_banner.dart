import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

class ComingUpItem {
  final String id;
  final String title;
  final DateTime eventTime;
  final String? location;

  const ComingUpItem({
    required this.id,
    required this.title,
    required this.eventTime,
    this.location,
  });
}

class ComingUpBanner extends StatelessWidget {
  final List<ComingUpItem> items;
  final ValueChanged<String> onItemTap;

  const ComingUpBanner({
    super.key,
    required this.items,
    required this.onItemTap,
  });

  Color _getEscalationColor(DateTime eventTime) {
    final diff = eventTime.difference(DateTime.now());
    if (diff.isNegative || diff.inMinutes <= 15) {
      return DesignTokens.escalationDanger;
    } else if (diff.inMinutes <= 60) {
      return DesignTokens.escalationWarning;
    } else {
      return DesignTokens.escalationSafe;
    }
  }

  String _formatTimeRemaining(DateTime eventTime) {
    final diff = eventTime.difference(DateTime.now());
    if (diff.isNegative) {
      return 'Overdue by ${diff.inMinutes.abs()}m';
    } else if (diff.inMinutes < 60) {
      return 'In ${diff.inMinutes}m';
    } else {
      final hours = (diff.inMinutes / 60).toStringAsFixed(1);
      return 'In ${hours}h';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 90,
      margin: const EdgeInsets.symmetric(vertical: DesignTokens.spaceSm),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final color = _getEscalationColor(item.eventTime);

          return Card(
            margin: const EdgeInsets.only(right: DesignTokens.spaceSm),
            child: InkWell(
              onTap: () => onItemTap(item.id),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              child: Container(
                width: 220,
                padding: const EdgeInsets.all(DesignTokens.spaceSm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: DesignTokens.spaceXs),
                        Text(
                          _formatTimeRemaining(item.eventTime),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Text(
                      item.location ?? 'No location',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
