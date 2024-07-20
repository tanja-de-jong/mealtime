import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

String formatDate(DateTime date) {
  final formatter = DateFormat('EEE d MMMM yyyy', 'nl_NL');
  return formatter.format(date);
}

DateTime? parseDate(dateField) {
  DateTime? date;

  if (dateField != null) {
    if (dateField is Timestamp) {
      date = dateField.toDate();
    } else if (dateField is DateTime) {
      date = dateField;
    } else if (dateField is String) {
      date = DateTime.tryParse(dateField);
    }
  }
  return date;
}
