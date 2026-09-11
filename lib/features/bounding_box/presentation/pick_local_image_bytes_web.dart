import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

/// Web-only local image pick via a hidden file input (no package dependency).
Future<Uint8List?> pickLocalImageBytes() {
  final completer = Completer<Uint8List?>();
  final input = html.FileUploadInputElement()
    ..accept = 'image/png,image/jpeg,image/webp,image/*'
    ..style.display = 'none';
  html.document.body?.append(input);

  void finish(Uint8List? bytes) {
    input.remove();
    if (!completer.isCompleted) {
      completer.complete(bytes);
    }
  }

  input.onChange.listen((_) async {
    final files = input.files;
    if (files == null || files.isEmpty) {
      finish(null);
      return;
    }
    final reader = html.FileReader();
    reader.readAsArrayBuffer(files.first);
    await reader.onLoad.first;
    final result = reader.result;
    if (result is ByteBuffer) {
      finish(result.asUint8List());
    } else {
      finish(null);
    }
  });

  // Best-effort cancel detection when the dialog closes without a selection.
  input.onBlur.listen((_) {
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (!completer.isCompleted) {
        finish(null);
      }
    });
  });

  input.click();
  return completer.future;
}
