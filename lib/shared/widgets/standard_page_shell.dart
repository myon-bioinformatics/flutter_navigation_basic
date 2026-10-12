import 'package:flutter/material.dart';
import 'standard_page_footer.dart';
import 'standard_page_header.dart';

/// Shared chrome around a self-contained feature body.
/// New callers provide a title; legacy AppBars remain accepted during migration.
class StandardPageShell extends StatelessWidget {
  const StandardPageShell({
    super.key,
    this.appBar,
    this.title,
    this.subHeader,
    this.headerActions = const [],
    required this.currentRouteName,
    required this.child,
    this.floatingActionButton,
  }) : assert(appBar != null || title != null);

  final PreferredSizeWidget? appBar;
  final String? title;
  final PreferredSizeWidget? subHeader;
  final List<Widget> headerActions;
  final String currentRouteName;
  final Widget child;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: appBar ?? StandardPageHeader(
          title: title!,
          subHeader: subHeader,
          extraActions: headerActions,
        ),
        endDrawer: title == null ? null : Drawer(
          child: SafeArea(child: ListView(children: [
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
          ])),
        ),
        body: child,
        bottomNavigationBar: StandardPageFooter(
          currentRouteName: currentRouteName,
        ),
        floatingActionButton: floatingActionButton,
      );
}
