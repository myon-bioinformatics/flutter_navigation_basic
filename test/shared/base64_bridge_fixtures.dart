import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/shared/clipboard/base64_image_bridge.dart';

/// Paths to the vendored Ironmate fixture and Flutter expectation mapping.
class Base64BridgeFixtures {
  Base64BridgeFixtures._();

  static final Directory _repoRoot = _findRepoRoot();

  static Directory _findRepoRoot() {
    var dir = Directory.current;
    while (!File('${dir.path}/pubspec.yaml').existsSync()) {
      final parent = dir.parent;
      if (parent.path == dir.path) {
        throw StateError('Could not locate repository root from ${Directory.current.path}');
      }
      dir = parent;
    }
    return dir;
  }

  static final String fixtureDir = '${_repoRoot.path}/test/fixtures/base64_bridge';

  static Map<String, dynamic> loadCasesDocument() {
    final raw = File('$fixtureDir/base64_bridge_cases.json').readAsStringSync();
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Map<String, dynamic> loadExpectationsDocument() {
    final raw = File('$fixtureDir/flutter_expectations.json').readAsStringSync();
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Map<String, dynamic> loadProvenanceDocument() {
    final raw =
        File('$fixtureDir/base64_bridge_cases.provenance.json').readAsStringSync();
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static List<Map<String, dynamic>> loadCases() {
    final cases = loadCasesDocument()['cases'];
    if (cases is! List) {
      throw StateError('base64_bridge_cases.json: cases must be a list');
    }
    return cases.cast<Map<String, dynamic>>();
  }

  static Map<String, Map<String, dynamic>> loadExpectationsById() {
    final cases = loadExpectationsDocument()['cases'];
    if (cases is! Map) {
      throw StateError('flutter_expectations.json: cases must be a map');
    }
    return cases.map(
      (key, value) => MapEntry(key as String, (value as Map).cast<String, dynamic>()),
    );
  }

  static void assertProvenanceHashMatches() {
    final provenance = loadProvenanceDocument();
    final bytes = File('$fixtureDir/base64_bridge_cases.json').readAsBytesSync();
    final digest = sha256.convert(bytes).toString();
    expect(digest, provenance['sha256'], reason: 'vendored fixture drift; refresh from provenance source_commit');
  }

  static String detectedFormatFromPayload(Base64ImagePayload payload) {
    return switch (payload.mimeType) {
      'image/png' => 'png',
      'image/jpeg' => 'jpeg',
      'image/webp' => 'webp',
      _ => throw StateError('unexpected mime: ${payload.mimeType}'),
    };
  }
}
