import 'package:flutter/material.dart';

import 'build_metadata.dart';

class BuildDiagnosticsCard extends StatelessWidget {
  const BuildDiagnosticsCard({super.key, this.screenId});

  final String? screenId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BuildMetadata>(
      future: BuildMetadata.load(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final metadata = snapshot.data!;
        final screen = screenId == null ? null : metadata.screens[screenId];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Build diagnostics', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    Text('${metadata.displayVersion} · ${metadata.stage}'),
                    Text('${metadata.platform} · ${metadata.mode}'),
                    Text('artifact ${formatDiagnosticBytes(metadata.artifactBytes)}'),
                    Text('repo ${formatDiagnosticBytes(metadata.sourceBytes)}'),
                    Text('assets ${formatDiagnosticBytes(metadata.assetBytes)}'),
                    if (screen != null)
                      Text('screen ${formatDiagnosticBytes(screen.sourceBytes)}'),
                    if (screen != null)
                      Text('feature ${formatDiagnosticBytes(screen.featureBytes)}'),
                  ],
                ),
                if (metadata.artifactBytes == null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Release artifact size has not been measured in this metadata snapshot.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
