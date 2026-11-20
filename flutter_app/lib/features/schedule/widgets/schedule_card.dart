import 'package:flutter/material.dart';
import '../../shared/widgets/item_card.dart';
import '../models/schedule_item.dart';

class ScheduleCard extends StatelessWidget {
  final ScheduleItem item;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool hasConflict;

  const ScheduleCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.hasConflict = false,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = item.allDay ? 'All Day' : (item.startTime ?? 'No time set');
    final subtitle = [
      timeStr,
      if (item.location != null) item.location,
    ].join(' · ');

    return Stack(
      children: [
        ItemCard(
          item: item,
          dateLine: item.eventDate.toString().split(' ')[0],
          subtitle: subtitle,
          isOverdue: item.isOverdue,
          onTap: onTap,
          onEdit: onEdit,
          onDelete: onDelete,
        ),
        if (hasConflict)
          Positioned(
            top: 12,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning, size: 12, color: Colors.red),
                  SizedBox(width: 2),
                  Text('Overlap', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
