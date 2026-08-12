import 'package:flutter/material.dart';
import '../themes/color_constants.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key, required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: ColorConstants.primary,
      foregroundColor: Colors.white,
      elevation: 2,
    );
  }
}
