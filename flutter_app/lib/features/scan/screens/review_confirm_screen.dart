import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/field_definitions.dart';
import '../../schedule/models/schedule_item.dart';
import '../../schedule/providers/schedule_provider.dart';
import '../../solicitation/models/solicitation_item.dart';
import '../../solicitation/providers/solicitation_provider.dart';
import '../../shared/widgets/dynamic_form.dart';

class ReviewConfirmScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? data;

  const ReviewConfirmScreen({super.key, this.data});

  @override
  ConsumerState<ReviewConfirmScreen> createState() => _ReviewConfirmScreenState();
}

class _ReviewConfirmScreenState extends ConsumerState<ReviewConfirmScreen> {
  @override
  Widget build(BuildContext context) {
    final data = widget.data ?? {};
    final module = data['module'] as String? ?? 'schedule';
    final imagePath = data['image_path'] as String?;
    final initialFields = (data['fields'] as Map<String, dynamic>?) ?? {};
    final confidences = (data['confidence'] as Map<String, double>?) ?? {};

    final isSchedule = module == 'schedule';
    final fieldsDef = isSchedule ? FieldDefinitions.scheduleFields : FieldDefinitions.solicitationFields;

    return Scaffold(
      appBar: AppBar(title: const Text('Review Scanned Data')),
      body: ListView(
        children: [
          // Original image preview
          if (imagePath != null && File(imagePath).existsSync())
            Container(
              height: 180,
              color: Colors.black12,
              child: Image.file(File(imagePath), fit: BoxFit.contain),
            ),

          // Confidence notice
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Review and verify extracted fields before saving. Low-confidence fields can be edited.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),

          // Form to edit and confirm
          DynamicForm(
            fields: fieldsDef,
            initialValues: initialFields,
            submitButtonText: 'Confirm & Save',
            onSave: (confirmedValues) {
              final now = DateTime.now().toUtc();
              final id = const Uuid().v4();

              if (isSchedule) {
                final item = ScheduleItem(
                  id: id,
                  title: confirmedValues['title'] as String? ?? 'Scanned Event',
                  description: confirmedValues['description'] as String?,
                  eventDate: confirmedValues['event_date'] as DateTime? ?? DateTime.now(),
                  startTime: confirmedValues['start_time'] as String?,
                  endTime: confirmedValues['end_time'] as String?,
                  location: confirmedValues['location'] as String?,
                  status: 'Active',
                  createdAt: now,
                  updatedAt: now,
                );
                ref.read(scheduleListProvider.notifier).addItem(item);
                context.go('/schedule');
              } else {
                final item = SolicitationItem(
                  id: id,
                  title: confirmedValues['title'] as String? ?? 'Scanned Solicitation',
                  organization: confirmedValues['organization'] as String?,
                  contactPerson: confirmedValues['contact_person'] as String?,
                  amountRequested: (confirmedValues['amount_requested'] as num?)?.toDouble(),
                  email: confirmedValues['email'] as String?,
                  phone: confirmedValues['phone'] as String?,
                  status: 'Draft',
                  createdAt: now,
                  updatedAt: now,
                );
                ref.read(solicitationListProvider.notifier).addItem(item);
                context.go('/solicitation');
              }
            },
          ),
        ],
      ),
    );
  }
}
