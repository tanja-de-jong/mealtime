import 'package:flutter/material.dart';
import 'package:mealtime/food/helpers/database.dart';
import 'package:mealtime/food/types/ingredient.dart';
import 'package:mealtime/food/types/ingredient_to_pantry_items_mapping.dart';
import 'package:mealtime/food/types/recipe_instance.dart';

class Dialogs {
  static Future<bool?> showConfirmationDialog(
      BuildContext context, String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    );
  }

  static Future<RecipeStatus?> showRecipeStatusDialog(
      BuildContext context, RecipeInstance recipeInstance) async {
    // Show modal to either confirm that the recipe should be completed (RecipeStatus.done) or that is should be planned again (RecipeStatus.planned). It can also be cancelled, so that the status remains what it is (RecipeStatus.ready).
    RecipeStatus status = await showDialog(
      context: context,
      builder: (context) {
        Map<String, double> quantities = {};

        return AlertDialog(
          title: const Text('Receptstatus'),
          content: Column(children: [
            const Text('Wil je dit recept voltooien?'),
            ...recipeInstance.ingredients.asMap().entries.map(
              (entry) {
                Ingredient ingredient = entry.value;
                if (ingredient.pantryItems.isEmpty) {
                  return Container();
                }
                IngredientToPantryItemsMapping pantryItem = ingredient
                    .pantryItems[0]; // TO DO: Fix: pantryItemName isn't filled
                return Row(children: [
                  SizedBox(
                      width: 200,
                      child: Text(ingredient
                          .ingredient)), //TO DO: Replace ingredient name by pantry item name
                  SizedBox(
                      width: 100,
                      child: TextField(
                        // controller: quantityControllers[indexs],
                        decoration: InputDecoration(
                          hintText: pantryItem.quantity?.toString(),
                        ),
                        onChanged: (value) {
                          quantities[entry.key.toString()] =
                              double.parse(value);
                        },
                      )),
                  SizedBox(width: 100, child: Text(pantryItem.unit ?? ''))

                  // Text(pantryItem?.quantities[0].unit ?? ''))
                ]);
              },
            )
          ]),
          actions: <Widget>[
            TextButton(
              child: const Text('Nee, opnieuw plannen'),
              onPressed: () {
                Navigator.of(context).pop(RecipeStatus.planned);
              },
            ),
            TextButton(
              child: const Text('Ja'),
              onPressed: () {
                recipeInstance.ingredients
                    .asMap()
                    .forEach((index, ingredient) async {
                  if (quantities.containsKey(index.toString())) {
                    ingredient.pantryItems[0].quantity =
                        quantities[index.toString()];
                  }
                  // Remove the recipe from the pantry item
                  await DatabaseService.completeRecipe(recipeInstance);
                });
                Navigator.of(context).pop(RecipeStatus.done);
              },
            ),
          ],
        );
      },
    );
    return status;
  }
}
