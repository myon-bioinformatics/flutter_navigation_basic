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

  group('BuildMetadata.load backward compatibility', () {
    test('degrades gracefully against a legacy build_meta.json without repository.revision', () async {
      // The checked-in assets/diagnostics/build_meta.json predates this
      // feature and has no `repository.revision` key at all, which is the
      // real-world scenario BuildMetadata.load() must tolerate.
      final metadata = await BuildMetadata.load();

      expect(metadata.revision.sha, isNull);
      expect(metadata.revision.dirty, isFalse);
      expect(metadata.revision.displaySha, 'unknown');
    });
  });
}
