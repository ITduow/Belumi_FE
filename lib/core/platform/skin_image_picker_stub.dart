import 'dart:convert';

import 'package:image_picker/image_picker.dart';

import 'picked_skin_image.dart';

Future<PickedSkinImage?> pickSkinImage({required bool preferCamera}) async {
  final picker = ImagePicker();
  final file = await picker.pickImage(
    source: preferCamera ? ImageSource.camera : ImageSource.gallery,
    imageQuality: 88,
    maxWidth: 1600,
  );
  if (file == null) return null;

  final bytes = await file.readAsBytes();
  final mimeType = _mimeTypeFor(file.name);
  return PickedSkinImage(
    name: file.name,
    mimeType: mimeType,
    dataUrl: 'data:$mimeType;base64,${base64Encode(bytes)}',
  );
}

String _mimeTypeFor(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  return 'image/jpeg';
}
