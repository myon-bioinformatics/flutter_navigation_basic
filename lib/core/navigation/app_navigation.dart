import 'package:get/get.dart';
import 'route_names.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/domain/home_controller.dart';
import '../../features/screen2/presentation/screen2_page.dart';
import '../../features/screen2/domain/screen2_controller.dart';
import '../../features/screen3/presentation/screen3_page.dart';
import '../../features/screen3/domain/screen3_controller.dart';
import '../../features/screen4/presentation/screen4_page.dart';
import '../../features/screen4/domain/screen4_controller.dart';

class AppNavigation {
  AppNavigation._();

  static void toHome() => Get.offAllNamed(RouteNames.home);
  static void toScreen2() => Get.toNamed(RouteNames.screen2);
  static void toScreen3() => Get.toNamed(RouteNames.screen3);
  static void toScreen4() => Get.toNamed(RouteNames.screen4);
  static void back() => Get.back();
}

List<GetPage<dynamic>> get appRoutes => [
      GetPage(
        name: RouteNames.home,
        page: () => const HomeScreen(),
        binding: BindingsBuilder(() => Get.lazyPut(() => HomeController())),
      ),
      GetPage(
        name: RouteNames.screen2,
        page: () => const Screen2Page(),
        binding: BindingsBuilder(() => Get.lazyPut(() => Screen2Controller())),
      ),
      GetPage(
        name: RouteNames.screen3,
        page: () => const Screen3Page(),
        binding: BindingsBuilder(() => Get.lazyPut(() => Screen3Controller())),
      ),
      GetPage(
        name: RouteNames.screen4,
        page: () => const Screen4Page(),
        binding: BindingsBuilder(() => Get.lazyPut(() => Screen4Controller())),
      ),
    ];
