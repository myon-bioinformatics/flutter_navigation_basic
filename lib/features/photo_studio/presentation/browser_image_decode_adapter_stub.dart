import 'dart:typed_data';

/// Non-web: no browser-native image decode bridge.
Future<Uint8List?> browserImageDecodeAdapter(Uint8List bytes) async => null;
