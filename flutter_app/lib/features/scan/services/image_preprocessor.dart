import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImagePreprocessor {
  ImagePreprocessor._();

  static Future<Uint8List> preprocessBytes(Uint8List inputBytes) async {
    try {
      img.Image? image = img.decodeImage(inputBytes);
      if (image == null) return inputBytes;

      // 1. Contrast & brightness adjustment
      image = img.adjustColor(image, contrast: 1.25, brightness: 1.05);

      // 2. Grayscale conversion for cleaner OCR binarization
      image = img.grayscale(image);

      // 3. Gaussian blur (mild) to remove speckle noise
      image = img.gaussianBlur(image, radius: 1);

      return Uint8List.fromList(img.encodeJpg(image, quality: 90));
    } catch (_) {
      return inputBytes;
    }
  }
}
