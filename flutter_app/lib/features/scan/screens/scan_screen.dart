import 'dart:io';
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
  final OcrService _ocrService = OcrService();
  bool _isProcessing = false;
  String _status = '';
  String _selectedModule = 'schedule';

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
      _status = 'Preprocessing image...';
    });

    try {
      final file = File(pickedFile.path);
      final preprocessed = await ImagePreprocessor.preprocess(file);

      setState(() {
        _status = 'Recognizing text via OCR...';
      });

      final ocrResult = await _ocrService.recognizeText(preprocessed);

      setState(() {
        _status = 'Parsing fields...';
      });

      final parsed = _selectedModule == 'schedule'
          ? FieldParser.parseSchedule(ocrResult.fullText)
          : FieldParser.parseSolicitation(ocrResult.fullText);

      if (mounted) {
        context.push('/scan/review', extra: {
          'module': _selectedModule,
          'image_path': preprocessed.path,
          'full_text': ocrResult.fullText,
          'fields': parsed.fields,
          'confidence': parsed.confidenceScores,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during scan: $e')),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Document')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select document type:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'schedule', label: Text('Schedule / Event')),
                ButtonSegment(value: 'solicitation', label: Text('Solicitation Letter')),
              ],
              selected: {_selectedModule},
              onSelectionChanged: (set) => setState(() => _selectedModule = set.first),
            ),
            const Spacer(),
            if (_isProcessing) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
              Text(_status, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w500)),
              const Spacer(),
            ] else ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Capture with Camera'),
                onPressed: () => _pickAndProcess(ImageSource.camera),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.photo_library),
                label: const Text('Pick from Gallery'),
                onPressed: () => _pickAndProcess(ImageSource.gallery),
              ),
              const Spacer(),
            ],
          ],
        ),
      ),
    );
  }
}
