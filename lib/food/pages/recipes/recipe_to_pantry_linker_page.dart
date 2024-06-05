import 'package:flutter/material.dart';
import 'package:mealtime/food/types/ingredient.dart';
import 'package:mealtime/food/types/ingredient_to_pantry_items_mapping.dart';
import 'package:mealtime/food/types/pantry_item.dart';
import 'package:mealtime/food/types/recipe_instance.dart';

import '../../helpers/database.dart';

class RecipeToPantryLinkerWidget extends StatefulWidget {
  final RecipeInstance recipeInstance;

  const RecipeToPantryLinkerWidget({super.key, required this.recipeInstance});

  @override
  RecipeToPantryLinkerWidgetState createState() =>
      RecipeToPantryLinkerWidgetState();
}

class RecipeToPantryLinkerWidgetState
    extends State<RecipeToPantryLinkerWidget> {
  bool loading = true;
  List<Ingredient> ingredients = [];
  List<PantryItem> pantryItems = [];
  List<PantryItem> filteredPantryItems = [];

  Future<void> loadData() async {
    List<PantryItem> data = await DatabaseService.getPantryItems();
    pantryItems = data;
    pantryItems = data;

    setState(() {
      filteredPantryItems =
          pantryItems.where((item) => !item.reserved).toList();
      loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    ingredients = widget.recipeInstance.ingredients;
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
              itemCount: widget.recipeInstance.ingredients.length,
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
                      items: [null, ...filteredPantryItems.map((e) => e.id)]
                          .map<DropdownMenuItem<String>>((String? value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: value == null
                              ? const DefaultTextStyle(
                                  style: TextStyle(fontStyle: FontStyle.italic),
                                  child: Text('Geen'),
                                )
                              : Text(filteredPantryItems
                                  .firstWhere((element) => element.id == value)
                                  .name),
                        );
                      }).toList(),
                    ));
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          DatabaseService.linkRecipeIngredientsToPantryItems(
              widget.recipeInstance.id!,
              widget.recipeInstance.name,
              ingredients);
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
