import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'photo_import_limits.dart';
import 'photo_media_ports.dart';

typedef GalleryPickImage = Future<XFile?> Function({
  required ImageSource source,
});

typedef GalleryFileLength = Future<int> Function(XFile file);
typedef GalleryFileRead = Future<Uint8List> Function(XFile file);

/// Gallery import port backed by [ImagePicker] (iOS / Android / desktop plugins).
///
/// UI must not call [ImagePicker] directly — inject this (or a fake) instead.
/// Transparent PNG stays as original bytes (no `imageQuality` re-encode).
/// HEIC/HEIF bytes are returned as-is; [nativeImageNormalizeAdapter] converts
/// them to orientation-aware PNG when Flutter's codec cannot probe the file.
///
/// Byte budget is enforced via [XFile.length] **before** [XFile.readAsBytes]
/// so oversized gallery files never enter Dart heap as a full buffer.
class ImagePickerPhotoSource {
  ImagePickerPhotoSource({
    GalleryPickImage? pickImage,
    GalleryFileLength? lengthOf,
    GalleryFileRead? readBytes,
    this.maxInputBytes = PhotoImportLimits.maxInputBytes,
  })  : _pickImage = pickImage ??
            (({required ImageSource source}) => ImagePicker().pickImage(
                  source: source,
                  // Do not set imageQuality — that JPEG-reencodes on iOS and drops alpha.
                  requestFullMetadata: false,
                )),
        _lengthOf = lengthOf ?? ((file) => file.length()),
        _readBytes = readBytes ?? ((file) => file.readAsBytes());

  final GalleryPickImage _pickImage;
  final GalleryFileLength _lengthOf;
  final GalleryFileRead _readBytes;
  final int maxInputBytes;

  Future<PhotoPickOutcome> pickFromGallery() async {
    try {
      final file = await _pickImage(source: ImageSource.gallery);
      if (file == null) return const PhotoPickOutcome.cancelled();

      final length = await _lengthOf(file);
      if (length <= 0) return const PhotoPickOutcome.failed();
      if (length > maxInputBytes) {
        return const PhotoPickOutcome.rejected(
          PhotoImportRejection.tooLargeBytes,
        );
      }

      final bytes = await _readBytes(file);
      if (bytes.isEmpty) return const PhotoPickOutcome.failed();
      // Defense in depth if length() was unavailable / wrong.
      if (bytes.lengthInBytes > maxInputBytes) {
        return const PhotoPickOutcome.rejected(
          PhotoImportRejection.tooLargeBytes,
        );
      }
      return PhotoPickOutcome.success(bytes, declaredMimeType: file.mimeType);
    } on MissingPluginException {
      return const PhotoPickOutcome.unavailable();
    } on PlatformException catch (error) {
      // Permission denial / picker errors.
      final code = error.code.toLowerCase();
      if (code.contains('photo') ||
          code.contains('permission') ||
          code.contains('access')) {
        return const PhotoPickOutcome.unavailable();
      }
      return const PhotoPickOutcome.failed();
    } catch (_) {
      return const PhotoPickOutcome.failed();
    }
  }
}
