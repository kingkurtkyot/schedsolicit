import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImagePreprocessor {
  ImagePreprocessor._();

  /// Preprocess image for OCR without destructive blurring or washing out light fonts.
  /// Preserves high-frequency edge contrast for cursive and stylized fonts.
  static Future<Uint8List> preprocessBytes(Uint8List inputBytes) async {
    try {
      img.Image? image = img.decodeImage(inputBytes);
      if (image == null) return inputBytes;

      // Ensure orientation is normalized from EXIF
      image = img.bakeOrientation(image);

      // If image is excessively large (> 2500px), downscale slightly to optimize OCR speed while retaining sharpness
      if (image.width > 2400 || image.height > 2400) {
        image = img.copyResize(
          image,
          width: image.width > image.height ? 2048 : (image.width * 2048 ~/ image.height),
          height: image.height >= image.width ? 2048 : (image.height * 2048 ~/ image.width),
          interpolation: img.Interpolation.linear,
        );
      }

      // Encode as clean high-quality JPEG (95% quality) without destructive blur or artificial brightness shifts
      return Uint8List.fromList(img.encodeJpg(image, quality: 95));
    } catch (_) {
      return inputBytes;
    }
  }
}
