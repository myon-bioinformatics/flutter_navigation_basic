import 'dart:typed_data';

/// No native image codec bridge on web (use the browser canvas adapter instead).
Future<Uint8List?> nativeImageNormalizeAdapter(Uint8List bytes) async => null;
