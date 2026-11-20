import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/color_schemes.dart';
import '../../../core/theme/design_tokens.dart';
import '../models/schedule_item.dart';
import '../providers/schedule_provider.dart';

class ScheduleDetailScreen extends ConsumerStatefulWidget {
  final String id;

  const ScheduleDetailScreen({super.key, required this.id});

  @override
  ConsumerState<ScheduleDetailScreen> createState() => _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends ConsumerState<ScheduleDetailScreen> with SingleTickerProviderStateMixin {
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
    final item = ref.watch(scheduleListProvider.notifier).getById(widget.id);

    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail')),
        body: const Center(child: Text('Item not found')),
      );
    }

    final theme = Theme.of(context);
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
              ref.read(scheduleListProvider.notifier).deleteItem(item.id);
              Navigator.of(context).pop();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Details'),
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
              // Status & Priority Banner
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

              _buildFieldTile('Event Date', DateFormat('EEEE, MMMM d, yyyy').format(item.eventDate)),
              if (item.startTime != null)
                _buildFieldTile('Time', '${item.startTime} ${item.endTime != null ? "- ${item.endTime}" : ""}'),
              if (item.location != null) _buildFieldTile('Location', item.location!),
              if (item.description != null) _buildFieldTile('Description', item.description!),
              if (item.notes != null) _buildFieldTile('Notes', item.notes!),
              _buildFieldTile('Created', DateFormat('MMM d, yyyy h:mm a').format(item.createdAt.toLocal())),
            ],
          ),

          // Timeline Tab
          ListView(
            padding: const EdgeInsets.all(DesignTokens.spaceLg),
            children: [
              _buildTimelineStep(
                title: 'Created event',
                subtitle: 'Created via mobile app',
                timestamp: item.createdAt,
                icon: Icons.add_circle_outline,
                isDone: true,
              ),
              if (item.isDone)
                _buildTimelineStep(
                  title: 'Completed',
                  subtitle: 'Marked as Done',
                  timestamp: item.completedAt ?? item.updatedAt,
                  icon: Icons.check_circle,
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
