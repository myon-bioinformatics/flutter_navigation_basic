import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

/// Browser-native decode → PNG bytes for formats Flutter's codec rejects
/// (e.g. some HEIC/HEIF payloads on browsers that can still paint them).
Future<Uint8List?> browserImageDecodeAdapter(Uint8List bytes) async {
  if (bytes.isEmpty) return null;

  String? objectUrl;
  html.ImageElement? image;
  html.CanvasElement? canvas;
  try {
    final blob = html.Blob([bytes]);
    objectUrl = html.Url.createObjectUrlFromBlob(blob);
    image = html.ImageElement();
    final loaded = Completer<void>();
    image.onLoad.listen((_) {
      if (!loaded.isCompleted) loaded.complete();
    });
    image.onError.listen((_) {
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
    image?.src = '';
    if (objectUrl != null) {
      html.Url.revokeObjectUrl(objectUrl);
    }
    canvas?.width = 0;
    canvas?.height = 0;
  }
}
