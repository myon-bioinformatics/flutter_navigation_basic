class HomeController {
  String today(List<String> weekdayLabels) {
    final value = DateTime.now();
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final weekday = weekdayLabels[value.weekday - 1];
    return '${value.year}/$month/$day($weekday)';
  }
}
