import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  late final OcrService _ocrService;
  bool _isProcessing = false;
  String _status = '';
  int _step = 1;
  String _selectedModule = 'schedule';
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _ocrService = OcrService();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _pickAndProcess(ImageSource source) async {
    HapticFeedback.selectionClick();
    final pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 2400,
      maxHeight: 2400,
      imageQuality: 95,
    );
    if (pickedFile == null) return;

    setState(() {
      _isProcessing = true;
      _step = 1;
      _status = 'Preparing image...';
    });

    try {
      final rawBytes = await pickedFile.readAsBytes();
      final preprocessedBytes = await ImagePreprocessor.preprocessBytes(rawBytes);

      if (!mounted) return;
      setState(() {
        _step = 2;
        _status = 'Reading document text...';
      });

      final ocrResult = await _ocrService.recognizeBytes(
        preprocessedBytes,
        filePath: pickedFile.path,
        fileName: pickedFile.name,
        module: _selectedModule,
      );

      // Check if text was actually detected
      if (ocrResult.fullText.trim().isEmpty) {
        if (mounted) {
          setState(() => _isProcessing = false);
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('No Text Detected'),
                ],
              ),
              content: const Text(
                'Could not detect readable text in this image. Please ensure proper lighting and that the document text is sharp and in focus.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Retake Photo'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/scan/review', extra: {
                      'module': _selectedModule,
                      'image_bytes': preprocessedBytes,
                      'image_name': pickedFile.name,
                      'full_text': '',
                      'fields': {'title': _selectedModule == 'schedule' ? 'New Event' : 'New Solicitation'},
                      'confidence': 0.0,
                      'confidences': <String, double>{},
                    });
                  },
                  child: const Text('Fill Manually'),
                ),
              ],
            ),
          );
        }
        return;
      }

      if (!mounted) return;
      setState(() {
        _step = 3;
        _status = 'Auto-extracting details...';
      });

      // Client-side heuristic parser
      final clientParsed = _selectedModule == 'schedule'
          ? FieldParser.parseSchedule(ocrResult.fullText)
          : FieldParser.parseSolicitation(ocrResult.fullText);

      final mergedFields = Map<String, dynamic>.from(clientParsed.fields);
      for (final entry in ocrResult.suggestedFields.entries) {
        if (entry.value != null && (!mergedFields.containsKey(entry.key) || mergedFields[entry.key] == null)) {
          mergedFields[entry.key] = entry.value;
        }
      }

      final confidenceScore = ocrResult.confidence > 0 ? ocrResult.confidence : 0.92;
      HapticFeedback.mediumImpact();

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
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _status = '';
          _step = 1;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Scan & Extract'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Banner Card
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [theme.colorScheme.primary.withOpacity(0.25), theme.colorScheme.surfaceContainerHigh]
                        : [theme.colorScheme.primary.withOpacity(0.12), theme.colorScheme.primaryContainer.withOpacity(0.35)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Instant Document Extraction',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Scan posters, invitations, letters, or receipts. Titles, dates, amounts, and venues are extracted on-device.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Module Selector
              Text(
                'DESTINATION MODULE',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                style: SegmentedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                segments: const [
                  ButtonSegment(
                    value: 'schedule',
                    icon: Icon(Icons.event_outlined),
                    label: Text('Schedule Event'),
                  ),
                  ButtonSegment(
                    value: 'solicitation',
                    icon: Icon(Icons.volunteer_activism_outlined),
                    label: Text('Solicitation Letter'),
                  ),
                ],
                selected: {_selectedModule},
                onSelectionChanged: (set) => setState(() => _selectedModule = set.first),
              ),

              const Spacer(),

              // Processing State or Action Buttons
              if (_isProcessing) ...[
                Center(
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 0.6, end: 1.0).animate(_pulseController),
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            strokeWidth: 3.5,
                            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Step $_step of 3 • Running offline AI OCR pipeline',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
              ] else ...[
                // Camera Action
                FilledButton.icon(
                  icon: const Icon(Icons.camera_alt, size: 22),
                  label: const Text('Capture with Camera', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  onPressed: () => _pickAndProcess(ImageSource.camera),
                ),
                const SizedBox(height: 14),

                // Gallery Action
                OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library_outlined, size: 22),
                  label: const Text('Pick Image from Gallery', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => _pickAndProcess(ImageSource.gallery),
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
