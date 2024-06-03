import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mealtime/food/helpers/constants.dart';
import 'package:mealtime/food/helpers/utils.dart';
import 'package:mealtime/food/pages/week_planning/select_recipe_dialog.dart';
import 'package:mealtime/food/types/recipe.dart';

class WeekPlanningPage extends StatefulWidget {
  const WeekPlanningPage({super.key});

  @override
  WeekPlanningPageState createState() => WeekPlanningPageState();
}

class WeekPlanningPageState extends State<WeekPlanningPage> {
  DateTime now = DateTime.now();
  late DateTime _startDate;
  late DateTime _endDate;
  num totalLunches = 0;
  num totalDinners = 0;
  String _startMeal = 'Dinner';
  String _endMeal = 'Lunch';
  List<Recipe> _recipes = [];
  List<Map<String, dynamic>> _selectedRecipes = [];
  List<num> presenceValues = [0, 1, 1, 2];

  void addSelectedRecipe(recipeId, name, portions, List<MealType> types) {
    Map<String, Object> recipe = {
      'id': recipeId,
      'name': name,
      'portions': portions,
      'types': types.map((e) => e.name),
    };
    setState(() {
      _selectedRecipes.add(recipe);
    });

    FirebaseFirestore.instance.collection('selected_recipes').add(recipe);
  }

  void _addRecipe() {
    if (_recipes.isNotEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return SelectRecipeDialog(_recipes,
              addSelectedRecipe: addSelectedRecipe);
        },
      );
    }
  }

  Future<void> _loadPresences() async {
    int startWeek = weekOfYear(_startDate);
    int endWeek = weekOfYear(_endDate);
    int startYear = _startDate.year;
    int endYear = _endDate.year;

    totalLunches = 0;
    totalDinners = 0;

    for (int year = startYear; year <= endYear; year++) {
      for (int week = startWeek; week <= endWeek; week++) {
        DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
            .collection('weeks')
            .doc('$year-$week')
            .get();

        if (documentSnapshot.exists) {
          Map<String, dynamic> weekData =
              documentSnapshot.data() as Map<String, dynamic>;
          for (int day = 1; day <= 7; day++) {
            if (weekData.containsKey(day.toString())) {
              Map<String, dynamic> dayData =
                  weekData[day.toString()] as Map<String, dynamic>;
              if (dayData.containsKey('lunch') &&
                  dayData['lunch']['presence'] > 0) {
                if (!(day == 1 && _startMeal == 'Dinner')) {
                  totalLunches += presenceValues[dayData['lunch']['presence']];
                }
              }
              if (dayData.containsKey('diner') &&
                  dayData['diner']['presence'] > 0) {
                if (!(day == 7 && _endMeal == 'Lunch')) {
                  totalDinners += presenceValues[dayData['diner']['presence']];
                }
              }
            }
          }
        }
      }
    }
    setState(() {});
  }

  Future<void> _loadRecipes() async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('recipes').get();

    _recipes = querySnapshot.docs
        .map((doc) =>
            Recipe.fromJson(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
    setState(() {});
  }

  Future<void> _loadSelectedRecipes() async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('selected_recipes').get();

    _selectedRecipes = querySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _startDate = now.add(Duration(days: (DateTime.monday - now.weekday) % 7));
    _endDate = _startDate.add(const Duration(days: 7));
    _loadPresences();
    _loadRecipes();
    _loadSelectedRecipes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planning'),
      ),
      body: Column(
        children: [
          // Date pickers
          ElevatedButton(
            onPressed: () async {
              final DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: _startDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (pickedDate != null && pickedDate != _startDate) {
                setState(() {
                  _startDate = pickedDate;
                });
                _loadPresences();
              }
            },
            child: Text(
                'Start Date: ${DateFormat('EEE d MMM').format(_startDate)}'),
          ),
          // Start meal selector
          DropdownButton<String>(
            value: _startMeal,
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(
                value: 'Lunch',
                child: Text('Lunch'),
              ),
              DropdownMenuItem<String>(
                value: 'Dinner',
                child: Text('Dinner'),
              ),
            ],
            onChanged: (String? newValue) {
              setState(() {
                _startMeal = newValue!;
              });
              _loadPresences();
            },
          ),
          ElevatedButton(
            onPressed: () async {
              final DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: _endDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (pickedDate != null && pickedDate != _endDate) {
                setState(() {
                  _endDate = pickedDate;
                });
                _loadPresences();
              }
            },
            child:
                Text('End Date: ${DateFormat('EEE d MMM').format(_endDate)}'),
          ),
          // End meal selector
          DropdownButton<String>(
            value: _endMeal,
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(
                value: 'Lunch',
                child: Text('Lunch'),
              ),
              DropdownMenuItem<String>(
                value: 'Dinner',
                child: Text('Dinner'),
              ),
            ],
            onChanged: (String? newValue) {
              setState(() {
                _endMeal = newValue!;
              });
              _loadPresences();
            },
          ),
          ElevatedButton(
            onPressed: _addRecipe,
            child: const Text('Add a new recipe'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _selectedRecipes.length,
              itemBuilder: (context, index) {
                final recipe = _selectedRecipes[index];
                return ListTile(
                  title: Text(
                      '${recipe['name']} (${recipe['portions']} porties, ${recipe['types']?.map((e) => MealType.values.firstWhere((t) => t.name == e).value).join(', ')})})'),
                );
              },
            ),
          ),
          // Display presences
          Text('Total lunches: $totalLunches'),
          Text('Total dinners: $totalDinners'),
        ],
      ),
    );
  }
}
