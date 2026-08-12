import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/screen2.dart';
import '../screens/screen3.dart';
import '../screens/screen4.dart';

class AppRoutes {
  static const String home = '/';
  static const String screen2 = '/screen2';
  static const String screen3 = '/screen3';
  static const String screen4 = '/screen4';

  static Map<String, WidgetBuilder> get routes => {
        home: (_) => const HomeScreen(),
        screen2: (_) => const Screen2(),
        screen3: (_) => const Screen3(),
        screen4: (_) => const Screen4(),
      };
}
