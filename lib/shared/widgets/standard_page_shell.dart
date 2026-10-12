import 'package:flutter/material.dart';
import 'standard_page_footer.dart';
import 'standard_page_header.dart';
import 'session_text_clipboard.dart';

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
            const SessionClipboardDrawerSection(),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.route_outlined),
              title: Text('Navigation'),
              subtitle: Text('Use the Door-to-Door selector below to move between tools.'),
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
