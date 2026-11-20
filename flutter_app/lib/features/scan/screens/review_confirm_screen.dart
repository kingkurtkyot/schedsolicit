import 'dart:typed_data';
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
    final theme = Theme.of(context);
    final data = widget.data ?? {};
    final module = data['module'] as String? ?? 'schedule';
    final imageBytes = data['image_bytes'] as Uint8List?;
    final fullText = data['full_text'] as String? ?? '';
    final initialFields = (data['fields'] as Map<String, dynamic>?) ?? {};
    final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.88;

    final isSchedule = module == 'schedule';
    final fieldsDef = isSchedule ? FieldDefinitions.scheduleFields : FieldDefinitions.solicitationFields;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSchedule ? 'Confirm Scanned Event' : 'Confirm Scanned Solicitation'),
        actions: [
          if (fullText.trim().isNotEmpty)
            IconButton(
              icon: const Icon(Icons.description_outlined),
              tooltip: 'View Raw OCR Text',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (ctx) => DraggableScrollableSheet(
                    initialChildSize: 0.6,
                    maxChildSize: 0.9,
                    minChildSize: 0.4,
                    expand: false,
                    builder: (_, scrollController) => Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: ListView(
                        controller: scrollController,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recognized Document Text',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ],
                          ),
                          const Divider(),
                          SelectableText(
                            fullText,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: ListView(
        children: [
          // Original image preview (Cross-platform Uint8List bytes)
          if (imageBytes != null && imageBytes.isNotEmpty)
            Container(
              height: 220,
              width: double.infinity,
              color: Colors.black.withOpacity(0.04),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.memory(
                      imageBytes,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.grey),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 14, color: Colors.green.shade400),
                          const SizedBox(width: 6),
                          Text(
                            '${(confidence * 100).toInt()}% Match',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Confidence notification card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Card(
              elevation: 0,
              color: theme.colorScheme.secondaryContainer.withOpacity(0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Extracted details are pre-filled below. Review and adjust any field if needed before saving.',
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Form to edit and confirm (Embedded directly without nested scroll lag)
          DynamicForm(
            fields: fieldsDef,
            initialValues: initialFields,
            submitButtonText: isSchedule ? 'Save Event to Schedule' : 'Save Solicitation',
            isScrollable: false,
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
                  priority: confirmedValues['priority'] as String? ?? 'medium',
                  category: confirmedValues['category'] as String?,
                  status: 'Active',
                  createdAt: now,
                  updatedAt: now,
                );
                ref.read(scheduleListProvider.notifier).addItem(item);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Saved "${item.title}" to schedule'),
                    backgroundColor: Colors.green.shade800,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
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
                  priority: confirmedValues['priority'] as String? ?? 'medium',
                  category: confirmedValues['category'] as String?,
                  status: 'Draft',
                  createdAt: now,
                  updatedAt: now,
                );
                ref.read(solicitationListProvider.notifier).addItem(item);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Saved "${item.title}" to solicitations'),
                    backgroundColor: Colors.green.shade800,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                context.go('/solicitation');
              }
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
