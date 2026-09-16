import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import '../data/photo_import_limits.dart';
import '../data/photo_media_ports.dart';

/// Web-only local image pick via a hidden file input (no package dependency).
Future<Uint8List?> pickLocalImageBytes() async {
  final outcome = await pickLocalImageBytesDetailed();
  return outcome.bytes;
}

Future<PhotoPickOutcome> pickLocalImageBytesDetailed() {
  final completer = Completer<PhotoPickOutcome>();
  final input = html.FileUploadInputElement()
    ..accept = 'image/png,image/jpeg,image/webp,image/*'
    ..style.display = 'none';
  html.document.body?.append(input);

  StreamSubscription<html.Event>? focusSubscription;
  var selectionStarted = false;
  Timer? cancelTimer;

  void finish(PhotoPickOutcome outcome) {
    cancelTimer?.cancel();
    cancelTimer = null;
    focusSubscription?.cancel();
    focusSubscription = null;
    input.remove();
    if (!completer.isCompleted) {
      completer.complete(outcome);
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
      finish(const PhotoPickOutcome.cancelled());
      return;
    }
    final file = files.first;
    if (file.size > PhotoImportLimits.maxInputBytes) {
      finish(
        const PhotoPickOutcome.rejected(PhotoImportRejection.tooLargeBytes),
      );
      return;
    }
    final reader = html.FileReader();
    reader.onError.listen((_) => finish(const PhotoPickOutcome.failed()));
    reader.onAbort.listen((_) => finish(const PhotoPickOutcome.cancelled()));
    reader.onLoad.listen((_) {
      final result = reader.result;
      if (result is ByteBuffer) {
        final bytes = result.asUint8List();
        if (bytes.isEmpty) {
          finish(const PhotoPickOutcome.failed());
        } else {
          finish(PhotoPickOutcome.success(bytes));
        }
      } else {
        finish(const PhotoPickOutcome.failed());
      }
    });
    reader.readAsArrayBuffer(file);
  });

  // Hidden inputs rarely blur. When the file dialog closes without a selection,
  // the window typically regains focus — settle as cancelled only if onChange
  // never started a read.
  focusSubscription = html.window.onFocus.listen((_) {
    cancelTimer?.cancel();
    cancelTimer = Timer(const Duration(milliseconds: 300), () {
      if (!selectionStarted && !completer.isCompleted) {
        finish(const PhotoPickOutcome.cancelled());
      }
    });
  });

  input.click();
  return completer.future;
}
