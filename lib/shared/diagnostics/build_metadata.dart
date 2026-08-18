import 'dart:convert';

import 'package:flutter/services.dart';

class BuildMetadata {
  const BuildMetadata({
    required this.version,
    required this.buildNumber,
    required this.stage,
    required this.platform,
    required this.mode,
    required this.artifactBytes,
    required this.sourceBytes,
    required this.assetBytes,
    required this.revision,
    required this.screens,
    required this.routeSources,
  });

  final String version;
  final int buildNumber;
  final String stage;
  final String platform;
  final String mode;
  final int? artifactBytes;
  final int? sourceBytes;
  final int? assetBytes;
  final RevisionMetadata revision;
  final Map<String, ScreenWeightMetadata> screens;
  final Map<String, RouteSourceWeightMetadata> routeSources;

  String get displayVersion => 'v$version+$buildNumber';

  static Future<BuildMetadata> load() async {
    final raw = await rootBundle.loadString('assets/diagnostics/build_meta.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final app = json['app'] as Map<String, dynamic>? ?? const {};
    final measurement = json['measurement'] as Map<String, dynamic>? ?? const {};
    final repository = json['repository'] as Map<String, dynamic>? ?? const {};
    final rawRevision = repository['revision'] as Map<String, dynamic>? ?? const {};
    final rawScreens = json['screens'] as Map<String, dynamic>? ?? const {};
    final rawRouteSources = json['routeSources'] as Map<String, dynamic>? ?? const {};

    return BuildMetadata(
      version: app['version'] as String? ?? 'unknown',
      buildNumber: (app['buildNumber'] as num?)?.toInt() ?? 0,
      stage: app['stage'] as String? ?? 'unknown',
      platform: measurement['platform'] as String? ?? 'unmeasured',
      mode: measurement['mode'] as String? ?? 'unknown',
      artifactBytes: (measurement['artifactBytes'] as num?)?.toInt(),
      sourceBytes: (repository['sourceBytes'] as num?)?.toInt(),
      assetBytes: (repository['assetBytes'] as num?)?.toInt(),
      revision: RevisionMetadata.fromJson(rawRevision),
      screens: {
        for (final entry in rawScreens.entries)
          entry.key: ScreenWeightMetadata.fromJson(entry.value as Map<String, dynamic>),
      },
      routeSources: {
        for (final entry in rawRouteSources.entries)
          entry.key: RouteSourceWeightMetadata.fromJson(entry.value as Map<String, dynamic>),
      },
    );
  }
}

class RevisionMetadata {
  const RevisionMetadata({
    required this.sha,
    required this.shortSha,
    required this.ref,
    required this.committedAt,
    required this.subject,
    required this.commitUrl,
    required this.dirty,
  });

  final String? sha;
  final String? shortSha;
  final String? ref;
  final String? committedAt;
  final String? subject;
  final String? commitUrl;
  final bool dirty;

  String get displaySha {
    if (shortSha != null && shortSha!.isNotEmpty) return shortSha!;
    if (sha == null || sha!.isEmpty) return 'unknown';
    return sha!.length <= 8 ? sha! : sha!.substring(0, 8);
  }

  factory RevisionMetadata.fromJson(Map<String, dynamic> json) {
    return RevisionMetadata(
      sha: json['sha'] as String?,
      shortSha: json['shortSha'] as String?,
      ref: json['ref'] as String?,
      committedAt: json['committedAt'] as String?,
      subject: json['subject'] as String?,
      commitUrl: json['commitUrl'] as String?,
      dirty: json['dirty'] as bool? ?? false,
    );
  }
}

class ScreenWeightMetadata {
  const ScreenWeightMetadata({required this.sourceBytes, required this.featureBytes});

  final int sourceBytes;
  final int featureBytes;

  factory ScreenWeightMetadata.fromJson(Map<String, dynamic> json) {
    return ScreenWeightMetadata(
      sourceBytes: (json['sourceBytes'] as num?)?.toInt() ?? 0,
      featureBytes: (json['featureBytes'] as num?)?.toInt() ?? 0,
    );
  }
}

class RouteSourceWeightMetadata {
  const RouteSourceWeightMetadata({required this.sourceBytes, required this.path});

  final int sourceBytes;
  final String path;

  factory RouteSourceWeightMetadata.fromJson(Map<String, dynamic> json) {
    return RouteSourceWeightMetadata(
      sourceBytes: (json['sourceBytes'] as num?)?.toInt() ?? 0,
      path: json['path'] as String? ?? '',
    );
  }
}

String formatDiagnosticBytes(int? bytes) {
  if (bytes == null) return 'not measured';
  const units = ['B', 'KiB', 'MiB', 'GiB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value.toStringAsFixed(unit == 0 ? 0 : 2)} ${units[unit]}';
}
