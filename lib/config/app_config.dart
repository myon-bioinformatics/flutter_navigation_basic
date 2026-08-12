import 'package:flutter/material.dart';

class AppConfig {
  // アプリ名
  static const String appName = 'Navigation Basics';

  // シードカラー
  static const Color seedColor = Colors.deepPurple;

  // テーマ定義
  static ThemeData get theme => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        useMaterial3: true,
      );
}
