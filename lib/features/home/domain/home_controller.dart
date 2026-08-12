import 'package:intl/intl.dart';
import '../../../core/services/base_controller.dart';

class HomeController extends BaseController {
  String get today => DateFormat('yyyy/MM/dd(E)').format(DateTime.now());
}
