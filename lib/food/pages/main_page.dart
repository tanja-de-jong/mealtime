import 'package:flutter/material.dart';
import 'package:mealtime/food/pages/pantry/pantry_page.dart';
import 'package:mealtime/food/pages/presence/presence_page.dart';
import 'package:mealtime/food/pages/recipes/recipe_list_page.dart';
import 'package:mealtime/food/pages/week_planning/week_planning_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  final _pageController = PageController();
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: const <Widget>[
          WeekPlanningPage(),
          PresencePage(),
          RecipeListPage(),
          PantryPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Planning',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Aanwezig',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Recepten',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.kitchen),
            label: 'Voorraad',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        onTap: _onItemTapped,
        backgroundColor: Colors.blueGrey,
      ),
    );
  }
}
