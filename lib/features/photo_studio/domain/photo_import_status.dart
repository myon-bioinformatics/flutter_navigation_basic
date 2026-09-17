import 'package:flutter/foundation.dart';

import '../data/photo_media_ports.dart';

/// Lifecycle of the latest Import / Paste / insert attempt.
enum PhotoImportPhase {
  idle,
  loading,
  success,
  failure,
  superseded,
  cancelled,
}

/// Why an import failed (maps to user-facing copy, no raw bytes).
enum PhotoImportFailureReason {
  noClipboardImage,
  clipboardUnavailable,
  pickUnavailable,
  pickFailed,
  tooLarge,
  unsupportedFormat,
  decodeFailed,
}

/// How the latest import was initiated (for retry).
enum PhotoImportSource { pick, paste, insert }

/// Persistent Import/Paste status shown near the preview / import controls.
@immutable
class PhotoImportStatus {
  const PhotoImportStatus({
    required this.phase,
    this.source,
    this.failureReason,
    this.formatLabel,
    this.width,
    this.height,
    this.fileName,
  });

  const PhotoImportStatus.idle() : this(phase: PhotoImportPhase.idle);

  const PhotoImportStatus.loading({PhotoImportSource? source})
      : this(phase: PhotoImportPhase.loading, source: source);

  const PhotoImportStatus.success({
    PhotoImportSource? source,
    String formatLabel = 'PNG',
    required int width,
    required int height,
    String? fileName,
  }) : this(
          phase: PhotoImportPhase.success,
          source: source,
          formatLabel: formatLabel,
          width: width,
          height: height,
          fileName: fileName,
        );

  const PhotoImportStatus.failure({
    required PhotoImportFailureReason reason,
    PhotoImportSource? source,
  }) : this(
          phase: PhotoImportPhase.failure,
          source: source,
          failureReason: reason,
        );

  const PhotoImportStatus.superseded({PhotoImportSource? source})
      : this(phase: PhotoImportPhase.superseded, source: source);

  const PhotoImportStatus.cancelled({PhotoImportSource? source})
      : this(phase: PhotoImportPhase.cancelled, source: source);

  final PhotoImportPhase phase;
  final PhotoImportSource? source;
  final PhotoImportFailureReason? failureReason;
  final String? formatLabel;
  final int? width;
  final int? height;
  final String? fileName;

  bool get isBusy => phase == PhotoImportPhase.loading;

  bool get canRetry =>
      phase == PhotoImportPhase.failure &&
      (source == PhotoImportSource.pick || source == PhotoImportSource.paste);

  /// Primary status line catalog key (never embeds bytes / clipboard / tokens).
  String get messageKey {
    switch (phase) {
      case PhotoImportPhase.idle:
        return 'photoStudio.importIdle';
      case PhotoImportPhase.loading:
        return 'photoStudio.importLoading';
      case PhotoImportPhase.success:
        return 'photoStudio.importSuccess';
      case PhotoImportPhase.superseded:
        return 'photoStudio.importSuperseded';
      case PhotoImportPhase.cancelled:
        return 'photoStudio.importCancelled';
      case PhotoImportPhase.failure:
        return switch (failureReason) {
          PhotoImportFailureReason.noClipboardImage =>
            'photoStudio.noClipboardImage',
          PhotoImportFailureReason.clipboardUnavailable =>
            'photoStudio.clipboardUnavailable',
          PhotoImportFailureReason.pickUnavailable =>
            'photoStudio.pickImageUnavailable',
          PhotoImportFailureReason.pickFailed => 'photoStudio.imageError',
          PhotoImportFailureReason.tooLarge => 'photoStudio.imageTooLarge',
          PhotoImportFailureReason.unsupportedFormat =>
            'photoStudio.imageUnsupported',
          PhotoImportFailureReason.decodeFailed || null =>
            'photoStudio.imageError',
        };
    }
  }

  /// Optional second line for success metadata (`PNG · W × H`).
  String? get metaMessageKey =>
      phase == PhotoImportPhase.success ? 'photoStudio.importSuccessMeta' : null;

  Map<String, Object?> get metaArguments => {
        'format': formatLabel ?? 'PNG',
        'width': width ?? 0,
        'height': height ?? 0,
        if (fileName != null && fileName!.isNotEmpty) 'fileName': fileName,
      };

  static PhotoImportFailureReason fromRejection(PhotoImportRejection rejection) {
    return switch (rejection) {
      PhotoImportRejection.tooLargeBytes ||
      PhotoImportRejection.tooManyPixels =>
        PhotoImportFailureReason.tooLarge,
      PhotoImportRejection.heicConversionFailed ||
      PhotoImportRejection.undecodable =>
        PhotoImportFailureReason.unsupportedFormat,
      PhotoImportRejection.empty => PhotoImportFailureReason.decodeFailed,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is PhotoImportStatus &&
        other.phase == phase &&
        other.source == source &&
        other.failureReason == failureReason &&
        other.formatLabel == formatLabel &&
        other.width == width &&
        other.height == height &&
        other.fileName == fileName;
  }

  @override
  int get hashCode => Object.hash(
        phase,
        source,
        failureReason,
        formatLabel,
        width,
        height,
        fileName,
      );
}
