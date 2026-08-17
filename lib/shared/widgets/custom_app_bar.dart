import 'package:flutter/material.dart';
import '../display/display_scope.dart';
import '../themes/color_constants.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.showLocalePicker = true,
  });

  final String title;
  final List<Widget> actions;
  final bool showLocalePicker;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        ...actions,
        if (showLocalePicker && DisplayScope.maybeOf(context) != null)
          const DisplayLocalePicker(compact: true),
      ],
      backgroundColor: ColorConstants.primary,
      foregroundColor: Colors.white,
      elevation: 2,
    );
  }
}
