import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/field_definitions.dart';
import '../../shared/models/filter_state.dart';
import '../../shared/providers/filter_provider.dart';
import '../../shared/widgets/view_switcher.dart';
import '../../shared/widgets/time_filter_bar.dart';
import '../../shared/widgets/filter_bar.dart';
import '../../shared/widgets/calendar_view.dart';
import '../../shared/widgets/grouped_list_view.dart';
import '../../shared/widgets/agenda_view.dart';
import '../../shared/widgets/coming_up_banner.dart';
import '../../shared/widgets/dynamic_form.dart';
import '../../shared/widgets/undo_snackbar.dart';
import '../../shared/widgets/confirmation_dialog.dart';
import '../models/schedule_item.dart';
import '../providers/schedule_provider.dart';

class ScheduleTab extends ConsumerStatefulWidget {
  const ScheduleTab({super.key});

  @override
  ConsumerState<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends ConsumerState<ScheduleTab> {
  ViewMode _viewMode = ViewMode.list;

  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(scheduleListProvider);
    final filter = ref.watch(filterProvider);
    final filterNotifier = ref.read(filterProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan Document',
            onPressed: () => context.push('/scan'),
          ),
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Export',
            onPressed: () => context.push('/export'),
          ),
        ],
      ),
      body: schedulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (items) {
          // Coming up items for active banner
          final now = DateTime.now();
          final upcomingItems = items
              .where((i) => !i.isDone && i.eventDate.isAfter(now.subtract(const Duration(minutes: 30))))
              .take(5)
              .map((i) => ComingUpItem(
                    id: i.id,
                    title: i.title,
                    eventTime: i.eventDate,
                    location: i.location,
                  ))
              .toList();

          return Column(
            children: [
              // Active / History Scope Switcher
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<FilterScope>(
                        segments: const [
                          ButtonSegment(value: FilterScope.active, label: Text('Active')),
                          ButtonSegment(value: FilterScope.history, label: Text('History')),
                        ],
                        selected: {filter.scope == FilterScope.history ? FilterScope.history : FilterScope.active},
                        onSelectionChanged: (set) => filterNotifier.setScope(set.first),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ViewSwitcher(
                      currentMode: _viewMode,
                      onModeChanged: (mode) => setState(() => _viewMode = mode),
                    ),
                  ],
                ),
              ),

              // Coming Up Banner
              if (upcomingItems.isNotEmpty && filter.scope != FilterScope.history)
                ComingUpBanner(
                  items: upcomingItems,
                  onItemTap: (id) => context.push('/schedule/detail/$id'),
                ),

              // Time Mode Stepper & Live Search
              const TimeFilterBar(searchHint: 'Search schedule events, locations, categories...'),

              // Filter Bar
              FilterBar(resultCount: items.length),

              // Main View
              Expanded(
                child: switch (_viewMode) {
                  ViewMode.list => GroupedListView<ScheduleItem>(
                      items: items,
                      groupBy: filter.groupBy,
                      getItemDate: (it) => it.eventDate,
                      onRefresh: () async {},
                      onItemTap: (it) => context.push('/schedule/detail/${it.id}'),
                      onItemEdit: (it) => _openEditDialog(it),
                      onItemDelete: (it) => _confirmDelete(it),
                    ),
                  ViewMode.calendar => CalendarViewWidget<ScheduleItem>(
                      items: items,
                      getItemDate: (it) => it.eventDate,
                      onItemTap: (it) => context.push('/schedule/detail/${it.id}'),
                      onItemEdit: (it) => _openEditDialog(it),
                      onItemDelete: (it) => _confirmDelete(it),
                    ),
                  ViewMode.agenda => AgendaViewWidget<ScheduleItem>(
                      items: items,
                      getItemTime: (it) => it.startTime ?? 'All day',
                      isAllDay: (it) => it.allDay,
                      onItemTap: (it) => context.push('/schedule/detail/${it.id}'),
                    ),
                },
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Event'),
      ),
    );
  }

  void _openCreateDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Create Schedule Event'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
            body: DynamicForm(
              fields: FieldDefinitions.scheduleFields,
              submitButtonText: 'Create Event',
              onSave: (values) {
                final now = DateTime.now().toUtc();
                final newItem = ScheduleItem(
                  id: const Uuid().v4(),
                  title: values['title'] as String,
                  description: values['description'] as String?,
                  eventDate: values['event_date'] as DateTime? ?? DateTime.now(),
                  startTime: values['start_time'] as String?,
                  endTime: values['end_time'] as String?,
                  allDay: values['all_day'] == true,
                  location: values['location'] as String?,
                  category: values['category'] as String?,
                  priority: values['priority'] as String? ?? 'medium',
                  repeatRule: values['repeat_rule'] as String?,
                  status: values['status'] as String? ?? 'Active',
                  notes: values['notes'] as String?,
                  createdAt: now,
                  updatedAt: now,
                );

                ref.read(scheduleListProvider.notifier).addItem(newItem);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Created event "${newItem.title}"'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _openEditDialog(ScheduleItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Edit Schedule Event'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
            body: DynamicForm(
              fields: FieldDefinitions.scheduleFields,
              initialValues: item.toJson(),
              submitButtonText: 'Update Event',
              onSave: (values) {
                final updated = ScheduleItem(
                  id: item.id,
                  title: values['title'] as String,
                  description: values['description'] as String?,
                  eventDate: values['event_date'] is DateTime
                      ? values['event_date'] as DateTime
                      : DateTime.tryParse(values['event_date']?.toString() ?? '') ?? item.eventDate,
                  startTime: values['start_time'] as String?,
                  endTime: values['end_time'] as String?,
                  allDay: values['all_day'] == true,
                  location: values['location'] as String?,
                  category: values['category'] as String?,
                  priority: values['priority'] as String? ?? 'medium',
                  repeatRule: values['repeat_rule'] as String?,
                  status: values['status'] as String? ?? item.status,
                  notes: values['notes'] as String?,
                  createdAt: item.createdAt,
                  updatedAt: DateTime.now().toUtc(),
                );

                ref.read(scheduleListProvider.notifier).updateItem(updated);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Updated event "${updated.title}"'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(ScheduleItem item) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Event',
      message: 'Are you sure you want to delete "${item.title}"?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed && mounted) {
      ref.read(scheduleListProvider.notifier).deleteItem(item.id);
      UndoSnackBar.show(
        context: context,
        message: 'Deleted "${item.title}"',
        onUndo: () {
          ref.read(scheduleListProvider.notifier).addItem(item);
        },
      );
    }
  }
}
