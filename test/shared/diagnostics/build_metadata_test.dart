import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/shared/diagnostics/build_metadata.dart';

import '../../../tool/src/repository_metadata.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('canonical repository metadata adapter', () {
    late Map<String, dynamic> canonical;
    setUp(() {
      canonical =
          jsonDecode(
                File(
                  'tool/python/fixtures/repository_metadata_v1.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
    });

    test('producer fields reach the existing UI model unchanged', () {
      final head = canonical['head'] as Map<String, dynamic>;
      final revision = revisionFromRepositoryMetadata(canonical, dirty: true);
      final metadata = BuildMetadata.fromJson({
        'app': {'version': '0.1.0', 'buildNumber': 7, 'stage': 'pre-beta'},
        'measurement': {
          'platform': 'web',
          'mode': 'release',
          'artifactBytes': 123,
        },
        'repository': {
          'revision': revision,
          'sourceBytes': 456,
          'assetBytes': 789,
        },
        'screens': {
          'photo_studio': {'sourceBytes': 10, 'featureBytes': 20},
        },
        'routeSources': {
          'screen6': {'sourceBytes': 30, 'path': 'lib/screens/screen6.dart'},
        },
      });
      expect(metadata.revision.sha, head['sha']);
      expect(metadata.revision.shortSha, head['short_sha']);
      expect(metadata.revision.ref, head['branch']);
      expect(metadata.revision.committedAt, head['timestamp']);
      expect(metadata.revision.subject, head['subject']);
      expect(metadata.revision.dirty, isTrue);
      expect(
        metadata.revision.commitUrl,
        'https://github.com/myon-bioinformatics/Ironmate/commit/${head['sha']}',
      );
      expect(metadata.buildNumber, 7);
      expect(metadata.platform, 'web');
      expect(metadata.artifactBytes, 123);
      expect(metadata.sourceBytes, 456);
      expect(metadata.assetBytes, 789);
      expect(metadata.screens['photo_studio']!.featureBytes, 20);
      expect(metadata.routeSources['screen6']!.sourceBytes, 30);
    });

    test(
      'missing canonical input fails rather than reading local Git',
      () async {
        final temp = await Directory.systemTemp.createTemp(
          'repository-metadata-',
        );
        try {
          await expectLater(
            readRepositoryRevision('${temp.path}/missing.json', dirty: false),
            throwsA(isA<FileSystemException>()),
          );
          final invalid = File('${temp.path}/invalid.json');
          await invalid.writeAsString('[]');
          await expectLater(
            readRepositoryRevision(invalid.path, dirty: false),
            throwsFormatException,
          );
        } finally {
          await temp.delete(recursive: true);
        }
      },
    );

    test(
      'unsupported schema or absent head fields cannot trigger fallback',
      () {
        canonical['schema_version'] = '2.0';
        expect(
          () => revisionFromRepositoryMetadata(canonical, dirty: false),
          throwsFormatException,
        );
        canonical['schema_version'] = '1.0';
        for (final key in [
          'sha',
          'short_sha',
          'branch',
          'timestamp',
          'subject',
        ]) {
          final head = canonical['head'] as Map<String, dynamic>;
          final saved = head.remove(key);
          expect(
            () => revisionFromRepositoryMetadata(canonical, dirty: false),
            throwsFormatException,
          );
          head[key] = saved;
        }
      },
    );
  });

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
      expect(
        revision.commitUrl,
        'https://github.com/example/repo/commit/abcdef1234567890',
      );
      expect(revision.dirty, isTrue);
      expect(revision.displaySha, 'abcdef12');
    });

    test(
      'displaySha falls back to a truncated sha when shortSha is absent',
      () {
        final revision = RevisionMetadata.fromJson(const {
          'sha': 'abcdef1234567890',
        });

        expect(revision.shortSha, isNull);
        expect(revision.displaySha, 'abcdef12');
      },
    );

    test('displaySha returns the full sha when shorter than 8 characters', () {
      final revision = RevisionMetadata.fromJson(const {'sha': 'abc12'});

      expect(revision.displaySha, 'abc12');
    });
  });

  group('BuildMetadata.fromJson backward compatibility', () {
    test('degrades gracefully when repository.revision is absent', () {
      // Prefer an inline legacy fixture for the "revision missing" case.
      // The checked-in assets/diagnostics/build_metadata.json is now the
      // deterministic neutral fallback (asserted in BuildMetadata.load),
      // and CI still refreshes it via `dart run tool/dev.dart meta` before
      // the GitHub Pages web build — so do not use that live asset here.
      final metadata = BuildMetadata.fromJson(const {
        'app': {'version': '0.1.0', 'buildNumber': 1, 'stage': 'pre-beta'},
        'measurement': {
          'platform': 'unmeasured',
          'mode': 'release',
          'artifactBytes': null,
        },
        'repository': {'sourceBytes': null, 'assetBytes': null},
        'screens': <String, Object>{},
      });

      expect(metadata.revision.sha, isNull);
      expect(metadata.revision.dirty, isFalse);
      expect(metadata.revision.displaySha, 'unknown');
      expect(metadata.version, '0.1.0');
      expect(metadata.buildNumber, 1);
      expect(metadata.displayVersion, 'v0.1.0');
      expect(metadata.displayBuild, 'build 1');
      expect(metadata.displayVersionWithBuild, 'v0.1.0+1');
    });

    test('parses repository.revision when present', () {
      final metadata = BuildMetadata.fromJson(const {
        'app': {'version': '0.1.0', 'buildNumber': 1, 'stage': 'pre-beta'},
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
            'commitUrl':
                'https://github.com/example/repo/commit/abcdef1234567890',
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
    test('loads the tracked deterministic fallback asset', () async {
      final metadata = await BuildMetadata.load();

      expect(metadata.version, '0.1.0');
      expect(metadata.buildNumber, 1);
      expect(metadata.displayVersion, 'v0.1.0');
      expect(metadata.displayVersion, isNot(contains('+')));
      expect(metadata.displayBuild, 'build 1');
      expect(metadata.displayVersionWithBuild, 'v0.1.0+1');
      // Checked-in file must stay a neutral placeholder (no live SHA/sizes).
      expect(metadata.revision.sha, isNull);
      expect(metadata.revision.displaySha, 'unknown');
      expect(metadata.revision.dirty, isFalse);
      expect(metadata.sourceBytes, isNull);
      expect(metadata.screens, isEmpty);
      expect(metadata.routeSources, isEmpty);
    });
  });
}
