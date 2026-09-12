import 'dart:typed_data';

import 'emoji_stamp.dart';

/// Read-only probe for widget tests (coords, undo depth, shared image refs).
///
/// Injected via [PhotoStudioPage.onTestProbe]; not referenced in production
/// logic. Lives in `lib/` so the production widget can call the callback,
/// but import it only from test code via
/// `package:flutter_application_1/features/photo_studio/domain/photo_studio_test_probe.dart`.
class PhotoStudioTestProbe {
  const PhotoStudioTestProbe({
    required this.stamps,
    required this.undoDepth,
    required this.imageBytes,
    required this.undoImageByteRefs,
    required this.rectLeft,
    required this.rectTop,
    required this.rectRight,
    required this.rectBottom,
    required this.shapeName,
    required this.strokeArgb,
    required this.stampScale,
  });

  final List<EmojiStamp> stamps;
  final int undoDepth;
  final Uint8List? imageBytes;
  final List<Uint8List?> undoImageByteRefs;
  final double rectLeft;
  final double rectTop;
  final double rectRight;
  final double rectBottom;
  final String shapeName;
  final int strokeArgb;
  final double stampScale;
}
