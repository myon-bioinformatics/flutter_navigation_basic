import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

String _browserImageMimeType(Uint8List bytes) {
  if (bytes.length >= 8 && bytes[0] == 137 && bytes[1] == 80 && bytes[2] == 78 && bytes[3] == 71) return 'image/png';
  if (bytes.length >= 3 && bytes[0] == 255 && bytes[1] == 216 && bytes[2] == 255) return 'image/jpeg';
  if (bytes.length >= 4 && bytes[0] == 71 && bytes[1] == 73 && bytes[2] == 70 && bytes[3] == 56) return 'image/gif';
  if (bytes.length >= 12 && bytes[0] == 82 && bytes[1] == 73 && bytes[2] == 70 && bytes[3] == 70 && bytes[8] == 87 && bytes[9] == 69 && bytes[10] == 66 && bytes[11] == 80) return 'image/webp';
  return 'application/octet-stream';
}

/// Browser-native decode → PNG bytes for formats Flutter's codec rejects
/// (e.g. some HEIC/HEIF payloads on browsers that can still paint them).
Future<Uint8List?> browserImageDecodeAdapter(Uint8List bytes) async {
  if (bytes.isEmpty) return null;

  String? objectUrl;
  html.ImageElement? image;
  html.CanvasElement? canvas;
  StreamSubscription<html.Event>? loadSub;
  StreamSubscription<html.Event>? errorSub;
  try {
    final blob = html.Blob([bytes], _browserImageMimeType(bytes));
    objectUrl = html.Url.createObjectUrlFromBlob(blob);
    image = html.ImageElement();
    final loaded = Completer<void>();
    loadSub = image.onLoad.listen((_) {
      if (!loaded.isCompleted) loaded.complete();
    });
    errorSub = image.onError.listen((_) {
      if (!loaded.isCompleted) {
        loaded.completeError(StateError('browser image decode failed'));
      }
    });
    image.src = objectUrl;
    await loaded.future.timeout(const Duration(seconds: 8));

    final width = image.naturalWidth;
    final height = image.naturalHeight;
    if (width <= 0 || height <= 0) return null;

    canvas = html.CanvasElement(width: width, height: height);
    final ctx = canvas.context2D;
    ctx.drawImage(image, 0, 0);
    final dataUrl = canvas.toDataUrl('image/png');
    final comma = dataUrl.indexOf(',');
    if (comma < 0) return null;
    return Uri.parse(dataUrl).data?.contentAsBytes();
  } catch (_) {
    return null;
  } finally {
    loadSub?.cancel();
    errorSub?.cancel();
    image?.src = '';
    if (objectUrl != null) {
      html.Url.revokeObjectUrl(objectUrl);
    }
    canvas?.width = 0;
    canvas?.height = 0;
  }
}
