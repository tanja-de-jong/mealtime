import 'package:intl/intl.dart';

int weekOfYear(DateTime date) {
  int dayOfYear = int.parse(DateFormat('D').format(date));
  return ((dayOfYear - date.weekday + 10) / 7).floor();
}

List<String> getDaysInWeek(DateTime date) {
  // Get the day of the week (1=Monday, 7=Sunday)
  int dayOfWeek = date.weekday;

  // Find the start of the week
  DateTime startOfWeek = date.subtract(Duration(days: dayOfWeek - 1));

  // Generate a list of the days in this week
  List<String> daysInWeek = List.generate(7, (index) {
    DateTime day = startOfWeek.add(Duration(days: index));
    return DateFormat('yyyy-MM-dd').format(day);
  });

  return daysInWeek;
}

List<String> getDaysInRangeFromUpcomingWeekday(int weekday, int duration) {
  DateTime now = DateTime.now();
  DateTime startDate = now.add(Duration(days: (weekday - now.weekday) % 7));
  DateTime endDate = startDate.add(Duration(days: duration - 1));
  return getDaysInRange(startDate, endDate);
}

List<String> getDaysInRange(DateTime startDate, DateTime endDate) {
  List<String> dates = [];

  for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
    dates
        .add(DateFormat('yyyy-MM-dd').format(startDate.add(Duration(days: i))));
  }

  return dates;
}

String capitalize(String str) {
  if (str.isEmpty) {
    return str;
  }
  return str[0].toUpperCase() + str.substring(1);
}
