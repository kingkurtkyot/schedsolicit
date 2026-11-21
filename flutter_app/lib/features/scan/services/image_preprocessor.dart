import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImagePreprocessor {
  ImagePreprocessor._();

  /// Standard preprocessing: Normalizes EXIF orientation and limits max dimension to 2048px
  /// to maintain maximum detail without overloading ML Kit or memory.
  static Future<Uint8List> preprocessBytes(Uint8List inputBytes) async {
    try {
      img.Image? image = img.decodeImage(inputBytes);
      if (image == null) return inputBytes;

      // Bake orientation so portrait/landscape photos are upright
      image = img.bakeOrientation(image);

      if (image.width > 2048 || image.height > 2048) {
        final scale = 2048.0 / max(image.width, image.height);
        image = img.copyResize(
          image,
          width: (image.width * scale).round(),
          height: (image.height * scale).round(),
          interpolation: img.Interpolation.linear,
        );
      }

      return Uint8List.fromList(img.encodeJpg(image, quality: 95));
    } catch (_) {
      return inputBytes;
    }
  }

  /// High-contrast normalization pass:
  /// Uses percentile-based min-max contrast stretching so faint cursive scripts,
  /// silver/gold lettering, and light-gray fonts become solid dark text on pure white paper.
  static Future<Uint8List> enhanceContrast(Uint8List inputBytes) async {
    try {
      img.Image? image = img.decodeImage(inputBytes);
      if (image == null) return inputBytes;

      image = img.bakeOrientation(image);

      if (image.width > 2048 || image.height > 2048) {
        final scale = 2048.0 / max(image.width, image.height);
        image = img.copyResize(
          image,
          width: (image.width * scale).round(),
          height: (image.height * scale).round(),
          interpolation: img.Interpolation.linear,
        );
      }

      // 1. Convert to grayscale
      image = img.grayscale(image);

      // 2. Compute histogram (256 bins)
      final histogram = List<int>.filled(256, 0);
      int totalPixels = 0;
      for (final pixel in image) {
        final lum = pixel.r.toInt().clamp(0, 255);
        histogram[lum]++;
        totalPixels++;
      }

      if (totalPixels == 0) return inputBytes;

      // 3. Find 1st percentile (dark text threshold) and 98th percentile (white paper threshold)
      final pLowTarget = (totalPixels * 0.01).round();
      final pHighTarget = (totalPixels * 0.98).round();

      int accum = 0;
      int pLow = 0;
      int pHigh = 255;

      for (int i = 0; i < 256; i++) {
        accum += histogram[i];
        if (pLow == 0 && accum >= pLowTarget) {
          pLow = i;
        }
        if (accum >= pHighTarget) {
          pHigh = i;
          break;
        }
      }

      final range = pHigh - pLow;
      if (range > 15) {
        // Linearly stretch [pLow, pHigh] to [0, 255]
        for (final pixel in image) {
          final val = pixel.r.toInt();
          int stretched;
          if (val <= pLow) {
            stretched = 0;
          } else if (val >= pHigh) {
            stretched = 255;
          } else {
            stretched = ((val - pLow) * 255 ~/ range).clamp(0, 255);
          }
          pixel.r = stretched;
          pixel.g = stretched;
          pixel.b = stretched;
        }
      }

      return Uint8List.fromList(img.encodeJpg(image, quality: 95));
    } catch (_) {
      return inputBytes;
    }
  }

  /// Inverted contrast pass for dark background documents (e.g. black/navy cards with white/gold script)
  static Future<Uint8List> enhanceInverted(Uint8List inputBytes) async {
    try {
      final enhanced = await enhanceContrast(inputBytes);
      img.Image? image = img.decodeImage(enhanced);
      if (image == null) return inputBytes;

      image = img.invert(image);
      return Uint8List.fromList(img.encodeJpg(image, quality: 95));
    } catch (_) {
      return inputBytes;
    }
  }
}
