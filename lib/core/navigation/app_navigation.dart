import 'package:get/get.dart';
import 'route_names.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/domain/home_controller.dart';
import '../../features/counter_playground/presentation/counter_playground_page.dart';
import '../../features/counter_playground/domain/counter_playground_controller.dart';
import '../../features/irony_generator/presentation/irony_generator_page.dart';
import '../../features/irony_generator/domain/irony_generator_controller.dart';
import '../../features/composition_generator/presentation/composition_generator_page.dart';
import '../../features/composition_generator/domain/composition_generator_controller.dart';
import '../../features/screen5/presentation/screen5_page.dart';
import '../../features/screen5/domain/screen5_controller.dart';

class AppNavigation {
  AppNavigation._();

  static void toHome() => Get.offAllNamed(RouteNames.home);
  static void toCounterPlayground() =>
      Get.toNamed(RouteNames.counterPlayground);
  static void toIronyGenerator() => Get.toNamed(RouteNames.ironyGenerator);
  static void toCompositionGenerator() =>
      Get.toNamed(RouteNames.compositionGenerator);
  static void toScreen5() => Get.toNamed(RouteNames.screen5);
  static void back() => Get.back();
}

List<GetPage<dynamic>> get appRoutes => [
      GetPage(
        name: RouteNames.home,
        page: () => const HomeScreen(),
        binding: BindingsBuilder(() => Get.lazyPut(() => HomeController())),
      ),
      GetPage(
        name: RouteNames.counterPlayground,
        page: () => const CounterPlaygroundPage(),
        binding: BindingsBuilder(
          () => Get.lazyPut(() => CounterPlaygroundController()),
        ),
      ),
      GetPage(
        name: RouteNames.ironyGenerator,
        page: () => const IronyGeneratorPage(),
        binding: BindingsBuilder(
          () => Get.lazyPut(() => IronyGeneratorController()),
        ),
      ),
      GetPage(
        name: RouteNames.compositionGenerator,
        page: () => const CompositionGeneratorPage(),
        binding: BindingsBuilder(
          () => Get.lazyPut(() => CompositionGeneratorController()),
        ),
      ),
      GetPage(
        name: RouteNames.screen5,
        page: () => const Screen5Page(),
        binding: BindingsBuilder(() => Get.lazyPut(() => Screen5Controller())),
      ),
    ];
