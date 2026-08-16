class HomeController {
  String get today {
    const weekdays = <String>['月', '火', '水', '木', '金', '土', '日'];
    final value = DateTime.now();
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final weekday = weekdays[value.weekday - 1];
    return '${value.year}/$month/$day($weekday)';
  }
}
