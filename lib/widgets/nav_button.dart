import 'package:flutter/material.dart';
import '../config/routes.dart';

/// 画面遷移用の共通ボタン。
/// [label] に表示テキスト、[routeName] に遷移先ルートを指定する。
/// [clearStack] が true の場合、または [routeName] が Home ルートの場合、
/// ナビゲーションスタックをクリアして遷移する。
class NavButton extends StatelessWidget {
  const NavButton({
    super.key,
    required this.label,
    required this.routeName,
    this.clearStack = false,
  });

  final String label;
  final String routeName;
  final bool clearStack;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        if (clearStack || routeName == AppRoutes.home) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            routeName,
            (route) => false,
          );
        } else {
          Navigator.pushNamed(context, routeName);
        }
      },
      child: Text(label),
    );
  }
}
