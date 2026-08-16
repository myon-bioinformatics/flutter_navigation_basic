import 'package:flutter/material.dart';

import 'build_metadata.dart';
import 'route_diagnostics_observer.dart';

class WeightBadgeOverlay extends StatefulWidget {
  const WeightBadgeOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<WeightBadgeOverlay> createState() => _WeightBadgeOverlayState();
}

class _WeightBadgeOverlayState extends State<WeightBadgeOverlay> {
  late final Future<BuildMetadata> _metadata = BuildMetadata.load();
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          right: 10,
          bottom: 10,
          child: SafeArea(
            minimum: const EdgeInsets.all(4),
            child: FutureBuilder<BuildMetadata>(
              future: _metadata,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                return ValueListenableBuilder<String?>(
                  valueListenable: RouteDiagnosticsObserver.instance.currentRouteName,
                  builder: (context, routeName, _) {
                    return _WeightBadge(
                      metadata: snapshot.data!,
                      routeName: routeName,
                      expanded: _expanded,
                      onTap: () => setState(() => _expanded = !_expanded),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _WeightBadge extends StatelessWidget {
  const _WeightBadge({
    required this.metadata,
    required this.routeName,
    required this.expanded,
    required this.onTap,
  });

  final BuildMetadata metadata;
  final String? routeName;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final screenId = _screenIdForRoute(routeName);
    final screen = screenId == null ? null : metadata.screens[screenId];
    final compactBytes = screen?.sourceBytes ?? metadata.artifactBytes ?? metadata.sourceBytes;
    final compactLabel = screen != null
        ? 'screen ${formatDiagnosticBytes(compactBytes)}'
        : metadata.artifactBytes != null
            ? 'build ${formatDiagnosticBytes(compactBytes)}'
            : 'repo ${formatDiagnosticBytes(compactBytes)}';

    return Material(
      elevation: 3,
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: expanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '⚖ $compactLabel',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(metadata.displayVersion, style: Theme.of(context).textTheme.labelSmall),
                      Text('route ${routeName ?? 'unknown'}', style: Theme.of(context).textTheme.labelSmall),
                      if (screen != null)
                        Text('feature ${formatDiagnosticBytes(screen.featureBytes)}', style: Theme.of(context).textTheme.labelSmall),
                      Text('artifact ${formatDiagnosticBytes(metadata.artifactBytes)}', style: Theme.of(context).textTheme.labelSmall),
                      Text('assets ${formatDiagnosticBytes(metadata.assetBytes)}', style: Theme.of(context).textTheme.labelSmall),
                    ],
                  )
                : Text(
                    '⚖ $compactLabel',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
          ),
        ),
      ),
    );
  }
}

String? _screenIdForRoute(String? routeName) {
  return switch (routeName) {
    '/' => 'home',
    '/examples/counter-playground' => 'counter_playground',
    '/examples/irony-generator' => 'irony_generator',
    '/examples/composition-generator' => 'composition_generator',
    '/screen5' => 'screen5',
    _ => null,
  };
}
