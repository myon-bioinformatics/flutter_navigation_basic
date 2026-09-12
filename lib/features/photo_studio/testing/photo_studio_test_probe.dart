import 'dart:typed_data';

import '../domain/emoji_stamp.dart';

/// Test-only diagnostic snapshot (coords, undo depth, shared image refs).
///
/// Lives under `testing/` (not `domain/`) so production feature APIs stay thin.
/// [PhotoStudioPage.onTestProbe] is marked `@visibleForTesting` and is a no-op
/// when null — supply it only from widget tests.
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
