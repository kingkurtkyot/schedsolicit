import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../shared/widgets/item_card.dart';
import '../models/solicitation_item.dart';

class SolicitationCard extends StatelessWidget {
  final SolicitationItem item;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SolicitationCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.compactSimpleCurrency();
    final amountStr = item.givenAmount != null
        ? 'Given: ${currency.format(item.givenAmount)}'
        : (item.amountRequested != null ? 'Req: ${currency.format(item.amountRequested)}' : null);

    return ItemCard(
      item: item,
      dateLine: item.deadline != null ? 'Due: ${DateFormat("MMM d").format(item.deadline!)}' : 'No deadline',
      subtitle: item.organization,
      extraAmount: amountStr,
      isOverdue: item.isOverdue,
      onTap: onTap,
      onEdit: onEdit,
      onDelete: onDelete,
    );
  }
}
