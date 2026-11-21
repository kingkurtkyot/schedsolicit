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
  bool _showImage = false;
  bool _showForm = false; // Collapsed by default so user doesn't have to touch anything!

  void _saveDirectly(Map<String, dynamic> fields, bool isSchedule) {
    HapticFeedback.heavyImpact();
    final now = DateTime.now().toUtc();
    final id = const Uuid().v4();

    if (isSchedule) {
      final dateVal = fields['event_date'];
      final DateTime parsedDate = dateVal is DateTime
          ? dateVal
          : (dateVal is String ? DateTime.tryParse(dateVal) ?? DateTime.now() : DateTime.now());

      final item = ScheduleItem(
        id: id,
        title: fields['title'] as String? ?? 'Scanned Event',
        description: fields['description'] as String?,
        eventDate: parsedDate,
        startTime: fields['start_time'] as String?,
        endTime: fields['end_time'] as String?,
        location: fields['location'] as String?,
        priority: fields['priority'] as String? ?? 'medium',
        category: fields['category'] as String? ?? 'General',
        status: 'Active',
        notes: fields['notes'] as String?,
        createdAt: now,
        updatedAt: now,
      );

      ref.read(scheduleListProvider.notifier).addItem(item);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('Auto-saved "${item.title}" to Schedule')),
            ],
          ),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/schedule');
    } else {
      final amtVal = fields['amount_requested'];
      final double? parsedAmt = amtVal is num
          ? amtVal.toDouble()
          : (amtVal is String ? double.tryParse(amtVal.replaceAll(',', '')) : null);

      final dateVal = fields['deadline'];
      final DateTime? parsedDeadline = dateVal is DateTime
          ? dateVal
          : (dateVal is String ? DateTime.tryParse(dateVal) : null);

      final item = SolicitationItem(
        id: id,
        title: fields['title'] as String? ?? 'Scanned Solicitation',
        organization: fields['organization'] as String?,
        contactPerson: fields['contact_person'] as String?,
        amountRequested: parsedAmt,
        deadline: parsedDeadline,
        email: fields['email'] as String?,
        phone: fields['phone'] as String?,
        purpose: fields['purpose'] as String?,
        priority: fields['priority'] as String? ?? 'medium',
        category: fields['category'] as String? ?? 'General',
        status: 'Draft',
        notes: fields['notes'] as String?,
        createdAt: now,
        updatedAt: now,
      );

      ref.read(solicitationListProvider.notifier).addItem(item);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('Auto-saved "${item.title}" to Solicitations')),
            ],
          ),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/solicitation');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = widget.data ?? {};
    final module = data['module'] as String? ?? 'schedule';
    final imageBytes = data['image_bytes'] as Uint8List?;
    final fullText = data['full_text'] as String? ?? '';
    final initialFields = (data['fields'] as Map<String, dynamic>?) ?? {};
    final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.95;

    final isSchedule = module == 'schedule';
    final fieldsDef = isSchedule ? FieldDefinitions.scheduleFields : FieldDefinitions.solicitationFields;

    final title = initialFields['title']?.toString() ?? (isSchedule ? 'Scanned Event' : 'Scanned Solicitation');
    final dateVal = isSchedule ? initialFields['event_date'] : initialFields['deadline'];
    final dateStr = dateVal is DateTime
        ? DateFormat('EEEE, MMM d, yyyy').format(dateVal)
        : (dateVal != null ? dateVal.toString() : 'Not specified');
    final timeStr = initialFields['start_time']?.toString();
    final location = (initialFields['location'] ?? initialFields['organization'])?.toString();
    final category = initialFields['category']?.toString();
    final amount = initialFields['amount_requested'];

    return Scaffold(
      appBar: AppBar(
        title: Text(isSchedule ? 'Review Scanned Event' : 'Review Solicitation'),
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // 1. PRIMARY AUTOMATED EXTRACTION CARD (Everything Ready!)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer.withOpacity(0.5),
                  theme.colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '100% Extracted & Ready',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.12),
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

                const SizedBox(height: 16),

                // Extracted Title
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 10),

                // Key Info Rows
                _buildInfoRow(
                  Icons.calendar_month,
                  'Date',
                  timeStr != null ? '$dateStr at $timeStr' : dateStr,
                  theme,
                ),

                if (location != null && location.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildInfoRow(
                    isSchedule ? Icons.place_outlined : Icons.business_outlined,
                    isSchedule ? 'Venue' : 'Organization',
                    location,
                    theme,
                  ),
                ],

                if (amount != null) ...[
                  const SizedBox(height: 10),
                  _buildInfoRow(
                    Icons.payments_outlined,
                    'Amount',
                    '₱$amount',
                    theme,
                  ),
                ],

                if (category != null && category.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildInfoRow(
                    Icons.label_outline,
                    'Category',
                    category,
                    theme,
                  ),
                ],

                const SizedBox(height: 20),

                // 🌟 ONE-TAP SAVE BUTTON (User never needs to touch anything!)
                FilledButton.icon(
                  icon: const Icon(Icons.check_circle_outline, size: 22),
                  label: Text(
                    isSchedule ? 'Confirm & Save Event (1-Tap)' : 'Confirm & Save Solicitation (1-Tap)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 3,
                  ),
                  onPressed: () => _saveDirectly(initialFields, isSchedule),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. Collapsible Document Preview
          if (imageBytes != null && imageBytes.isNotEmpty)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
              ),
              child: ExpansionTile(
                initiallyExpanded: _showImage,
                leading: const Icon(Icons.image_outlined),
                title: const Text('View Captured Document', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                children: [
                  Container(
                    height: 220,
                    width: double.infinity,
                    color: Colors.black.withOpacity(0.04),
                    padding: const EdgeInsets.all(8),
                    child: Image.memory(
                      imageBytes,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // 3. Optional Manual Adjustment Accordion (Collapsed by default!)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
            ),
            child: ExpansionTile(
              initiallyExpanded: _showForm,
              leading: const Icon(Icons.edit_note_outlined),
              title: const Text('Adjust Extracted Fields', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Optional: Only if you want to tweak details', style: TextStyle(fontSize: 12, color: Colors.grey)),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: DynamicForm(
                    fields: fieldsDef,
                    initialValues: initialFields,
                    submitButtonText: isSchedule ? 'Save Customized Event' : 'Save Customized Solicitation',
                    isScrollable: false,
                    onSave: (confirmedValues) => _saveDirectly(confirmedValues, isSchedule),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
