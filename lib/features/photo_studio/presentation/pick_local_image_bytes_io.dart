import 'dart:typed_data';

import '../data/image_picker_photo_source.dart';
import '../data/photo_media_ports.dart';

/// IO (iOS / Android / desktop) gallery picker via [ImagePickerPhotoSource].
Future<Uint8List?> pickLocalImageBytes() async {
  final outcome = await pickLocalImageBytesDetailed();
  return outcome.bytes;
}

/// Structured pick for production UI (cancel vs unavailable vs failure).
Future<PhotoPickOutcome> pickLocalImageBytesDetailed() =>
    ImagePickerPhotoSource().pickFromGallery();
