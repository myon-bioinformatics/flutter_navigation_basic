import 'package:flutter_application_1/features/photo_studio/data/photo_media_ports.dart';
import 'package:flutter_application_1/features/photo_studio/domain/photo_import_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PhotoImportStatus', () {
    test('idle / loading / cancelled / superseded keys', () {
      expect(const PhotoImportStatus.idle().messageKey, 'photoStudio.importIdle');
      expect(
        const PhotoImportStatus.loading().messageKey,
        'photoStudio.importLoading',
      );
      expect(
        const PhotoImportStatus.cancelled().messageKey,
        'photoStudio.importCancelled',
      );
      expect(
        const PhotoImportStatus.superseded().messageKey,
        'photoStudio.importSuperseded',
      );
    });

    test('success exposes safe meta without bytes', () {
      const status = PhotoImportStatus.success(width: 1170, height: 2532);
      expect(status.messageKey, 'photoStudio.importSuccess');
      expect(status.metaMessageKey, 'photoStudio.importSuccessMeta');
      expect(status.metaArguments['format'], 'PNG');
      expect(status.metaArguments['width'], 1170);
      expect(status.metaArguments['height'], 2532);
      expect(status.metaArguments.containsKey('bytes'), isFalse);
    });

    test('failure reasons map to distinct keys', () {
      expect(
        const PhotoImportStatus.failure(
          reason: PhotoImportFailureReason.noClipboardImage,
        ).messageKey,
        'photoStudio.noClipboardImage',
      );
      expect(
        const PhotoImportStatus.failure(
          reason: PhotoImportFailureReason.clipboardUnavailable,
        ).messageKey,
        'photoStudio.clipboardUnavailable',
      );
      expect(
        const PhotoImportStatus.failure(
          reason: PhotoImportFailureReason.tooLarge,
        ).messageKey,
        'photoStudio.imageTooLarge',
      );
      expect(
        const PhotoImportStatus.failure(
          reason: PhotoImportFailureReason.unsupportedFormat,
        ).messageKey,
        'photoStudio.imageUnsupported',
      );
    });

    test('fromRejection covers gate outcomes', () {
      expect(
        PhotoImportStatus.fromRejection(PhotoImportRejection.tooLargeBytes),
        PhotoImportFailureReason.tooLarge,
      );
      expect(
        PhotoImportStatus.fromRejection(PhotoImportRejection.undecodable),
        PhotoImportFailureReason.unsupportedFormat,
      );
      expect(
        PhotoImportStatus.fromRejection(PhotoImportRejection.empty),
        PhotoImportFailureReason.decodeFailed,
      );
    });

    test('canRetry only for pick/paste failures', () {
      expect(
        const PhotoImportStatus.failure(
          reason: PhotoImportFailureReason.noClipboardImage,
          source: PhotoImportSource.paste,
        ).canRetry,
        isTrue,
      );
      expect(
        const PhotoImportStatus.failure(
          reason: PhotoImportFailureReason.pickFailed,
          source: PhotoImportSource.pick,
        ).canRetry,
        isTrue,
      );
      expect(
        const PhotoImportStatus.failure(
          reason: PhotoImportFailureReason.decodeFailed,
          source: PhotoImportSource.insert,
        ).canRetry,
        isFalse,
      );
      expect(const PhotoImportStatus.success(width: 1, height: 1).canRetry, isFalse);
    });
  });
}
