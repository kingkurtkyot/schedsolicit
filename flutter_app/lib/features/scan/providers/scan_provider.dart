import 'package:flutter_riverpod/flutter_riverpod.dart';

final scanProvider = StateNotifierProvider<ScanNotifier, ScanPipelineData>((ref) {
  return ScanNotifier();
});

class ScanPipelineData {
  final bool isScanning;
  final String? currentImagePath;
  final String? recognizedText;
  final Map<String, dynamic> extractedFields;
  final Map<String, double> confidences;

  const ScanPipelineData({
    this.isScanning = false,
    this.currentImagePath,
    this.recognizedText,
    this.extractedFields = const {},
    this.confidences = const {},
  });
}

class ScanNotifier extends StateNotifier<ScanPipelineData> {
  ScanNotifier() : super(const ScanPipelineData());

  void setScanning(bool scanning) {
    state = ScanPipelineData(
      isScanning: scanning,
      currentImagePath: state.currentImagePath,
      recognizedText: state.recognizedText,
      extractedFields: state.extractedFields,
      confidences: state.confidences,
    );
  }

  void setScanResult({
    required String imagePath,
    required String text,
    required Map<String, dynamic> fields,
    required Map<String, double> confidences,
  }) {
    state = ScanPipelineData(
      isScanning: false,
      currentImagePath: imagePath,
      recognizedText: text,
      extractedFields: fields,
      confidences: confidences,
    );
  }

  void reset() {
    state = const ScanPipelineData();
  }
}
