import 'package:flutter/material.dart';

import '../display/display_scope.dart';
import '../navigation/page_identities.g.dart';
import 'session_text_clipboard.dart';

/// Favorites are a session-only prototype: reload starts a new collection.
class SessionPageFavorites {
  SessionPageFavorites._();
  static final routes = ValueNotifier<Set<String>>(<String>{});

  static void toggle(String route) {
    routes.value = routes.value.contains(route)
        ? (Set.of(routes.value)..remove(route))
        : {...routes.value, route};
  }
}

/// Title decoration is presentation only; automation uses semantic identifiers.
String standardPageTitle(String title, String route) {
  final emoji = pageEmojis[canonicalPageRoute(route)];
  // Unregistered private/demo pages keep their title. Public routes are checked
  // against this registry; never assign a shared fallback identity.
  if (emoji == null) return title;
  final plainTitle = title
      .replaceAll(
        RegExp(
          r'[\u{1F000}-\u{1FAFF}\u2600-\u27BF\uFE0F\u200D]',
          unicode: true,
        ),
        '',
      )
      .trim();
  return '$plainTitle $emoji';
}

/// Row one is identical on every page. Page actions occupy a scrollable row two.
class StandardPageHeader extends StatefulWidget implements PreferredSizeWidget {
  const StandardPageHeader({
    super.key,
    required this.title,
    this.currentRouteName,
    this.titleTrailing,
    this.subHeader,
    this.extraActions = const [],
    this.showLocalePicker = true,
  });

  final String title;
  final String? currentRouteName;
  final Widget? titleTrailing;
  final PreferredSizeWidget? subHeader;
  final List<Widget> extraActions;
  final bool showLocalePicker;

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight +
        (extraActions.isEmpty ? 0 : 48) +
        (subHeader?.preferredSize.height ?? 0),
  );

  @override
  State<StandardPageHeader> createState() => _StandardPageHeaderState();
}

class _StandardPageHeaderState extends State<StandardPageHeader> {
  bool _homeInFlight = false;
  String get title => widget.title;
  String? get currentRouteName => widget.currentRouteName;
  Widget? get titleTrailing => widget.titleTrailing;
  PreferredSizeWidget? get subHeader => widget.subHeader;
  List<Widget> get extraActions => widget.extraActions;
  bool get showLocalePicker => widget.showLocalePicker;
  Size get preferredSize => widget.preferredSize;

  String _route(BuildContext context) =>
      currentRouteName ?? ModalRoute.of(context)?.settings.name ?? '/';

  Future<void> _home(BuildContext context) async {
    if (_homeInFlight || canonicalPageRoute(_route(context)) == '/') return;
    setState(() => _homeInFlight = true);
    var navigated = false;
    try {
      final destination = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Return to Home?'),
          content: Text(
            'Leave $title? Unsaved changes on this screen may be lost.',
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    key: const Key('shared-header-stay'),
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Cancel · Stay here'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    key: const Key('shared-header-confirm-home'),
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('Home'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
      if (destination == true && context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
        navigated = true;
      }
    } finally {
      // Keep the guard through the outgoing route's transition after approval.
      if (mounted && !navigated) setState(() => _homeInFlight = false);
    }
  }

  void _menu(BuildContext context) {
    final display = DisplayScope.maybeOf(context);
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => Builder(
        builder: (sheetContext) {
          final content = FractionallySizedBox(
            heightFactor: 0.75,
            child: ListView(
              children: [
                if (showLocalePicker && display != null)
                  const ListTile(
                    title: Text('Language'),
                    trailing: DisplayLocalePicker(compact: true),
                  ),
                const ListTile(
                  leading: Icon(Icons.star_outline),
                  title: Text('Favorites'),
                  subtitle: Text(
                    'The star remembers this page until the app reloads.',
                  ),
                ),
                const SessionClipboardDrawerSection(),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.route_outlined),
                  title: Text('Navigation'),
                  subtitle: Text(
                    'Use the Door-to-Door selector below to move between tools.',
                  ),
                ),
              ],
            ),
          );
          return display == null
              ? content
              : DisplayScope(controller: display, child: content);
        },
      ),
    );
  }

  Widget _identified(String id, Widget child) =>
      Semantics(identifier: id, container: true, child: child);

  @override
  Widget build(BuildContext context) {
    final route = _route(context);
    return AppBar(
      titleSpacing: 8,
      leadingWidth: 40,
      title: Semantics(
        identifier: 'shared-header-title',
        header: true,
        child: Row(
          children: [
            Flexible(
              child: Text(
                standardPageTitle(title, route),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (titleTrailing != null) titleTrailing!,
          ],
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      leading: Navigator.of(context).canPop()
          ? const BackButton(key: Key('shared-header-back'))
          : null,
      automaticallyImplyLeading: false,
      actions: [
        _identified(
          'shared-header-home',
          IconButton(
            key: const Key('shared-header-home'),
            tooltip: 'Home',
            icon: const Icon(Icons.home_outlined),
            onPressed: _homeInFlight ? null : () => _home(context),
          ),
        ),
        ValueListenableBuilder<Set<String>>(
          valueListenable: SessionPageFavorites.routes,
          builder: (context, favorites, _) => _identified(
            'shared-header-favorite',
            IconButton(
              key: const Key('shared-header-favorite'),
              tooltip: favorites.contains(route)
                  ? 'Remove favorite'
                  : 'Favorite this page',
              isSelected: favorites.contains(route),
              icon: const Icon(Icons.star_outline),
              selectedIcon: const Icon(Icons.star),
              onPressed: () => SessionPageFavorites.toggle(route),
            ),
          ),
        ),
        _identified(
          'shared-header-menu',
          IconButton(
            key: const Key('shared-header-menu'),
            tooltip: 'Menu',
            icon: const Icon(Icons.menu),
            onPressed: () => _menu(context),
          ),
        ),
      ],
      bottom: extraActions.isEmpty && subHeader == null
          ? null
          : PreferredSize(
              preferredSize: Size.fromHeight(
                preferredSize.height - kToolbarHeight,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (extraActions.isNotEmpty)
                    Semantics(
                      identifier: 'shared-header-secondary',
                      container: true,
                      child: SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          reverse: true,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: extraActions,
                          ),
                        ),
                      ),
                    ),
                  if (subHeader != null) subHeader!,
                ],
              ),
            ),
    );
  }
}
