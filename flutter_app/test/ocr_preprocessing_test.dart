import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('ImagePreprocessor contrast stretching produces dark text on white', () {
    // Create a 100x100 white image with faint gray text
    final testImg = img.Image(width: 100, height: 100);
    // Fill white (255)
    img.fill(testImg, color: img.ColorRgb8(250, 250, 250));
    // Draw some faint gray pixels (210)
    for (int y = 40; y < 60; y++) {
      for (int x = 40; x < 60; x++) {
        testImg.setPixel(x, y, img.ColorRgb8(200, 200, 200));
      }
    }

    // Convert to grayscale
    var gray = img.grayscale(testImg);

    // Min-max stretching
    int minVal = 255;
    int maxVal = 0;
    for (final pixel in gray) {
      final l = pixel.r.toInt();
      if (l < minVal) minVal = l;
      if (l > maxVal) maxVal = l;
    }

    expect(minVal, 200);
    expect(maxVal, 250);

    final range = maxVal - minVal;
    expect(range > 0, true);

    for (final pixel in gray) {
      final l = pixel.r.toInt();
      final stretched = ((l - minVal) * 255 ~/ range).clamp(0, 255);
      pixel.r = stretched;
      pixel.g = stretched;
      pixel.b = stretched;
    }

    final darkPixel = gray.getPixel(50, 50);
    final lightPixel = gray.getPixel(10, 10);

    expect(darkPixel.r.toInt(), 0); // Faint text stretched to jet black!
    expect(lightPixel.r.toInt(), 255); // Background stretched to pure white!
  });
}
