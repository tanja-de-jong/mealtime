import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        children: <Widget>[
          // Add your sub-application tiles here
          // Each tile is a GestureDetector that navigates to the sub-application when tapped
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/food');
            },
            child: const Card(
              child: Center(child: Text('Maaltijden')),
            ),
          ),
          // Add more tiles as needed
        ],
      ),
    );
  }
}
