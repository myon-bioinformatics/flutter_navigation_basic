import 'dart:typed_data';

typedef NativeNormalizeInvoker = Future<Uint8List?> Function(Uint8List bytes);

/// No native image codec bridge on web (use the browser canvas adapter instead).
///
/// Signature matches the IO adapter so conditional exports stay interchangeable.
Future<Uint8List?> nativeImageNormalizeAdapter(
  Uint8List bytes, {
  NativeNormalizeInvoker? invoke,
}) async {
  if (bytes.isEmpty) return null;
  if (invoke != null) return invoke(bytes);
  return null;
}
