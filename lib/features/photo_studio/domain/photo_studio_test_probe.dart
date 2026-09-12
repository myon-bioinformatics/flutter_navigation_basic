import 'dart:typed_data';

import 'emoji_stamp.dart';

/// Read-only probe for widget tests (coords, undo depth, shared image refs).
///
/// The production widget imports this class so it can invoke the optional
/// [PhotoStudioPage.onTestProbe] callback, but the callback is a no-op when
/// `null`, so there is no runtime cost in production builds. Callers should
/// only supply an [onTestProbe] callback from test code.
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
