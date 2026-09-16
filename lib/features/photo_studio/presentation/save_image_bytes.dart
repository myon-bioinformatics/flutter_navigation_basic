import 'dart:typed_data';

import 'save_image_bytes_stub.dart'
    if (dart.library.html) 'save_image_bytes_web.dart'
    if (dart.library.io) 'save_image_bytes_io.dart';

/// Saves [bytes] as a downloadable file (web) or photo-library write (IO).
///
/// Returns false when the platform cannot save (permission denied, missing
/// plugin, unsupported host).
Future<bool> saveImageBytes({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) =>
    saveImageBytesImpl(
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    );
