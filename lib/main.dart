import 'package:flutter/material.dart';
import 'config/app_config.dart';
import 'config/routes.dart';
import 'shared/diagnostics/route_diagnostics_observer.dart';
import 'shared/diagnostics/weight_badge_overlay.dart';
import 'shared/display/display_scope.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _DisplayBootstrap(child: App()));
}

class _DisplayBootstrap extends StatefulWidget {
  const _DisplayBootstrap({required this.child});

  final Widget child;

  @override
  State<_DisplayBootstrap> createState() => _DisplayBootstrapState();
}

class _DisplayBootstrapState extends State<_DisplayBootstrap> {
  late final Future<DisplayController> _controller = DisplayController.load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DisplayController>(
      future: _controller,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        return DisplayScope(controller: snapshot.data!, child: widget.child);
      },
    );
  }
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      theme: AppConfig.theme,
      routes: AppRoutes.routes,
      initialRoute: AppRoutes.home,
      navigatorObservers: [RouteDiagnosticsObserver.instance],
      builder: (context, child) => Column(
        children: [
          Expanded(child: child ?? const SizedBox.shrink()),
          const WeightDiagnosticsStrip(),
        ],
      ),
    );
  }
}
