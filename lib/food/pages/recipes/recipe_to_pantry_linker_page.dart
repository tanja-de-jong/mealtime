import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mealtime/food/types/ingredient.dart';
import 'package:mealtime/food/types/ingredient_to_pantry_items_mapping.dart';
import 'package:mealtime/food/types/recipe.dart';

import '../../helpers/database.dart';

class RecipeToPantryLinkerWidget extends StatefulWidget {
  final Recipe recipe;

  const RecipeToPantryLinkerWidget({super.key, required this.recipe});

  @override
  RecipeToPantryLinkerWidgetState createState() =>
      RecipeToPantryLinkerWidgetState();
}

class RecipeToPantryLinkerWidgetState
    extends State<RecipeToPantryLinkerWidget> {
  bool loading = true;
  List<Ingredient> ingredients = [];
  Map<String, String> pantryItems = {};

  Future<void> loadData() async {
    List<DocumentSnapshot<Object?>> pantryItemDocs =
        await DatabaseService.getAllPantryItems();
    setState(() {
      for (DocumentSnapshot doc in pantryItemDocs) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        pantryItems[doc.id] = data?['name'] as String;
      }

      loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    ingredients = widget.recipe.ingredients;
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Koppel ingrediënten aan voorraad'),
      ),
      body: loading
          ? const CircularProgressIndicator()
          : ListView.builder(
              itemCount: widget.recipe.ingredients.length,
              itemBuilder: (context, index) {
                Ingredient ingredient = ingredients[index];
                String ingredientName = ingredient.name;
                return ListTile(
                    title: Text(ingredientName),
                    trailing: DropdownButton<String>(
                      value: ingredient.pantryItems.isEmpty
                          ? null
                          : ingredient.pantryItems[0].pantryItemId,
                      onChanged: (String? newValue) {
                        setState(() {
                          if (newValue == null) {
                            ingredient.pantryItems = [];
                          } else {
                            ingredient.pantryItems = [
                              IngredientToPantryItemsMapping(
                                  pantryItemId: newValue)
                            ];
                          }
                        });
                      },
                      items: [null, ...pantryItems.keys]
                          .map<DropdownMenuItem<String>>((String? value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: value == null
                              ? const DefaultTextStyle(
                                  style: TextStyle(fontStyle: FontStyle.italic),
                                  child: Text('Geen'),
                                )
                              : Text(pantryItems[value]!),
                        );
                      }).toList(),
                    ));
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          DatabaseService.linkRecipeIngredientsToPantryItems(
              widget.recipe.id!, widget.recipe.name, ingredients);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ingredients linked to pantry items successfully!'),
            ),
          );
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.save),
      ),
    );
  }
}
