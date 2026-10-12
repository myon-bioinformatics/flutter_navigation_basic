import 'package:flutter/material.dart';

import 'standard_page_header.dart';

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
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (actions.isEmpty ? 0 : 48));

  @override
  Widget build(BuildContext context) {
    return StandardPageHeader(
      title: title,
      extraActions: actions,
      showLocalePicker: showLocalePicker,
    );
  }
}
