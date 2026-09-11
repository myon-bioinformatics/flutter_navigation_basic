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

  StreamSubscription<html.Event>? focusSubscription;
  var selectionStarted = false;
  Timer? cancelTimer;

  void finish(Uint8List? bytes) {
    cancelTimer?.cancel();
    cancelTimer = null;
    focusSubscription?.cancel();
    focusSubscription = null;
    input.remove();
    if (!completer.isCompleted) {
      completer.complete(bytes);
    }
  }

  input.onChange.listen((_) {
    // A file was chosen (or empty change). Stop treating window focus as cancel.
    selectionStarted = true;
    cancelTimer?.cancel();
    cancelTimer = null;
    focusSubscription?.cancel();
    focusSubscription = null;

    final files = input.files;
    if (files == null || files.isEmpty) {
      finish(null);
      return;
    }
    final reader = html.FileReader();
    reader.onError.listen((_) => finish(null));
    reader.onAbort.listen((_) => finish(null));
    reader.onLoad.listen((_) {
      final result = reader.result;
      if (result is ByteBuffer) {
        finish(result.asUint8List());
      } else {
        finish(null);
      }
    });
    reader.readAsArrayBuffer(files.first);
  });

  // Hidden inputs rarely blur. When the file dialog closes without a selection,
  // the window typically regains focus — settle as cancelled only if onChange
  // never started a read.
  focusSubscription = html.window.onFocus.listen((_) {
    cancelTimer?.cancel();
    cancelTimer = Timer(const Duration(milliseconds: 300), () {
      if (!selectionStarted && !completer.isCompleted) {
        finish(null);
      }
    });
  });

  input.click();
  return completer.future;
}
