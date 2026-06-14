import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

/// Service for extracting text from images using Google ML Kit OCR.
/// Includes auto-contrast filter to improve accuracy on curved labels
/// and low-light conditions.
class OcrService {
  OcrService._();
  static final OcrService instance = OcrService._();

  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Extract text from an image file at the given [imagePath].
  ///
  /// Applies auto-contrast enhancement before OCR to improve
  /// text detection on curved labels and in low-light conditions.
  /// Returns the full recognized text as a single string.
  Future<String> extractTextFromFile(String imagePath) async {
    // Step 1: Apply auto-contrast filter to enhance the image
    final enhancedPath = await _applyAutoContrast(imagePath);

    // Step 2: Run OCR on the enhanced image
    final inputImage = InputImage.fromFilePath(enhancedPath);
    final recognized = await _recognizer.processImage(inputImage);

    // Clean up temporary enhanced image
    if (enhancedPath != imagePath) {
      try {
        await File(enhancedPath).delete();
      } catch (_) {}
    }

    if (recognized.text.trim().isEmpty) {
      throw Exception(
        'Không nhận diện được chữ trong ảnh. '
        'Hãy chụp rõ hơn với ánh sáng đủ.',
      );
    }

    return recognized.text;
  }

  /// Apply auto-contrast enhancement to improve OCR accuracy.
  ///
  /// This filter:
  /// - Increases contrast to make text stand out from background
  /// - Adjusts brightness for low-light images
  /// - Sharpens edges for curved label text
  Future<String> _applyAutoContrast(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      var image = img.decodeImage(bytes);
      if (image == null) return imagePath;

      // Auto-contrast: stretch histogram to use full range
      image = img.adjustColor(
        image,
        contrast: 1.4, // Increase contrast by 40%
        brightness: 1.05, // Slight brightness boost for low-light
      );

      // Sharpen to help with curved/blurry labels
      image = img.convolution(
        image,
        filter: [0, -0.5, 0, -0.5, 3, -0.5, 0, -0.5, 0],
        div: 1,
      );

      // Save enhanced image to temp file
      final dir = File(imagePath).parent;
      final enhancedPath =
          '${dir.path}${Platform.pathSeparator}_ocr_enhanced.jpg';
      final encoded = img.encodeJpg(image, quality: 95);
      await File(enhancedPath).writeAsBytes(encoded);

      return enhancedPath;
    } catch (_) {
      // If enhancement fails, fall back to original image
      return imagePath;
    }
  }

  /// Cleanup resources when no longer needed.
  void dispose() {
    _recognizer.close();
  }
}
