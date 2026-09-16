import 'dart:typed_data';

import '../data/photo_media_ports.dart';

/// Stub for hosts without a gallery plugin (tests / unsupported platforms).
Future<Uint8List?> pickLocalImageBytes() async => null;

Future<PhotoPickOutcome> pickLocalImageBytesDetailed() async =>
    const PhotoPickOutcome.unavailable();
