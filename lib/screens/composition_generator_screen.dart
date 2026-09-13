import 'package:flutter/material.dart';

import '../config/routes.dart';
import '../shared/display/display_scope.dart';
import '../shared/widgets/song_seed_panel.dart';
import '../widgets/nav_button.dart';

/// Legacy Song Seed screen kept for catalogue/tests; prod deep links redirect
/// to Composition Studio. This host reuses [SongSeedPanel] to avoid logic drift.
class CompositionGeneratorScreen extends StatelessWidget {
  const CompositionGeneratorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final display = DisplayScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(display.text('nav.compositionGenerator')),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              children: [
                const SongSeedPanel(initiallyExpanded: true),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    NavButton(label: display.text('home.title'), routeName: AppRoutes.home),
                    NavButton(
                      label: display.text('nav.counterPlayground'),
                      routeName: AppRoutes.counterPlayground,
                    ),
                    NavButton(
                      label: display.text('nav.ironyGenerator'),
                      routeName: AppRoutes.ironyGenerator,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
