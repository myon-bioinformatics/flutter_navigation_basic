import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'photo_media_ports.dart';

typedef GalleryPickImage = Future<XFile?> Function({
  required ImageSource source,
});

/// Gallery import port backed by [ImagePicker] (iOS / Android / desktop plugins).
///
/// UI must not call [ImagePicker] directly — inject this (or a fake) instead.
/// Transparent PNG stays as original bytes (no `imageQuality` re-encode).
/// HEIC/HEIF bytes are returned as-is; [nativeImageNormalizeAdapter] converts
/// them to orientation-aware PNG when Flutter's codec cannot probe the file.
class ImagePickerPhotoSource {
  ImagePickerPhotoSource({GalleryPickImage? pickImage})
      : _pickImage = pickImage ??
            (({required ImageSource source}) => ImagePicker().pickImage(
                  source: source,
                  // Do not set imageQuality — that JPEG-reencodes on iOS and drops alpha.
                  requestFullMetadata: false,
                ));

  final GalleryPickImage _pickImage;

  Future<PhotoPickOutcome> pickFromGallery() async {
    try {
      final file = await _pickImage(source: ImageSource.gallery);
      if (file == null) return const PhotoPickOutcome.cancelled();
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return const PhotoPickOutcome.failed();
      return PhotoPickOutcome.success(bytes);
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
