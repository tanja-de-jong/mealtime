import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mealtime/food/helpers/constants.dart';

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

bool isCountableMeal(days, startMeal, MealType meal, day) {
  bool isCountableLunch = (day != days.first || startMeal == MealType.lunch) &&
      startMeal == MealType.lunch;
  bool isCountableDinner = (day != days.last || startMeal == MealType.lunch) &&
      startMeal == MealType.dinner;
  return isCountableLunch || isCountableDinner;
}

/*
   * This function counts the presence at a specific meal (lunch or dinner) for a given presence status.
   * It iterates over the daysInRange list and increments the count if the selected meal for the day equals the presence status.
   * The function returns the count.
   */
Future<int> countPresenceAtMeal(days, startMeal, meal, presence) async {
  int count = 0;
  for (String day in days) {
    // Get the presence for a certain meal on a given day from the database
    var date =
        await FirebaseFirestore.instance.collection('days').doc(day).get();
    // if (isCountableMeal(days, startMeal, meal, day) && // TO DO: implemenet this
    //     date.data()[] == presence) {
    //   count++;
    // }
  }
  return count;
}

/*
   * This function counts the presence at both meals for every presence status.
   * It iterates over the _presence list and calls the countPresenceAtMeal function for every presence status.
   * The function returns a Column containing a Text widget for every presence status and a Text widget with the total count.
   */
countPresenceAtMeals() {
  int totalLunchCount = 0;
  int totalDinnerCount = 0;
  List<Text> presenceCount = [];
  for (int i = 0; i < Presence.values.length; i++) {
    // Presence presence = Presence.values[i];
    // int factor = presence.count;
    // int lunchCount = countPresenceAtMeal(MealType.lunch, presence);
    // totalLunchCount += lunchCount * factor;
    // int dinnerCount = countPresenceAtMeal(MealType.dinner, presence);
    // totalDinnerCount += dinnerCount * factor;
    // presenceCount
    //     .add(Text('$presence: $lunchCount lunch, $dinnerCount dinner'));
  }
  presenceCount
      .add(Text("Totaal: $totalLunchCount lunch, $totalDinnerCount dinner"));
  return Column(children: presenceCount);
}
