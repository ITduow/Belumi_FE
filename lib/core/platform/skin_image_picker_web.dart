// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

import 'picked_skin_image.dart';

Future<PickedSkinImage?> pickSkinImage({required bool preferCamera}) async {
  if (preferCamera) {
    final captured = await _captureFromCamera();
    if (captured != null) return captured;
  }

  return _pickFromFile(preferCamera: preferCamera);
}

Future<PickedSkinImage?> _pickFromFile({required bool preferCamera}) async {
  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..multiple = false;
  if (preferCamera) {
    input.setAttribute('capture', 'user');
  }

  input.click();
  await input.onChange.first.timeout(const Duration(minutes: 5));

  final file = input.files?.isNotEmpty == true ? input.files!.first : null;
  if (file == null) {
    return null;
  }

  final reader = html.FileReader();
  reader.readAsDataUrl(file);
  await reader.onLoad.first;

  final result = reader.result;
  if (result is! String || result.isEmpty) {
    return null;
  }

  return PickedSkinImage(
    name: file.name,
    mimeType: file.type.isEmpty ? 'image/jpeg' : file.type,
    dataUrl: result,
  );
}

Future<PickedSkinImage?> _captureFromCamera() async {
  html.MediaStream? stream;
  html.DivElement? overlay;

  try {
    final mediaDevices = html.window.navigator.mediaDevices;
    if (mediaDevices == null) {
      return null;
    }

    stream = await mediaDevices.getUserMedia({
      'audio': false,
      'video': {
        'facingMode': 'user',
        'width': {'ideal': 960},
        'height': {'ideal': 960},
      },
    });

    final completer = Completer<PickedSkinImage?>();
    final video = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..srcObject = stream;
    video.setAttribute('playsinline', 'true');

    final title = html.DivElement()
      ..text = 'Canh khuon mat roi bam Chup anh'
      ..style.color = 'white'
      ..style.fontWeight = '700'
      ..style.fontSize = '16px'
      ..style.textAlign = 'center';

    final captureButton = html.ButtonElement()
      ..text = 'Chup anh'
      ..style.padding = '12px 18px'
      ..style.border = '0'
      ..style.borderRadius = '12px'
      ..style.backgroundColor = '#5ba4d2'
      ..style.color = 'white'
      ..style.fontWeight = '700';

    final cancelButton = html.ButtonElement()
      ..text = 'Huy'
      ..style.padding = '12px 18px'
      ..style.border = '1px solid rgba(255,255,255,.45)'
      ..style.borderRadius = '12px'
      ..style.backgroundColor = 'transparent'
      ..style.color = 'white'
      ..style.fontWeight = '700';

    final controls = html.DivElement()
      ..style.display = 'flex'
      ..style.justifyContent = 'center'
      ..style.gap = '12px'
      ..children.addAll([captureButton, cancelButton]);

    final panel = html.DivElement()
      ..style.width = 'min(92vw, 520px)'
      ..style.padding = '16px'
      ..style.borderRadius = '18px'
      ..style.backgroundColor = '#101827'
      ..style.boxShadow = '0 24px 80px rgba(0,0,0,.35)'
      ..style.display = 'flex'
      ..style.flexDirection = 'column'
      ..style.gap = '14px'
      ..children.addAll([
        title,
        video
          ..style.width = '100%'
          ..style.maxHeight = '68vh'
          ..style.objectFit = 'cover'
          ..style.borderRadius = '14px'
          ..style.backgroundColor = '#000',
        controls,
      ]);

    overlay = html.DivElement()
      ..style.position = 'fixed'
      ..style.top = '0'
      ..style.left = '0'
      ..style.right = '0'
      ..style.bottom = '0'
      ..style.zIndex = '2147483647'
      ..style.backgroundColor = 'rgba(0,0,0,.72)'
      ..style.display = 'flex'
      ..style.alignItems = 'center'
      ..style.justifyContent = 'center'
      ..style.padding = '18px'
      ..children.add(panel);

    html.document.body?.append(overlay);

    await video.onCanPlay.first.timeout(const Duration(seconds: 10));

    captureButton.onClick.first.then((_) {
      if (completer.isCompleted) return;
      final width = video.videoWidth > 0 ? video.videoWidth : 720;
      final height = video.videoHeight > 0 ? video.videoHeight : 720;
      final canvas = html.CanvasElement(width: width, height: height);
      final context = canvas.context2D;
      context.drawImage(video, 0, 0);
      final dataUrl = canvas.toDataUrl('image/jpeg', 0.9);
      completer.complete(
        PickedSkinImage(
          name: 'camera-${DateTime.now().millisecondsSinceEpoch}.jpg',
          mimeType: 'image/jpeg',
          dataUrl: dataUrl,
        ),
      );
    });

    cancelButton.onClick.first.then((_) {
      if (!completer.isCompleted) completer.complete(null);
    });

    return await completer.future.timeout(const Duration(minutes: 5));
  } catch (_) {
    return null;
  } finally {
    overlay?.remove();
    for (final track
        in stream?.getTracks() ?? const <html.MediaStreamTrack>[]) {
      track.stop();
    }
  }
}
