import '../data/clipboard_image_read.dart';

/// Stub for non-web: reading binary clipboard images is unavailable.
Future<ClipboardImageRead> readWebClipboardImage({int? maxBytes}) async =>
    const ClipboardImageRead.empty();
