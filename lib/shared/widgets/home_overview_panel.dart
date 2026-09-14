import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../diagnostics/build_metadata.dart';
import '../display/display_scope.dart';

class HomeOverviewAction {
  const HomeOverviewAction({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
}

class HomeOverviewPanel extends StatelessWidget {
  const HomeOverviewPanel({
    super.key,
    required this.actions,
    this.title = 'Flutter Navigation Basic',
    this.subtitle = 'Explore navigation, API, UI/theme, and data-processing patterns from one dashboard.',
    this.metadataLoader = BuildMetadata.load,
  });

  final List<HomeOverviewAction> actions;
  final String title;
  final String subtitle;

  /// Overridable for tests so revision-metric loading can be driven
  /// deterministically instead of depending on real asset I/O timing.
  final Future<BuildMetadata> Function() metadataLoader;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final display = DisplayScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                scheme.primaryContainer,
                scheme.secondaryContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _Metric(label: display.text('homeOverview.metricReferencePatterns'), value: '792'),
                  _Metric(label: display.text('homeOverview.metricPerCategory'), value: '198'),
                  _Metric(label: display.text('homeOverview.metricRuntimeDeps'), value: '2'),
                  _Metric(
                    label: display.text('homeOverview.metricStage'),
                    value: display.text('homeOverview.metricStageValue'),
                  ),
                  _BuildMetrics(loader: metadataLoader),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width >= 1000 ? 4 : width >= 620 ? 2 : 1;
            final cardWidth = columns == 1
                ? width
                : (width - ((columns - 1) * 12)) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final action in actions)
                  SizedBox(width: cardWidth, child: _HoverActionCard(action: action)),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Text('$value · $label'),
      ),
    );
  }
}

class _BuildMetrics extends StatefulWidget {
  const _BuildMetrics({required this.loader});

  final Future<BuildMetadata> Function() loader;

  @override
  State<_BuildMetrics> createState() => _BuildMetricsState();
}

class _BuildMetricsState extends State<_BuildMetrics> {
  // One Future for Version + Commit so the asset is read/parsed once per
  // panel lifetime. Parent rebuilds (Home refresh) reuse the same Future.
  late final Future<BuildMetadata> _metadata;

  @override
  void initState() {
    super.initState();
    _metadata = widget.loader();
  }

  @override
  Widget build(BuildContext context) {
    final display = DisplayScope.of(context);
    return FutureBuilder<BuildMetadata>(
      future: _metadata,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Metric(
                label: display.text('homeOverview.version'),
                value: display.text('homeOverview.loading'),
              ),
              _Metric(
                label: display.text('homeOverview.commit'),
                value: display.text('homeOverview.loading'),
              ),
            ],
          );
        }

        final metadata = snapshot.data!;
        final revision = metadata.revision;
        final details = <String>[
          if (revision.sha != null)
            display.text('homeOverview.shaLabel', arguments: {'sha': revision.sha}),
          if (revision.ref != null)
            display.text('homeOverview.refLabel', arguments: {'ref': revision.ref}),
          if (revision.committedAt != null)
            display.text(
              'homeOverview.committedLabel',
              arguments: {'date': revision.committedAt},
            ),
          if (revision.subject != null) revision.subject!,
          if (revision.commitUrl != null) revision.commitUrl!,
          if (revision.dirty) display.text('homeOverview.dirtyWorkingTree'),
        ].join('\n');
        final commitUrl = revision.commitUrl;
        final versionMetric = _Metric(
          label: display.text('homeOverview.version'),
          value: display.text(
            'homeOverview.versionWithBuild',
            arguments: {
              'version': metadata.displayVersion,
              'build': '${metadata.buildNumber}',
            },
          ),
        );
        final commitMetric = _Metric(
          label: revision.ref == null || revision.ref!.isEmpty
              ? display.text('homeOverview.commit')
              : display.text(
                  'homeOverview.commitWithRef',
                  arguments: {'ref': revision.ref},
                ),
          value: revision.displaySha,
        );

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            versionMetric,
            Tooltip(
              message: details.isEmpty
                  ? display.text('homeOverview.gitRevisionUnavailable')
                  : commitUrl == null
                      ? details
                      : '$details\n${display.text('homeOverview.tapToCopyCommitUrl')}',
              child: commitUrl == null
                  ? commitMetric
                  : InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: commitUrl));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              display.text('homeOverview.commitUrlCopied'),
                            ),
                          ),
                        );
                      },
                      child: commitMetric,
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _HoverActionCard extends StatefulWidget {
  const _HoverActionCard({required this.action});

  final HomeOverviewAction action;

  @override
  State<_HoverActionCard> createState() => _HoverActionCardState();
}

class _HoverActionCardState extends State<_HoverActionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 160),
        transform: Matrix4.translationValues(0, _hovered && !reduceMotion ? -3 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          boxShadow: _hovered && !reduceMotion
              ? [
                  BoxShadow(
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                    color: Theme.of(context).shadowColor.withValues(alpha: 0.12),
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: widget.action.onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(widget.action.icon),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.action.label, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(widget.action.subtitle, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
