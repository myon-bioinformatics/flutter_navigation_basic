import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/shared/diagnostics/build_metadata.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RevisionMetadata.fromJson', () {
    test('defaults every field gracefully when the map is empty', () {
      final revision = RevisionMetadata.fromJson(const {});

      expect(revision.sha, isNull);
      expect(revision.shortSha, isNull);
      expect(revision.ref, isNull);
      expect(revision.committedAt, isNull);
      expect(revision.subject, isNull);
      expect(revision.commitUrl, isNull);
      expect(revision.dirty, isFalse);
      expect(revision.displaySha, 'unknown');
    });

    test('parses a fully populated map', () {
      final revision = RevisionMetadata.fromJson(const {
        'sha': 'abcdef1234567890',
        'shortSha': 'abcdef12',
        'ref': 'main',
        'committedAt': '2026-08-18T00:00:00Z',
        'subject': 'feat: show deployed git revision on home',
        'commitUrl': 'https://github.com/example/repo/commit/abcdef1234567890',
        'dirty': true,
      });

      expect(revision.sha, 'abcdef1234567890');
      expect(revision.shortSha, 'abcdef12');
      expect(revision.ref, 'main');
      expect(revision.committedAt, '2026-08-18T00:00:00Z');
      expect(revision.subject, 'feat: show deployed git revision on home');
      expect(revision.commitUrl, 'https://github.com/example/repo/commit/abcdef1234567890');
      expect(revision.dirty, isTrue);
      expect(revision.displaySha, 'abcdef12');
    });

    test('displaySha falls back to a truncated sha when shortSha is absent', () {
      final revision = RevisionMetadata.fromJson(const {'sha': 'abcdef1234567890'});

      expect(revision.shortSha, isNull);
      expect(revision.displaySha, 'abcdef12');
    });

    test('displaySha returns the full sha when shorter than 8 characters', () {
      final revision = RevisionMetadata.fromJson(const {'sha': 'abc12'});

      expect(revision.displaySha, 'abc12');
    });
  });

  group('BuildMetadata.fromJson backward compatibility', () {
    test('degrades gracefully when repository.revision is absent', () {
      // Use an inline legacy fixture instead of the live asset. CI refreshes
      // assets/diagnostics/build_meta.json via `dart run tool/dev.dart meta`
      // before the GitHub Pages web build, so the checked-in file is not a
      // stable stand-in for "revision missing".
      final metadata = BuildMetadata.fromJson(const {
        'app': {
          'version': '0.0.1',
          'buildNumber': 1,
          'stage': 'pre-beta',
        },
        'measurement': {
          'platform': 'unmeasured',
          'mode': 'release',
          'artifactBytes': null,
        },
        'repository': {
          'sourceBytes': null,
          'assetBytes': null,
        },
        'screens': <String, Object>{},
      });

      expect(metadata.revision.sha, isNull);
      expect(metadata.revision.dirty, isFalse);
      expect(metadata.revision.displaySha, 'unknown');
      expect(metadata.version, '0.0.1');
      expect(metadata.buildNumber, 1);
    });

    test('parses repository.revision when present', () {
      final metadata = BuildMetadata.fromJson(const {
        'app': {
          'version': '0.0.1',
          'buildNumber': 1,
          'stage': 'pre-beta',
        },
        'measurement': {
          'platform': 'android-arm64',
          'mode': 'release',
          'artifactBytes': 1024,
        },
        'repository': {
          'sourceBytes': 2048,
          'assetBytes': 512,
          'revision': {
            'sha': 'abcdef1234567890',
            'shortSha': 'abcdef12',
            'ref': 'main',
            'committedAt': '2026-08-18T00:00:00Z',
            'subject': 'feat: show deployed git revision on home',
            'commitUrl': 'https://github.com/example/repo/commit/abcdef1234567890',
            'dirty': false,
          },
        },
        'screens': <String, Object>{},
      });

      expect(metadata.revision.sha, 'abcdef1234567890');
      expect(metadata.revision.displaySha, 'abcdef12');
      expect(metadata.artifactBytes, 1024);
      expect(metadata.sourceBytes, 2048);
      expect(metadata.assetBytes, 512);
    });
  });

  group('BuildMetadata.load', () {
    test('loads the checked-in diagnostics asset without throwing', () async {
      final metadata = await BuildMetadata.load();

      expect(metadata.version, isNotEmpty);
      expect(metadata.displayVersion, startsWith('v'));
    });
  });
}
