import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

/// Web-only: read the first image/* item from the system clipboard, if any.
///
/// Uses the async Clipboard API. Callers should still accept Base64 text and
/// [ContentInsertionConfiguration] as fallbacks — browser permissions vary.
Future<Uint8List?> readWebClipboardImageBytes() async {
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
        final reader = html.FileReader();
        final completer = Completer<Uint8List?>();
        reader.onError.listen((_) {
          if (!completer.isCompleted) completer.complete(null);
        });
        reader.onLoad.listen((_) {
          final result = reader.result;
          if (result is ByteBuffer) {
            completer.complete(result.asUint8List());
          } else {
            completer.complete(null);
          }
        });
        reader.readAsArrayBuffer(blob);
        final bytes = await completer.future;
        if (bytes != null && bytes.isNotEmpty) return bytes;
      }
    }
  } catch (_) {
    return null;
  }
  return null;
}
