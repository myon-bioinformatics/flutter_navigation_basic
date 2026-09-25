import 'dart:async';
import 'dart:html' as html;
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;

import '../data/photo_import_limits.dart';
import '../data/photo_media_ports.dart';

/// Web-only local image pick via a hidden file input (no package dependency).
Future<Uint8List?> pickLocalImageBytes() async {
  final outcome = await pickLocalImageBytesDetailed();
  return outcome.bytes;
}

Future<PhotoPickOutcome> pickLocalImageBytesDetailed() {
  debugPrint('[photo-picker-web] 1/5 input:create');
  final completer = Completer<PhotoPickOutcome>();
  final input = html.FileUploadInputElement()
    ..accept = 'image/png,image/jpeg,image/webp,image/*'
    ..style.display = 'none';
  html.document.body?.append(input);

  StreamSubscription<html.Event>? focusSubscription;
  var selectionStarted = false;
  Timer? cancelTimer;

  void finish(PhotoPickOutcome outcome) {
    debugPrint('[photo-picker-web] 5/5 finish status=${outcome.status.name} bytes=${outcome.bytes?.lengthInBytes ?? 0} mime=${outcome.declaredMimeType ?? '-'}');
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
    debugPrint('[photo-picker-web] 2/5 change:event');
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
    debugPrint('[photo-picker-web] 3/5 file:selected name=${file.name} size=${file.size} type=${file.type}');
    if (file.size > PhotoImportLimits.maxInputBytes) {
      finish(
        const PhotoPickOutcome.rejected(PhotoImportRejection.tooLargeBytes),
      );
      return;
    }
    final reader = html.FileReader();
    reader.onError.listen((_) {
      debugPrint('[photo-picker-web] 4/5 reader:error');
      finish(const PhotoPickOutcome.failed());
    });
    reader.onAbort.listen((_) {
      debugPrint('[photo-picker-web] 4/5 reader:abort');
      finish(const PhotoPickOutcome.cancelled());
    });
    reader.onLoad.listen((_) {
      final result = reader.result;
      debugPrint('[photo-picker-web] 4/5 reader:load resultType=${result.runtimeType}');
      Uint8List? bytes;
      if (result is ByteBuffer) {
        bytes = result.asUint8List();
      } else if (result is JSArrayBuffer) {
        // dart2wasm exposes FileReader.result as JSArrayBuffer rather than the
        // dart2js ByteBuffer wrapper. Normalize both runtimes at this boundary.
        bytes = result.toDart.asUint8List();
      }
      if (bytes == null || bytes.isEmpty) {
        debugPrint('[photo-picker-web] 4/5 reader:unsupported-result');
        finish(const PhotoPickOutcome.failed());
      } else {
        debugPrint('[photo-picker-web] 4/5 reader:bytes length=${bytes.lengthInBytes}');
        finish(PhotoPickOutcome.success(bytes, declaredMimeType: file.type));
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

  debugPrint('[photo-picker-web] 1/5 input:click');
  input.click();
  return completer.future;
}
