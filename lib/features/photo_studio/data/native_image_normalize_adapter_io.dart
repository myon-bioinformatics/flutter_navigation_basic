import 'package:flutter/services.dart';

import 'photo_import_limits.dart';
import 'photo_media_ports.dart';

/// MethodChannel that asks iOS/Android to decode bytes → orientation-fixed PNG.
///
/// Used when Flutter's encoded probe cannot read HEIC/HEIF (or similar).
/// Native hosts must probe dimensions, reject >[PhotoImportLimits.maxPixels]
/// before allocating a full-size bitmap, downsample to
/// [PhotoImportLimits.maxDocumentLongEdge], and bake EXIF orientation.
const MethodChannel kNativeImageNormalizeChannel = MethodChannel(
  'com.example.flutter_application_1/image_normalize',
);

typedef NativeNormalizeInvoker = Future<Uint8List?> Function(Uint8List bytes);

/// Default IO adapter: platform ImageIO / ImageDecoder → PNG bytes.
///
/// Inject [invoke] in tests to fake success / failure without a device.
Future<Uint8List?> nativeImageNormalizeAdapter(
  Uint8List bytes, {
  NativeNormalizeInvoker? invoke,
}) async {
  if (bytes.isEmpty) return null;
  final call = invoke ?? _defaultInvoke;
  try {
    return await call(bytes);
  } on NativeImageNormalizeException {
    rethrow;
  } on MissingPluginException {
    return null;
  } on PlatformException catch (error) {
    if (error.code == 'too_many_pixels') {
      throw const NativeImageNormalizeException(
        PhotoImportRejection.tooManyPixels,
      );
    }
    return null;
  } catch (_) {
    return null;
  }
}

Future<Uint8List?> _defaultInvoke(Uint8List bytes) async {
  final result = await kNativeImageNormalizeChannel.invokeMethod<Object?>(
    'normalizeToPng',
    <String, Object>{
      'bytes': bytes,
      'maxPixels': PhotoImportLimits.maxPixels,
      'maxLongEdge': PhotoImportLimits.maxDocumentLongEdge,
    },
  );
  if (result is Uint8List) {
    return result.isEmpty ? null : result;
  }
  if (result is ByteData) {
    final view = result.buffer.asUint8List(
      result.offsetInBytes,
      result.lengthInBytes,
    );
    return view.isEmpty ? null : Uint8List.fromList(view);
  }
  return null;
}
