import 'package:flutter/material.dart';
import '../display/display_scope.dart';

/// Minimal common header: Home, title, locale switch and a navigation drawer.
/// Feature-specific controls belong in [subHeader] or [extraActions].
class StandardPageHeader extends StatelessWidget implements PreferredSizeWidget {
  const StandardPageHeader({
    super.key,
    required this.title,
    this.subHeader,
    this.extraActions = const [],
  });

  final String title;
  final PreferredSizeWidget? subHeader;
  final List<Widget> extraActions;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (subHeader?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) => AppBar(
        title: Semantics(
          identifier: 'shared-header-title',
          header: true,
          child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: Navigator.of(context).canPop()
            ? const BackButton(key: Key('shared-header-back'))
            : null,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
          key: const Key('shared-header-home'),
          tooltip: 'Home',
          icon: const Icon(Icons.home_outlined),
          onPressed: () async {
            final destination = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Return to Home?'),
                content: Text(
                  'Leave $title? Unsaved changes on this screen may be lost.',
                ),
                actions: [
                  Row(children: [
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
                  ]),
                ],
              ),
            );
            if (destination != true || !context.mounted) return;
            Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
          },
        ),
          ...extraActions,
          if (DisplayScope.maybeOf(context) != null &&
              MediaQuery.sizeOf(context).width >= 600)
            const DisplayLocalePicker(compact: true),
          Builder(builder: (menuContext) => IconButton(
                key: const Key('shared-header-menu'),
                tooltip: 'Menu',
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(menuContext).openEndDrawer(),
              )),
        ],
        bottom: subHeader,
      );
}
