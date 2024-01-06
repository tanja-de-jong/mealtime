import 'package:intl/intl.dart';

int weekOfYear(DateTime date) {
  int dayOfYear = int.parse(DateFormat('D').format(date));
  return ((dayOfYear - date.weekday + 10) / 7).floor();
}