import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mealtime/food/types/pantry_item.dart';
import 'package:mealtime/general/dialogs.dart';
import 'package:mealtime/general/utils.dart';

import '../../helpers/database.dart'; // Import the file containing the DatabaseService class

class PantryPage extends StatefulWidget {
  const PantryPage({super.key});

  @override
  PantryPageState createState() => PantryPageState();
}

class PantryPageState extends State<PantryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voorraad'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            DatabaseService.getPantryItems(), // Use the getPantryItems method
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('Something went wrong');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text("Loading");
          }

          List<PantryItem> pantryItems = snapshot.data!.docs
              .map((DocumentSnapshot document) => PantryItem.fromJson(
                  document.id, document.data() as Map<String, dynamic>))
              .toList();
          pantryItems.sort((a, b) => a.name.compareTo(b.name));

          return ListView(
            children: pantryItems.map((PantryItem item) {
              return ListTile(
                title: Padding(
                  padding: const EdgeInsets.only(bottom: 1.0),
                  child: Text(
                    item.toString(),
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: item.usages.map<Widget>((usage) {
                        return Text(usage.toString());
                      }).toList() ??
                      [],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => showEditItemDialog(context, item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        bool confirm = await Dialogs.showConfirmationDialog(
                              context,
                              'Remove pantry item',
                              'Are you sure you want to remove this pantry item?',
                            ) ??
                            false;
                        if (confirm) {
                          DatabaseService.deletePantryItem(item
                              .id!); // Assume this method exists in DatabaseService
                        }
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: StreamBuilder<QuerySnapshot>(
        stream: DatabaseService.getPantryItems(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return FloatingActionButton(
                child: const Icon(Icons.add),
                onPressed: () => showEditItemDialog(context, null));
          } else {
            return Container(); // Return an empty container when there's no data
          }
        },
      ),
    );
  }

  void navigateToRecipe(String recipeId) {}
}

void showEditItemDialog(BuildContext context, PantryItem? item) async {
  final TextEditingController nameController =
      TextEditingController(text: item?.name);
  final TextEditingController quantityController =
      TextEditingController(text: item?.quantity?.toString());
  final TextEditingController unitController =
      TextEditingController(text: item?.unit);
  final TextEditingController dateController = TextEditingController(
      text: formatDate(item?.dateOfReceival ?? DateTime.now()));

  final newItem = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(item == null ? 'Voeg item toe' : 'Pas item aan'),
      content: Column(
        children: [
          TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Naam'),
          ),
          TextField(
            controller: quantityController,
            decoration: const InputDecoration(labelText: 'Hoeveelheid'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          TextField(
            controller: unitController,
            decoration: const InputDecoration(labelText: 'Eenheid'),
          ),
          TextField(
            controller: dateController,
            decoration: const InputDecoration(labelText: 'Datum'),
            onTap: () async {
              DateTime? selectedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (selectedDate != null) {
                dateController.text = formatDate(selectedDate);
              }
            },
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Save'),
          onPressed: () {
            Navigator.of(context).pop({
              'name': nameController.text,
              'quantity':
                  double.tryParse(quantityController.text.replaceAll(',', '.')),
              'unit': unitController.text,
              'date': dateController.text,
            });
          },
        ),
      ],
    ),
  );

  if (newItem != null) {
    if (item == null) {
      DatabaseService.addPantryItem(
        newItem['name'].toLowerCase(),
        newItem['quantity'],
        newItem['unit'].toLowerCase(),
        newItem['date'],
      );
    } else {
      DatabaseService.updatePantryItem(
        item.id!,
        newItem['name'].toLowerCase(),
        newItem['quantity'],
        newItem['unit'].toLowerCase(),
        newItem['date'],
      );
    }
  }
}
