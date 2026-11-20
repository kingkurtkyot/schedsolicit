import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/color_schemes.dart';
import '../../../core/theme/design_tokens.dart';
import '../models/solicitation_item.dart';
import '../providers/solicitation_provider.dart';

class SolicitationDetailScreen extends ConsumerStatefulWidget {
  final String id;

  const SolicitationDetailScreen({super.key, required this.id});

  @override
  ConsumerState<SolicitationDetailScreen> createState() => _SolicitationDetailScreenState();
}

class _SolicitationDetailScreenState extends ConsumerState<SolicitationDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = ref.watch(solicitationListProvider.notifier).getById(widget.id);

    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail')),
        body: const Center(child: Text('Item not found')),
      );
    }

    final currency = NumberFormat.simpleCurrency();
    final statusColor = AppColorSchemes.getStatusColor(item.status);

    return Scaffold(
      appBar: AppBar(
        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              ref.read(solicitationListProvider.notifier).deleteItem(item.id);
              Navigator.of(context).pop();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Details & Fulfillment'),
            Tab(text: 'Timeline & History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Details Tab
          ListView(
            padding: const EdgeInsets.all(DesignTokens.spaceLg),
            children: [
              // Status & Priority
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spaceMd,
                      vertical: DesignTokens.spaceXs,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      item.status,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spaceSm),
                  Chip(
                    avatar: Icon(AppColorSchemes.getPriorityIcon(item.priority), size: 16),
                    label: Text(item.priority.toUpperCase()),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.spaceLg),

              if (item.organization != null) _buildFieldTile('Organization', item.organization!),
              if (item.contactPerson != null) _buildFieldTile('Contact Person', item.contactPerson!),
              if (item.phone != null) _buildFieldTile('Phone', item.phone!),
              if (item.email != null) _buildFieldTile('Email', item.email!),
              if (item.purpose != null) _buildFieldTile('Purpose', item.purpose!),

              if (item.amountRequested != null)
                _buildFieldTile('Amount Requested', currency.format(item.amountRequested)),

              if (item.deadline != null)
                _buildFieldTile('Deadline', DateFormat('MMMM d, yyyy').format(item.deadline!)),

              const Divider(),
              const Text('FULFILLMENT / GIVEN DETAILS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              const SizedBox(height: DesignTokens.spaceSm),

              if (item.givenAmount != null)
                _buildFieldTile('Amount Given', currency.format(item.givenAmount)),
              if (item.givenDate != null)
                _buildFieldTile('Date Given', DateFormat('MMMM d, yyyy').format(item.givenDate!)),
              if (item.givenBy != null) _buildFieldTile('Given By', item.givenBy!),
              if (item.givenTo != null) _buildFieldTile('Given To', item.givenTo!),
            ],
          ),

          // Timeline Tab
          ListView(
            padding: const EdgeInsets.all(DesignTokens.spaceLg),
            children: [
              _buildTimelineStep(
                title: 'Created solicitation',
                subtitle: 'Draft initiated',
                timestamp: item.createdAt,
                icon: Icons.edit_note,
                isDone: true,
              ),
              if (item.givenDate != null)
                _buildTimelineStep(
                  title: 'Donation fulfilled',
                  subtitle: 'Given ${item.givenAmount != null ? currency.format(item.givenAmount) : ""}',
                  timestamp: item.givenDate!,
                  icon: Icons.card_giftcard,
                  isDone: true,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFieldTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
          const SizedBox(height: DesignTokens.spaceXxs),
          Text(value, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required DateTime timestamp,
    required IconData icon,
    required bool isDone,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDone ? Colors.green : Colors.grey),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: Text(
        DateFormat('MMM d, h:mm a').format(timestamp.toLocal()),
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }
}
