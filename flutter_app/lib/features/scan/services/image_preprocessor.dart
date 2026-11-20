import 'dart:io';
import 'package:image/image.dart' as img;

class ImagePreprocessor {
  ImagePreprocessor._();

  static Future<File> preprocess(File inputFile) async {
    final bytes = await inputFile.readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) return inputFile;

    // 1. Contrast adjustment
    image = img.adjustColor(image, contrast: 1.2, brightness: 1.05);

    // 2. Grayscale conversion for cleaner OCR binarization
    image = img.grayscale(image);

    // 3. Gaussian blur (mild) to remove speckle noise
    image = img.gaussianBlur(image, radius: 1);

    final outBytes = img.encodeJpg(image, quality: 90);
    final processedFile = File('${inputFile.path}_preprocessed.jpg');
    await processedFile.writeAsBytes(outBytes);

    return processedFile;
  }
}
