import 'package:flutter/services.dart';

/// MethodChannel that asks iOS/Android to decode bytes → orientation-fixed PNG.
///
/// Used when Flutter's encoded probe cannot read HEIC/HEIF (or similar).
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
  } on MissingPluginException {
    return null;
  } on PlatformException {
    return null;
  } catch (_) {
    return null;
  }
}

Future<Uint8List?> _defaultInvoke(Uint8List bytes) async {
  final result = await kNativeImageNormalizeChannel.invokeMethod<Object?>(
    'normalizeToPng',
    bytes,
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
