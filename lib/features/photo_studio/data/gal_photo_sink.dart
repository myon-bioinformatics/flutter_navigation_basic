import 'package:flutter/services.dart';
import 'package:gal/gal.dart';

import 'photo_media_ports.dart';

/// PNG save port that writes into the device photo library via [Gal].
///
/// Web continues to use the browser download sink; this port is IO/mobile only.
class GalPhotoSink {
  const GalPhotoSink();

  Future<PhotoSaveOutcome> savePng({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (bytes.isEmpty) return const PhotoSaveOutcome.failed();
    try {
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) return const PhotoSaveOutcome.unavailable();
      }
      final name = fileName.replaceAll(RegExp(r'\.png$', caseSensitive: false), '');
      await Gal.putImageBytes(bytes, name: name.isEmpty ? 'photo-studio' : name);
      return const PhotoSaveOutcome.saved();
    } on GalException {
      return const PhotoSaveOutcome.failed();
    } on MissingPluginException {
      return const PhotoSaveOutcome.unavailable();
    } on PlatformException {
      return const PhotoSaveOutcome.failed();
    } catch (_) {
      return const PhotoSaveOutcome.failed();
    }
  }
}
