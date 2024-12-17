import 'package:clipboard/clipboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mealtime/food/helpers/constants.dart';
import 'package:mealtime/food/helpers/database.dart';
import 'package:mealtime/food/helpers/utils.dart';
import 'package:mealtime/food/types/pantry_item.dart';

class PresencePage extends StatefulWidget {
  const PresencePage({super.key});

  @override
  PresencePageState createState() => PresencePageState();
}

class PresencePageState extends State<PresencePage> {
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
  List<PantryItem> pantryItems = [];
  List<PantryItem> defaultPantryItems = [];

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
    PantryItemMap pantryItemMap = await DatabaseService.getPantryItems();
    for (var item in pantryItemMap.pantryItems) {
      if (item.getAvailableQuantity().entries.any((entry) => entry.value > 0)) {
        pantryItems.add(item);
      } else if (!(item
          .getAvailableQuantity()
          .entries
          .any((entry) => entry.value <= 0))) {
        defaultPantryItems.add(item);
      }
    }

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

  String presenceListToString() {
    Map<String, int> counts = {
      'lunch voor 1 persoon': 0,
      'lunch voor 2 personen': 0,
      'diner voor 1 persoon': 0,
      'diner voor 2 personen': 0,
    };

    selectedMeals.forEach((mealType, presenceMap) {
      presenceMap.forEach((date, presence) {
        if ((mealType == MealType.lunch && date == daysInRange.first) ||
            (mealType == MealType.dinner && date == daysInRange.last)) {
          return;
        }

        String key;
        if (mealType == MealType.lunch) {
          key = 'lunch voor ';
        } else {
          key = 'diner voor ';
        }
        if (presence == Presence.tanja || presence == Presence.mattanja) {
          key += '1 persoon';
        } else if (presence == Presence.all) {
          key += '2 personen';
        }

        if (counts[key] != null) {
          counts.update(key, (value) => value + 1);
        }
      });
    });

    return counts.entries.map((e) => '${e.value}x ${e.key}').join(', ');
  }

  String quantitiesToString(Map<String, double> quantities) {
    return quantities.isEmpty
        ? "onbekend"
        : quantities.entries
            .map((entry) => '${entry.value} ${entry.key}')
            .join(', ');
  }

// TO DO: update quantities + units for multiple quantities
  String generatePantryList(
      List<PantryItem> pantryItems, List<PantryItem> defaultPantryItems) {
    String template =
        "Ik heb recepten nodig voor ${presenceListToString()}. Ik wil graag één recept per keer kiezen. Ik wil dat een lunch minstens 400kcal bevat en een diner minstens 500 kcal. Ik heb de volgende ingrediënten in huis:\n\n";
    Map<PantryItemPreservation?, List<PantryItem>> pantryItemsByPreservation =
        groupBy([...pantryItems, ...defaultPantryItems],
            (PantryItem pantryItem) => pantryItem.preservation);
    List<String> preservationStrings =
        pantryItemsByPreservation.keys.map((key) {
      if (key == null) {
        return 'Onbekend\n + ${pantryItemsByPreservation[key]!.map((pantryItem) {
          return '${pantryItem.name}: ${quantitiesToString(pantryItem.getAvailableQuantity())}';
        }).join('\n + ')}';
      }
      return '${key.label}\n + ${pantryItemsByPreservation[key]!.map((pantryItem) {
        return '${pantryItem.name}: ${quantitiesToString(pantryItem.getAvailableQuantity())}';
      }).join('\n + ')}';
    }).toList();

    return '$template${preservationStrings.join('\n\n')}\n\n';
  }

  @override
  void initState() {
    super.initState();
    daysInRange = getDaysInRangeFromUpcomingWeekday(startDay.number, duration);
    loadPresenceData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                                        child:
                                            DropdownButtonFormField<Presence>(
                                          value: selectedMeals[MealType.lunch]![
                                              day]!,
                                          decoration: InputDecoration(
                                            // Add Horizontal padding using menuItemStyleData.padding so it matches
                                            // the menu padding when button's width is not specified.
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                    horizontal: 12),
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
                                        value: selectedMeals[MealType.dinner]![
                                            day]!,
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
                                            selectedMeals[MealType.dinner]![
                                                day] = newValue!;
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
        floatingActionButton: pantryItems.isNotEmpty
            ? FloatingActionButton(
                child: Image.asset('assets/images/chatgpt_logo.png'),
                onPressed: () {
                  String pantryList =
                      generatePantryList(pantryItems, defaultPantryItems);
                  FlutterClipboard.copy(pantryList);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pantry list copied to clipboard'),
                      backgroundColor: Colors.teal,
                    ),
                  );
                },
              )
            : Container());
  }
}
