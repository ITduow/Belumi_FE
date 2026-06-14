import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Service for extracting text from images using Google ML Kit OCR.
/// Used to read ingredient lists from cosmetic product labels.
class OcrService {
  OcrService._();
  static final OcrService instance = OcrService._();

  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Extract text from an image file at the given [imagePath].
  ///
  /// Returns the full recognized text as a single string.
  /// Throws if OCR fails or no text is found.
  Future<String> extractTextFromFile(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognized = await _recognizer.processImage(inputImage);

    if (recognized.text.trim().isEmpty) {
      throw Exception(
        'Không nhận diện được chữ trong ảnh. '
        'Hãy chụp rõ hơn với ánh sáng đủ.',
      );
    }

    return recognized.text;
  }

  /// Extract text from raw image bytes.
  Future<String> extractTextFromBytes(
    Uint8List bytes, {
    required int width,
    required int height,
    required int rotation,
  }) async {
    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: ui.Size(width.toDouble(), height.toDouble()),
        rotation: InputImageRotation.values[rotation],
        format: InputImageFormat.nv21,
        bytesPerRow: width,
      ),
    );
    final recognized = await _recognizer.processImage(inputImage);
    return recognized.text;
  }

  /// Cleanup resources when no longer needed.
  void dispose() {
    _recognizer.close();
  }
}
