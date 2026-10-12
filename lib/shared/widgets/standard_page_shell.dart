import 'package:flutter/material.dart';
import 'standard_page_footer.dart';

/// Shared page chrome. Feature widgets own only their page-specific content.
/// Existing custom AppBars can be passed unchanged until migrated.
class StandardPageShell extends StatelessWidget {
  const StandardPageShell({
    super.key,
    required this.appBar,
    required this.currentRouteName,
    required this.child,
    this.floatingActionButton,
  });

  final PreferredSizeWidget appBar;
  final String currentRouteName;
  final Widget child;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: appBar,
        body: child,
        bottomNavigationBar: StandardPageFooter(
          currentRouteName: currentRouteName,
        ),
        floatingActionButton: floatingActionButton,
      );
}
