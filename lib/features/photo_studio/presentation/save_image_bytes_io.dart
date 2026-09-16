import 'dart:typed_data';

import '../data/gal_photo_sink.dart';

Future<bool> saveImageBytesImpl({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  // Photo Studio export is PNG-only; ignore non-PNG mime at the sink boundary.
  if (mimeType.toLowerCase() != 'image/png') return false;
  final outcome = await const GalPhotoSink().savePng(
    bytes: bytes,
    fileName: fileName,
  );
  return outcome.ok;
}
