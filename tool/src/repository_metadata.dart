import 'dart:convert';
import 'dart:io';

/// Adapt producer-owned identity into the existing Flutter diagnostics shape.
/// Missing/invalid input is an error, never a request to recompute Git identity.
Map<String, dynamic> revisionFromRepositoryMetadata(
  Map<String, dynamic> record, {
  required bool dirty,
  String serverUrl = 'https://github.com',
}) {
  if (record['schema_version'] != '1.0') {
    throw const FormatException('Unsupported repository metadata schema');
  }
  final head = record['head'];
  final repository = record['repository'];
  if (head is! Map || repository is! Map) {
    throw const FormatException('Missing canonical head/repository');
  }
  String field(Map map, String key) {
    final value = map[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Missing canonical $key');
    }
    return value;
  }

  final sha = field(head, 'sha');
  final fullName = field(repository, 'full_name');
  return {
    'sha': sha,
    'shortSha': field(head, 'short_sha'),
    'ref': field(head, 'branch'),
    'committedAt': field(head, 'timestamp'),
    'subject': field(head, 'subject'),
    'commitUrl': '$serverUrl/$fullName/commit/$sha',
    'dirty': dirty,
  };
}

Future<Map<String, dynamic>> readRepositoryRevision(
  String path, {
  required bool dirty,
  String serverUrl = 'https://github.com',
}) async {
  final record = jsonDecode(await File(path).readAsString());
  if (record is! Map<String, dynamic>) {
    throw const FormatException('Repository metadata must be an object');
  }
  return revisionFromRepositoryMetadata(
    record,
    dirty: dirty,
    serverUrl: serverUrl,
  );
}
