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
import '../../shared/widgets/summary_strip.dart';
import '../../shared/widgets/dynamic_form.dart';
import '../../shared/widgets/undo_snackbar.dart';
import '../../shared/widgets/confirmation_dialog.dart';
import '../models/solicitation_item.dart';
import '../providers/solicitation_provider.dart';

class SolicitationTab extends ConsumerStatefulWidget {
  const SolicitationTab({super.key});

  @override
  ConsumerState<SolicitationTab> createState() => _SolicitationTabState();
}

class _SolicitationTabState extends ConsumerState<SolicitationTab> {
  ViewMode _viewMode = ViewMode.list;

  @override
  Widget build(BuildContext context) {
    final solicitationsAsync = ref.watch(solicitationListProvider);
    final filter = ref.watch(filterProvider);
    final filterNotifier = ref.read(filterProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan Solicitation Letter',
            onPressed: () => context.push('/scan'),
          ),
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Export',
            onPressed: () => context.push('/export'),
          ),
        ],
      ),
      body: solicitationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (items) {
          double totalRequested = 0;
          double totalGiven = 0;
          int approvedCount = 0;
          final statusCounts = <String, int>{};

          for (final it in items) {
            if (it.amountRequested != null) totalRequested += it.amountRequested!;
            if (it.givenAmount != null) totalGiven += it.givenAmount!;
            if (it.status == 'Approved' || it.status == 'Given') approvedCount++;
            statusCounts[it.status] = (statusCounts[it.status] ?? 0) + 1;
          }

          final approvalRate = items.isNotEmpty ? (approvedCount / items.length) : 0.0;

          return Column(
            children: [
              // Scope and View Controls
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

              // Summary Strip
              SummaryStrip(
                totalCount: items.length,
                totalRequestedAmount: totalRequested > 0 ? totalRequested : null,
                totalGivenAmount: totalGiven > 0 ? totalGiven : null,
                approvalRate: approvalRate,
                countPerStatus: statusCounts,
              ),

              // Time Mode Stepper & Live Search
              const TimeFilterBar(searchHint: 'Search solicitations, organizations, contacts...'),

              // Filter Bar
              FilterBar(resultCount: items.length),

              // Main List / Calendar View
              Expanded(
                child: switch (_viewMode) {
                  ViewMode.list => GroupedListView<SolicitationItem>(
                      items: items,
                      groupBy: filter.groupBy,
                      getItemDate: (it) => it.deadline ?? it.createdAt,
                      onRefresh: () async {},
                      onItemTap: (it) => context.push('/solicitation/detail/${it.id}'),
                      onItemEdit: (it) => _openEditDialog(it),
                      onItemDelete: (it) => _confirmDelete(it),
                    ),
                  ViewMode.calendar => CalendarViewWidget<SolicitationItem>(
                      items: items,
                      getItemDate: (it) => it.deadline ?? it.createdAt,
                      onItemTap: (it) => context.push('/solicitation/detail/${it.id}'),
                      onItemEdit: (it) => _openEditDialog(it),
                      onItemDelete: (it) => _confirmDelete(it),
                    ),
                  ViewMode.agenda => GroupedListView<SolicitationItem>(
                      items: items,
                      groupBy: GroupBy.status,
                      getItemDate: (it) => it.deadline ?? it.createdAt,
                      onRefresh: () async {},
                      onItemTap: (it) => context.push('/solicitation/detail/${it.id}'),
                      onItemEdit: (it) => _openEditDialog(it),
                      onItemDelete: (it) => _confirmDelete(it),
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
        label: const Text('New Solicitation'),
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
              title: const Text('Create Solicitation'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
            body: DynamicForm(
              fields: FieldDefinitions.solicitationFields,
              submitButtonText: 'Save Solicitation',
              onSave: (values) {
                final now = DateTime.now().toUtc();
                final newItem = SolicitationItem(
                  id: const Uuid().v4(),
                  title: values['title'] as String,
                  organization: values['organization'] as String?,
                  contactPerson: values['contact_person'] as String?,
                  phone: values['phone'] as String?,
                  email: values['email'] as String?,
                  purpose: values['purpose'] as String?,
                  amountRequested: (values['amount_requested'] as num?)?.toDouble(),
                  quantityRequested: values['quantity_requested'] as String?,
                  deadline: values['deadline'] as DateTime?,
                  status: values['status'] as String? ?? 'Draft',
                  priority: values['priority'] as String? ?? 'medium',
                  category: values['category'] as String?,
                  notes: values['notes'] as String?,
                  createdAt: now,
                  updatedAt: now,
                );

                ref.read(solicitationListProvider.notifier).addItem(newItem);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Created solicitation "${newItem.title}"'),
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

  void _openEditDialog(SolicitationItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Edit Solicitation'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
            body: DynamicForm(
              fields: FieldDefinitions.solicitationFields,
              initialValues: item.toJson(),
              submitButtonText: 'Update Solicitation',
              onSave: (values) {
                final updated = SolicitationItem(
                  id: item.id,
                  title: values['title'] as String,
                  organization: values['organization'] as String?,
                  contactPerson: values['contact_person'] as String?,
                  phone: values['phone'] as String?,
                  email: values['email'] as String?,
                  purpose: values['purpose'] as String?,
                  amountRequested: (values['amount_requested'] as num?)?.toDouble() ?? item.amountRequested,
                  quantityRequested: values['quantity_requested'] as String?,
                  deadline: values['deadline'] as DateTime? ?? item.deadline,
                  givenDate: values['given_date'] as DateTime? ?? item.givenDate,
                  givenAmount: (values['given_amount'] as num?)?.toDouble() ?? item.givenAmount,
                  givenItem: values['given_item'] as String? ?? item.givenItem,
                  givenBy: values['given_by'] as String? ?? item.givenBy,
                  givenTo: values['given_to'] as String? ?? item.givenTo,
                  status: values['status'] as String? ?? item.status,
                  priority: values['priority'] as String? ?? item.priority,
                  category: values['category'] as String? ?? item.category,
                  notes: values['notes'] as String?,
                  createdAt: item.createdAt,
                  updatedAt: DateTime.now().toUtc(),
                );

                ref.read(solicitationListProvider.notifier).updateItem(updated);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Updated "${updated.title}"'),
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

  Future<void> _confirmDelete(SolicitationItem item) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Solicitation',
      message: 'Are you sure you want to delete "${item.title}"?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed && mounted) {
      ref.read(solicitationListProvider.notifier).deleteItem(item.id);
      UndoSnackBar.show(
        context: context,
        message: 'Deleted "${item.title}"',
        onUndo: () {
          ref.read(solicitationListProvider.notifier).addItem(item);
        },
      );
    }
  }
}
