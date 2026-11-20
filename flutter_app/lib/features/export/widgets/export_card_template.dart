import 'package:flutter/material.dart';
import '../../shared/models/base_item.dart';
import '../../../core/theme/design_tokens.dart';

class ExportCardTemplate extends StatelessWidget {
  final BaseItem item;

  const ExportCardTemplate({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceLightContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF131D13),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: DesignTokens.colorEmerald.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.status.toUpperCase(),
                  style: const TextStyle(
                    color: DesignTokens.colorEmerald,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Priority: ${item.priority} | Category: ${item.category ?? "General"}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF3F4A3F)),
          ),
        ],
      ),
    );
  }
}
