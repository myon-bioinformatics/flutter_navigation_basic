import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import '../data/clipboard_image_read.dart';

/// Web-only: read the first image/* item from the system clipboard, if any.
///
/// Uses the async Clipboard API. Callers should still accept Base64 text and
/// [ContentInsertionConfiguration] as fallbacks — browser permissions vary.
///
/// When [maxBytes] is set, Blobs larger than that limit are reported as
/// [ClipboardImageRead.tooLarge] when no smaller image is present.
Future<ClipboardImageRead> readWebClipboardImage({int? maxBytes}) async {
  try {
    final clipboard = html.window.navigator.clipboard;
    if (clipboard == null) return const ClipboardImageRead.unavailable();
    // Typed as dynamic: dart:html stubs differ across analyzer platforms.
    final dynamic items = await clipboard.read();
    final int length = items.length as int;
    var sawImage = false;
    var sawTooLarge = false;
    var sawReadFailure = false;
    for (var i = 0; i < length; i++) {
      final dynamic item = items[i];
      final dynamic types = item.types;
      final int typeCount = types.length as int;
      for (var t = 0; t < typeCount; t++) {
        final type = types[t] as String;
        if (!type.startsWith('image/')) continue;
        sawImage = true;
        final html.Blob blob = await item.getType(type) as html.Blob;
        if (maxBytes != null && blob.size > maxBytes) {
          sawTooLarge = true;
          continue;
        }
        final bytes = await _readBlobAsBytes(blob);
        if (bytes != null && bytes.isNotEmpty) {
          return ClipboardImageRead.bytes(bytes);
        }
        sawReadFailure = true;
      }
    }
    if (sawTooLarge) return const ClipboardImageRead.tooLarge();
    if (sawReadFailure) return const ClipboardImageRead.readFailed();
    if (!sawImage) return const ClipboardImageRead.empty();
    return const ClipboardImageRead.empty();
  } catch (error) {
    final text = error.toString().toLowerCase();
    if (text.contains('notallowed') ||
        text.contains('denied') ||
        text.contains('permission')) {
      return const ClipboardImageRead.denied();
    }
    if (text.contains('notsupported') ||
        text.contains('undefined') ||
        text.contains('is not a function')) {
      return const ClipboardImageRead.unavailable();
    }
    return const ClipboardImageRead.readFailed();
  }
}

Future<Uint8List?> _readBlobAsBytes(html.Blob blob) {
  final reader = html.FileReader();
  final completer = Completer<Uint8List?>();
  Timer? timeout;
  StreamSubscription<html.ProgressEvent>? loadSub;
  StreamSubscription<html.ProgressEvent>? errorSub;

  void cleanup() {
    timeout?.cancel();
    timeout = null;
    loadSub?.cancel();
    loadSub = null;
    errorSub?.cancel();
    errorSub = null;
  }

  void finish(Uint8List? value) {
    cleanup();
    try {
      reader.abort();
    } catch (_) {
      // Already finished / not abortable.
    }
    if (!completer.isCompleted) {
      completer.complete(value);
    }
  }

  timeout = Timer(const Duration(seconds: 10), () => finish(null));
  errorSub = reader.onError.listen((_) => finish(null));
  loadSub = reader.onLoad.listen((_) {
    final result = reader.result;
    if (result is ByteBuffer) {
      finish(result.asUint8List());
    } else {
      finish(null);
    }
  });
  reader.readAsArrayBuffer(blob);
  return completer.future;
}
