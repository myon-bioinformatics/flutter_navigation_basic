import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../diagnostics/build_metadata.dart';

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
                  const _Metric(label: 'Reference patterns', value: '792'),
                  const _Metric(label: 'Per category', value: '198'),
                  const _Metric(label: 'Runtime deps', value: '2'),
                  const _Metric(label: 'Stage', value: 'pre-beta'),
                  _RevisionMetric(loader: metadataLoader),
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

class _RevisionMetric extends StatefulWidget {
  const _RevisionMetric({required this.loader});

  final Future<BuildMetadata> Function() loader;

  @override
  State<_RevisionMetric> createState() => _RevisionMetricState();
}

class _RevisionMetricState extends State<_RevisionMetric> {
  // Loaded once per widget lifetime so parent rebuilds (e.g. the Home
  // screen's Refresh action calling setState) reuse the same Future
  // instead of re-reading the asset and flashing back to "loading…".
  late final Future<BuildMetadata> _metadata;

  @override
  void initState() {
    super.initState();
    _metadata = widget.loader();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BuildMetadata>(
      future: _metadata,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const _Metric(label: 'Revision', value: 'loading…');
        }
        final revision = snapshot.data!.revision;
        final details = <String>[
          if (revision.sha != null) 'SHA: ${revision.sha}',
          if (revision.ref != null) 'Ref: ${revision.ref}',
          if (revision.committedAt != null) 'Committed: ${revision.committedAt}',
          if (revision.subject != null) revision.subject!,
          if (revision.commitUrl != null) revision.commitUrl!,
          if (revision.dirty) 'Local working tree was dirty',
        ].join('\n');
        final commitUrl = revision.commitUrl;
        final metric = _Metric(
          label: revision.ref == null || revision.ref!.isEmpty
              ? 'Revision'
              : 'Revision · ${revision.ref}',
          value: revision.displaySha,
        );
        return Tooltip(
          message: details.isEmpty
              ? 'Git revision unavailable'
              : commitUrl == null
                  ? details
                  : '$details\n(tap to copy commit URL)',
          child: commitUrl == null
              ? metric
              : InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: commitUrl));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Commit URL copied')),
                    );
                  },
                  child: metric,
                ),
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
