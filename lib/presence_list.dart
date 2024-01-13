import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mealtime/constants.dart';
import 'package:mealtime/nav_scaffold.dart';
import 'package:mealtime/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PresenceList extends StatefulWidget {
  const PresenceList({super.key});

  @override
  PresenceListState createState() => PresenceListState();
}

class PresenceListState extends State<PresenceList> {
  bool loading = true;
  WeekDay startDay = WeekDay.monday;
  MealType startMeal = MealType.dinner;
  int duration = 8;
  late List<String> daysInRange;
  final Map<MealType, Map<String, Presence>> selectedMeals = {
    MealType.lunch: {},
    MealType.dinner: {},
  };
  bool dataExists = false;

  bool isCountableMeal(MealType meal, day) {
    bool isCountableLunch =
        (day != daysInRange.first || startMeal == MealType.lunch) &&
            startMeal == MealType.lunch;
    bool isCountableDinner =
        (day != daysInRange.last || startMeal == MealType.lunch) &&
            startMeal == MealType.dinner;
    return isCountableLunch || isCountableDinner;
  }

  /*
   * This function counts the presence at a specific meal (lunch or dinner) for a given presence status.
   * It iterates over the daysInRange list and increments the count if the selected meal for the day equals the presence status.
   * The function returns the count.
   */
  int countPresenceAtMeal(meal, presence) {
    int count = 0;
    for (String day in daysInRange) {
      if (isCountableMeal(meal, day) && selectedMeals[meal]![day] == presence) {
        count++;
      }
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
      Presence presence = Presence.values[i];
      int factor = presence.count;
      int lunchCount = countPresenceAtMeal(MealType.lunch, i);
      totalLunchCount += lunchCount * factor;
      int dinnerCount = countPresenceAtMeal(MealType.dinner, i);
      totalDinnerCount += dinnerCount * factor;
      presenceCount
          .add(Text('$presence: $lunchCount lunch, $dinnerCount dinner'));
    }
    presenceCount
        .add(Text("Totaal: $totalLunchCount lunch, $totalDinnerCount dinner"));
    return Column(children: presenceCount);
  }

  /*
   * This function sets the default presence for every day in the daysInRange list.
   * It iterates over the daysInRange list and sets the default presence for every day.
   */
  setDefaultPresence() {
    selectedMeals[MealType.lunch] = {};
    selectedMeals[MealType.dinner] = {};
    setState(() {
      // For every daysInWeek, set the default presence
      for (String date in daysInRange) {
        int dayOfWeek = DateTime.parse(date).weekday;
        if (dayOfWeek == 1 || dayOfWeek == 3 || dayOfWeek == 4) {
          selectedMeals[MealType.lunch]![date] = Presence.tanja;
        } else if (dayOfWeek == 2 || dayOfWeek == 5) {
          selectedMeals[MealType.lunch]![date] = Presence.mattanja;
        } else {
          selectedMeals[MealType.lunch]![date] = Presence.all;
        }
        selectedMeals[MealType.dinner]![date] = Presence.all;
      }
    });
  }

  /*
   * This function gets the presence data for every day in the daysInRange list.
   * It iterates over the daysInRange list and gets the presence data for every day.
   * If the document exists, it sets the presence for that day.
   * If the document doesn't exist, it sets the presence to the default.
   */
  Future<void> loadPresenceData() async {
    setState(() {
      loading = true;
    });
    setDefaultPresence();
    // Get the firestore document for every day in range
    // If the document exists, set the presence for that day
    // If the document doesn't exist, set the presence to the default
    for (String date in daysInRange) {
      DocumentSnapshot<Map<String, dynamic>> document =
          await FirebaseFirestore.instance.collection('days').doc(date).get();

      if (document.exists) {
        dataExists = true;
        Map<String, dynamic> presenceData =
            document.data() as Map<String, dynamic>;
        setState(() {
          for (MealType type in MealType.values) {
            int? presenceIndex = presenceData[type.name]?['presence'];
            if (presenceIndex != null) {
              if (selectedMeals[type] == null) {
                selectedMeals[type] = {};
              }
              selectedMeals[type]![date] = Presence.values[presenceIndex];
            }
          }
        });
      } else {
        dataExists = false;
        setDefaultPresence();
      }
    }
    setState(() {
      loading = false;
    });
  }

  String getWeekLabel() {
    // DateTime now = DateTime.now();
    // int week = weekOfYear(date);
    // int year = date.year;
    // return now.year == year ? 'Week $week' : 'Week $year-$week';
    return "To do";
  }

  /*
   * This function saves the presence data for every day in the daysInRange list.
   * It iterates over the daysInRange list and saves the presence data for every day.
   */
  Future<void> savePresenceData() async {
    for (String date in daysInRange) {
      await FirebaseFirestore.instance.collection('days').doc(date).set({
        'lunch': {'presence': selectedMeals[MealType.lunch]![date]!.index},
        'dinner': {'presence': selectedMeals[MealType.dinner]![date]!.index},
      }, SetOptions(merge: true));
    }
  }

  @override
  void initState() {
    super.initState();
    daysInRange = getDaysInRangeFromUpcomingWeekday(startDay.number, duration);
    loadPresenceData();
  }

  @override
  Widget build(BuildContext context) {
    return NavScaffold(
      appBar: AppBar(
        title: const Text('Aanwezigheid'),
        actions: <Widget>[
          ElevatedButton(
            onPressed: savePresenceData,
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  if (dataExists) return Colors.green;
                  return Colors.transparent; // Use the component's default.
                },
              ),
            ),
            child: const Text("Opslaan"),
          ),
        ],
      ),
      body: Center(
          child: loading
              ? const CircularProgressIndicator()
              : Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            daysInRange = getDaysInRange(
                                DateTime.parse(daysInRange.first)
                                    .add(const Duration(days: -7)),
                                DateTime.parse(daysInRange.last)
                                    .add(const Duration(days: -7)));
                          });
                          loadPresenceData();
                        },
                        child: const Text('Vorige periode'),
                      ),
                      const SizedBox(width: 20),
                      Text(getWeekLabel()),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            daysInRange = getDaysInRange(
                                DateTime.parse(daysInRange.first)
                                    .add(const Duration(days: 7)),
                                DateTime.parse(daysInRange.last)
                                    .add(const Duration(days: 7)));
                          });
                          loadPresenceData();
                        },
                        child: const Text('Volgende periode'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  countPresenceAtMeals(),
                  const SizedBox(height: 20),
                  Expanded(
                      child: ListView.builder(
                    itemCount: daysInRange.length,
                    itemBuilder: (context, index) {
                      String day = daysInRange[index];
                      String dayLabel = DateFormat('EEE d MMMM', 'nl_NL')
                          .format(DateTime.parse(day));
                      return Card(
                        child: ListTile(
                          title: Text(dayLabel[0].toUpperCase() +
                              dayLabel.substring(1)),
                          subtitle: Column(
                            children: [
                              if (day != daysInRange.first ||
                                  startMeal == MealType.lunch)
                                Row(children: [
                                  const SizedBox(
                                      width: 100, child: Text('Lunch')),
                                  const SizedBox(width: 10),
                                  SizedBox(
                                      width: 200,
                                      child: DropdownButtonFormField<Presence>(
                                        value: selectedMeals[MealType.lunch]![
                                            day]!,
                                        decoration: InputDecoration(
                                          // Add Horizontal padding using menuItemStyleData.padding so it matches
                                          // the menu padding when button's width is not specified.
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  vertical: 12, horizontal: 12),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                          ),
                                          // Add more decoration..
                                        ),
                                        items: Presence.values
                                            .map<DropdownMenuItem<Presence>>(
                                                (Presence presence) {
                                          return DropdownMenuItem<Presence>(
                                            value: presence,
                                            child: Text(presence.value),
                                          );
                                        }).toList(),
                                        onChanged: (Presence? newValue) {
                                          print("Changed $newValue");
                                          setState(() {
                                            selectedMeals[MealType.lunch]![
                                                day] = newValue!;
                                          });
                                        },
                                      ))
                                ]),
                              const SizedBox(height: 10),
                              if (day != daysInRange.last ||
                                  startMeal == MealType.lunch)
                                Row(children: [
                                  const SizedBox(
                                      width: 100, child: Text('Diner')),
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    width: 200,
                                    child: DropdownButtonFormField<Presence>(
                                      value:
                                          selectedMeals[MealType.dinner]![day]!,
                                      decoration: InputDecoration(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 12, horizontal: 12),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                      ),
                                      items: Presence.values
                                          .map<DropdownMenuItem<Presence>>(
                                              (Presence presence) {
                                        return DropdownMenuItem<Presence>(
                                          value: presence,
                                          child: Text(presence.value),
                                        );
                                      }).toList(),
                                      onChanged: (Presence? newValue) {
                                        setState(() {
                                          selectedMeals[MealType.dinner]![day] =
                                              newValue!;
                                        });
                                      },
                                    ),
                                  ),
                                ]),
                            ],
                          ),
                        ),
                      );
                    },
                  ))
                ])),
      selectedIndex: 1,
    );
  }
}
