import 'package:intl/intl.dart';

String formatDate(DateTime date) {
  final formatter = DateFormat('EEE d MMMM yyyy', 'nl_NL');
  return formatter.format(date);
}
