import 'dart:typed_data';

import 'save_image_bytes_stub.dart'
    if (dart.library.html) 'save_image_bytes_web.dart';

/// Saves [bytes] as a downloadable file. Web triggers a browser download;
/// other platforms no-op and return false.
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
