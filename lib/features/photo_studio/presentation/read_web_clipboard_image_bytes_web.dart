import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

/// Web-only: read the first image/* item from the system clipboard, if any.
///
/// Uses the async Clipboard API. Callers should still accept Base64 text and
/// [ContentInsertionConfiguration] as fallbacks — browser permissions vary.
///
/// When [maxBytes] is set, Blobs larger than that limit are skipped before
/// allocating a FileReader buffer.
Future<Uint8List?> readWebClipboardImageBytes({int? maxBytes}) async {
  try {
    final clipboard = html.window.navigator.clipboard;
    if (clipboard == null) return null;
    // Typed as dynamic: dart:html stubs differ across analyzer platforms.
    final dynamic items = await clipboard.read();
    final int length = items.length as int;
    for (var i = 0; i < length; i++) {
      final dynamic item = items[i];
      final dynamic types = item.types;
      final int typeCount = types.length as int;
      for (var t = 0; t < typeCount; t++) {
        final type = types[t] as String;
        if (!type.startsWith('image/')) continue;
        final html.Blob blob = await item.getType(type) as html.Blob;
        if (maxBytes != null && blob.size > maxBytes) {
          continue;
        }
        final bytes = await _readBlobAsBytes(blob);
        if (bytes != null && bytes.isNotEmpty) return bytes;
      }
    }
  } catch (_) {
    return null;
  }
  return null;
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
