import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_preprocessor.dart';
import '../services/ocr_service.dart';
import '../services/field_parser.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  late final OcrService _ocrService;
  bool _isProcessing = false;
  String _status = '';
  String _selectedModule = 'schedule';

  @override
  void initState() {
    super.initState();
    _ocrService = OcrService();
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _pickAndProcess(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    setState(() {
      _isProcessing = true;
      _status = 'Optimizing image for text recognition...';
    });

    try {
      final rawBytes = await pickedFile.readAsBytes();
      final preprocessedBytes = await ImagePreprocessor.preprocessBytes(rawBytes);

      setState(() {
        _status = 'Running AI OCR & extracting details...';
      });

      final ocrResult = await _ocrService.recognizeBytes(
        preprocessedBytes,
        fileName: pickedFile.name,
      );

      setState(() {
        _status = 'Auto-mapping fields & categories...';
      });

      // 1. Client-side heuristic parser
      final clientParsed = _selectedModule == 'schedule'
          ? FieldParser.parseSchedule(ocrResult.fullText)
          : FieldParser.parseSolicitation(ocrResult.fullText);

      // 2. Merge backend AI suggested fields with client parser
      final mergedFields = Map<String, dynamic>.from(clientParsed.fields);
      for (final entry in ocrResult.suggestedFields.entries) {
        if (entry.value != null) {
          final val = entry.value;
          if (entry.key == 'event_date' || entry.key == 'requested_date') {
            if (val is String) {
              mergedFields[entry.key] = DateTime.tryParse(val) ?? DateTime.now();
            } else if (val is DateTime) {
              mergedFields[entry.key] = val;
            }
          } else {
            mergedFields[entry.key] = val;
          }
        }
      }

      // Default title if still empty
      if (mergedFields['title'] == null || (mergedFields['title'] as String).trim().isEmpty) {
        mergedFields['title'] = _selectedModule == 'schedule' ? 'Scanned Event' : 'Scanned Solicitation';
      }

      final confidenceScore = ocrResult.confidence > 0 ? ocrResult.confidence : 0.85;

      if (mounted) {
        context.push('/scan/review', extra: {
          'module': _selectedModule,
          'image_bytes': preprocessedBytes,
          'image_name': pickedFile.name,
          'full_text': ocrResult.fullText,
          'fields': mergedFields,
          'confidence': confidenceScore,
          'confidences': clientParsed.confidenceScores,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scanning notice: $e'),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _status = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan & Auto-Extract'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 0,
                color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Upload or capture any poster, flyer, letter, or receipt. SchedSolicit will automatically extract titles, dates, amounts, and contact details.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Select Destination Module:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'schedule',
                    icon: Icon(Icons.event),
                    label: Text('Schedule / Event'),
                  ),
                  ButtonSegment(
                    value: 'solicitation',
                    icon: Icon(Icons.volunteer_activism),
                    label: Text('Solicitation Letter'),
                  ),
                ],
                selected: {_selectedModule},
                onSelectionChanged: (set) => setState(() => _selectedModule = set.first),
              ),
              const Spacer(),
              if (_isProcessing) ...[
                const Center(
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Reading typography and formatting...',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                const Spacer(),
              ] else ...[
                FilledButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Capture with Camera', style: TextStyle(fontSize: 16)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => _pickAndProcess(ImageSource.camera),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Pick Image or Document', style: TextStyle(fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => _pickAndProcess(ImageSource.gallery),
                ),
                const Spacer(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
