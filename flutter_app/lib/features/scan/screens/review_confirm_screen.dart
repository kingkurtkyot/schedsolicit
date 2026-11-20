import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
  bool _showImage = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = widget.data ?? {};
    final module = data['module'] as String? ?? 'schedule';
    final imageBytes = data['image_bytes'] as Uint8List?;
    final fullText = data['full_text'] as String? ?? '';
    final initialFields = (data['fields'] as Map<String, dynamic>?) ?? {};
    final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.90;

    final isSchedule = module == 'schedule';
    final fieldsDef = isSchedule ? FieldDefinitions.scheduleFields : FieldDefinitions.solicitationFields;

    // Build quick summary chips from extracted fields
    final chips = <Widget>[];
    if (initialFields['event_date'] != null) {
      final d = initialFields['event_date'];
      final dateStr = d is DateTime ? DateFormat('MMM d, yyyy').format(d) : d.toString();
      chips.add(_buildChip(Icons.calendar_today, dateStr, theme));
    }
    if (initialFields['deadline'] != null) {
      final d = initialFields['deadline'];
      final dateStr = d is DateTime ? DateFormat('MMM d, yyyy').format(d) : d.toString();
      chips.add(_buildChip(Icons.event_busy, 'Deadline: $dateStr', theme));
    }
    if (initialFields['start_time'] != null) {
      chips.add(_buildChip(Icons.access_time, initialFields['start_time'].toString(), theme));
    }
    if (initialFields['amount_requested'] != null) {
      chips.add(_buildChip(Icons.payments_outlined, '\$${initialFields['amount_requested']}', theme));
    }
    if (initialFields['organization'] != null) {
      chips.add(_buildChip(Icons.business, initialFields['organization'].toString(), theme));
    }
    if (initialFields['location'] != null) {
      chips.add(_buildChip(Icons.place_outlined, initialFields['location'].toString(), theme));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isSchedule ? 'Review Scanned Event' : 'Review Scanned Solicitation'),
        actions: [
          if (fullText.trim().isNotEmpty)
            IconButton(
              icon: const Icon(Icons.text_snippet_outlined),
              tooltip: 'Inspect OCR Text',
              onPressed: () => _showRawTextSheet(context, fullText),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          // Extraction Result Summary Banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'AI Auto-Extraction Complete',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(confidence * 100).toInt()}% Match',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Extracted details are pre-filled below. You can adjust any field before saving.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: chips),
                ],
              ],
            ),
          ),

          // Collapsible Image Preview
          if (imageBytes != null && imageBytes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.image_outlined),
                      title: const Text('Captured Document Preview', style: TextStyle(fontWeight: FontWeight.w600)),
                      trailing: IconButton(
                        icon: Icon(_showImage ? Icons.expand_less : Icons.expand_more),
                        onPressed: () => setState(() => _showImage = !_showImage),
                      ),
                    ),
                    if (_showImage)
                      Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.black.withOpacity(0.04),
                        child: Image.memory(
                          imageBytes,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image_outlined, size: 40, color: Colors.grey),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Form to edit and confirm
          DynamicForm(
            fields: fieldsDef,
            initialValues: initialFields,
            submitButtonText: isSchedule ? 'Save Event to Schedule' : 'Save Solicitation',
            isScrollable: false,
            onSave: (confirmedValues) {
              HapticFeedback.mediumImpact();
              final now = DateTime.now().toUtc();
              final id = const Uuid().v4();

              if (isSchedule) {
                final dateVal = confirmedValues['event_date'];
                final DateTime parsedDate = dateVal is DateTime
                    ? dateVal
                    : (dateVal is String ? DateTime.tryParse(dateVal) ?? DateTime.now() : DateTime.now());

                final item = ScheduleItem(
                  id: id,
                  title: confirmedValues['title'] as String? ?? 'Scanned Event',
                  description: confirmedValues['description'] as String?,
                  eventDate: parsedDate,
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
                final amtVal = confirmedValues['amount_requested'];
                final double? parsedAmt = amtVal is num
                    ? amtVal.toDouble()
                    : (amtVal is String ? double.tryParse(amtVal.replaceAll(',', '')) : null);

                final item = SolicitationItem(
                  id: id,
                  title: confirmedValues['title'] as String? ?? 'Scanned Solicitation',
                  organization: confirmedValues['organization'] as String?,
                  contactPerson: confirmedValues['contact_person'] as String?,
                  amountRequested: parsedAmt,
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
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  void _showRawTextSheet(BuildContext context, String rawText) {
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
                  const Text(
                    'Recognized Document Text',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copy all text',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: rawText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied OCR text to clipboard'), behavior: SnackBarBehavior.floating),
                      );
                    },
                  ),
                ],
              ),
              const Divider(),
              SelectableText(
                rawText,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
