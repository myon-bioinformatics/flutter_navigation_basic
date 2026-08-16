import 'package:flutter/material.dart';

class RouteDiagnosticsObserver extends NavigatorObserver {
  RouteDiagnosticsObserver._();

  static final RouteDiagnosticsObserver instance = RouteDiagnosticsObserver._();

  final ValueNotifier<String?> currentRouteName = ValueNotifier<String?>('/');

  void _publish(Route<dynamic>? route) {
    currentRouteName.value = route?.settings.name ?? currentRouteName.value;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _publish(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _publish(previousRoute);
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _publish(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
