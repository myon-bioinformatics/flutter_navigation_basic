import 'dart:typed_data';

/// No native image codec on this host (e.g. pure Dart VM without plugins).
Future<Uint8List?> nativeImageNormalizeAdapter(Uint8List bytes) async => null;
