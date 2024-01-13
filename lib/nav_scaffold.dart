import 'package:flutter/material.dart';
import 'package:mealtime/plan.dart';
import 'package:mealtime/presence_list.dart';
import 'package:mealtime/recipe_book.dart';

class NavScaffold extends StatefulWidget {
  final Widget body;
  final int selectedIndex;
  final PreferredSizeWidget? appBar;

  const NavScaffold({
    super.key,
    required this.body,
    required this.selectedIndex,
    this.appBar,
  });

  @override
  NavScaffoldState createState() => NavScaffoldState();
}

class NavScaffoldState extends State<NavScaffold> {
  late int _selectedIndex;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Plan()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PresenceList()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RecipeBook()),
        );
        break;
      // Add more cases if you have more items
    }
  }

  @override
  initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.appBar,
      body: widget.body,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Planning',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Aanwezig',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Recepten',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}