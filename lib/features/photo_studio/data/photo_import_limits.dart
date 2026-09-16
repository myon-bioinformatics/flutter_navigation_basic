/// Safety ceilings for Photo Studio import / document storage.
///
/// Raw phone photos often exceed the old 4 MiB gate. We still refuse unbounded
/// payloads: byte count and decoded pixel count are both capped, then the
/// document is PNG-normalized and downscaled to [maxDocumentLongEdge].
abstract final class PhotoImportLimits {
  /// Maximum accepted raw input bytes (picker / paste / clipboard).
  static const int maxInputBytes = 32 * 1024 * 1024;

  /// Maximum width × height after decode (before document downscale).
  static const int maxPixels = 40 * 1000 * 1000; // 40 MP

  /// Longest edge kept in the editable studio document (PNG).
  static const int maxDocumentLongEdge = 4096;

  /// Soft shrink applied when the image already fits the long-edge budget.
  static const double defaultDownscale = 2 / 3;
}
