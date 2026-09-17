import 'dart:typed_data';

import 'photo_import_limits.dart';

/// Why a Photo Studio import was rejected before editing state changes.
enum PhotoImportRejection {
  empty,
  tooLargeBytes,
  tooManyPixels,
  undecodable,
  heicConversionFailed,
}

/// Thrown by native normalize adapters when the host rejects for policy reasons
/// (e.g. pixel budget) before returning PNG bytes.
class NativeImageNormalizeException implements Exception {
  const NativeImageNormalizeException(this.rejection);

  final PhotoImportRejection rejection;

  @override
  String toString() => 'NativeImageNormalizeException($rejection)';
}

/// Status of a gallery / file pick attempt.
enum PhotoPickStatus {
  success,
  cancelled,
  unavailable,
  failed,
  rejected,
}

/// Structured pick outcome so cancel ≠ unavailable ≠ failure ≠ policy reject.
class PhotoPickOutcome {
  const PhotoPickOutcome._(this.status, {this.bytes, this.rejection});

  const PhotoPickOutcome.success(Uint8List bytes)
      : this._(PhotoPickStatus.success, bytes: bytes);

  const PhotoPickOutcome.cancelled() : this._(PhotoPickStatus.cancelled);

  const PhotoPickOutcome.unavailable() : this._(PhotoPickStatus.unavailable);

  const PhotoPickOutcome.failed() : this._(PhotoPickStatus.failed);

  const PhotoPickOutcome.rejected(PhotoImportRejection rejection)
      : this._(PhotoPickStatus.rejected, rejection: rejection);

  final PhotoPickStatus status;
  final Uint8List? bytes;
  final PhotoImportRejection? rejection;
}

/// Status of a PNG save attempt.
enum PhotoSaveStatus { saved, cancelled, unavailable, failed }

class PhotoSaveOutcome {
  const PhotoSaveOutcome._(this.status);

  const PhotoSaveOutcome.saved() : this._(PhotoSaveStatus.saved);
  const PhotoSaveOutcome.cancelled() : this._(PhotoSaveStatus.cancelled);
  const PhotoSaveOutcome.unavailable() : this._(PhotoSaveStatus.unavailable);
  const PhotoSaveOutcome.failed() : this._(PhotoSaveStatus.failed);

  final PhotoSaveStatus status;

  bool get ok => status == PhotoSaveStatus.saved;
}

/// Pure gate used by the page and unit tests (no platform I/O).
abstract final class PhotoImportGate {
  static PhotoImportRejection? rejectRawBytes(Uint8List bytes) {
    if (bytes.isEmpty) return PhotoImportRejection.empty;
    if (bytes.lengthInBytes > PhotoImportLimits.maxInputBytes) {
      return PhotoImportRejection.tooLargeBytes;
    }
    return null;
  }

  static PhotoImportRejection? rejectDecodedSize({
    required int width,
    required int height,
  }) {
    if (width <= 0 || height <= 0) return PhotoImportRejection.undecodable;
    final pixels = width * height;
    if (pixels > PhotoImportLimits.maxPixels) {
      return PhotoImportRejection.tooManyPixels;
    }
    return null;
  }

  /// Known iPhone-relevant HEIC/HEIF major brands in the ISOBMFF `ftyp` box.
  static const heicBrands = <String>{'heic', 'heif', 'mif1', 'msf1', 'heix'};

  static bool isHeicBrand(String brand) => heicBrands.contains(brand);

  /// HEIC/HEIF brand in the ISOBMFF `ftyp` box (bytes 4..8 == 'ftyp').
  static bool looksLikeHeic(Uint8List bytes) {
    if (bytes.lengthInBytes < 12) return false;
    if (bytes[4] != 0x66 ||
        bytes[5] != 0x74 ||
        bytes[6] != 0x79 ||
        bytes[7] != 0x70) {
      return false;
    }
    final brand = String.fromCharCodes(bytes.sublist(8, 12));
    return isHeicBrand(brand);
  }
}
