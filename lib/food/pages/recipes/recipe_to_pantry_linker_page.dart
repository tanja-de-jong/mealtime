import 'package:collection/collection.dart';
import 'package:drop_down_search_field/drop_down_search_field.dart';
import 'package:flutter/material.dart';
import 'package:mealtime/food/pages/pantry/edit_pantry_item_dialog.dart';
import 'package:mealtime/food/types/ingredient.dart';
import 'package:mealtime/food/types/ingredient_to_pantry_items_mapping.dart';
import 'package:mealtime/food/types/pantry_item.dart';
import 'package:mealtime/food/types/product.dart';
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
  List<ProductCategory> products = [];
  List<Ingredient> ingredients = [];
  List<PantryItem> pantryItems = [];
  List<PantryItem> filteredPantryItems = [];
  MissingIngredientsMap missingIngredients = MissingIngredientsMap();

  List<TextEditingController> dropDownSearchControllers = [];
  List<TextEditingController> quantityControllers = [];
  List<TextEditingController> unitControllers = [];

  List<String> previousLinkIds = [];

  bool isMissingIngredient(Ingredient ingredient) {
    return missingIngredients.contains(ingredient);
  }

  Future<void> loadData() async {
    products = await DatabaseService.getProducts();
    PantryItemMap allPantryItems = await DatabaseService.getPantryItems();
    List<PantryItem> data = [
      ...allPantryItems.pantryItems,
      ...allPantryItems.missingIngredients
    ];
    data.sort((a, b) => a.name.compareTo(b.name));
    pantryItems = data;

    for (PantryItem mi in allPantryItems.missingIngredients) {
      missingIngredients.add(mi, false);
    }

    setState(() {
      filteredPantryItems =
          pantryItems.where((item) => !item.reserved).toList();
      for (int i = 0; i < ingredients.length; i++) {
        Ingredient ingredient = ingredients[i];
        if (missingIngredients.contains(ingredient)) {
          dropDownSearchControllers.add(TextEditingController());
        } else {
          String? pantryItemId = ingredient.getFirstPantryItemId();
          dropDownSearchControllers.add(TextEditingController(
            text: pantryItemId != null
                ? pantryItems
                    .firstWhereOrNull((element) => element.id == pantryItemId)
                    ?.name
                : null,
          ));
        }

        quantityControllers.add(TextEditingController(
          text: ingredients[i].pantryItems.isNotEmpty
              ? ingredients[i].pantryItems[0].quantity?.toString()
              : null,
        ));
        unitControllers.add(TextEditingController(
          // TO DO: set default value
          text: ingredients[i].pantryItems.isNotEmpty
              ? ingredients[i].pantryItems[0].unit
              : null,
        ));
      }
      loading = false;
    });
  }

  Iterable<PantryItem> filter(String pattern) {
    return filteredPantryItems
        .where((element) => element.name.toLowerCase().contains(pattern));
  }

  void showEditItemDialog(
      Ingredient ingredient, List<ProductCategory> products) async {
    final newItem = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) =>
          EditPantryItemDialog(item: null, products: products),
    );
    // TO DO: improve performance by keeping list sorted when adding item
    if (newItem != null) {
      try {
        List<PantryItemQuantity> quantities =
            (newItem['quantities'] as List).map((q) {
          return PantryItemQuantity.fromJson(q);
        }).toList();

        PantryItem createdItem = PantryItem(
          categoryId: newItem['productId'],
          name: newItem['name'].toLowerCase(),
          quantities: quantities,
          status: PantryItemStatus.needed,
          preservation: PantryItemPreservation.days,
        );

        setState(() {
          ingredient.pantryItems = [
            IngredientToPantryItemsMapping(
              pantryItemName: createdItem.name,
              pantryItemId: createdItem.id!,
            ),
          ];
          missingIngredients.add(createdItem, true);
        });
      } catch (e) {
        // Debugging: Print the error
        print('Error creating PantryItem: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    ingredients = widget.recipeInstance.ingredients;
    previousLinkIds = ingredients
        .expand(
            (ingredient) => ingredient.pantryItems.map((e) => e.pantryItemId))
        .toList();

    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Koppel ingrediënten aan voorraad'),
      ),
      body: SingleChildScrollView(
        child: loading
            ? const CircularProgressIndicator()
            : Column(children: [
                ...widget.recipeInstance.ingredients.asMap().entries.map((
                  entry,
                ) {
                  int index = entry.key;
                  Ingredient ingredient = entry.value;
                  PantryItem? pantryItem = ingredient.pantryItems.isEmpty
                      ? null
                      : pantryItems.firstWhereOrNull((element) =>
                              ingredient.pantryItems[0].pantryItemId ==
                              element.id) ??
                          missingIngredients.get(ingredient);

                  return Row(children: [
                    SizedBox(width: 300, child: Text(ingredient.ingredient)),
                    pantryItem != null &&
                            pantryItem.status == PantryItemStatus.needed
                        ? const SizedBox(
                            height: 50,
                            child: Center(child: Text("Op boodschappenlijst")))
                        : Row(children: [
                            SizedBox(
                                width: 200,
                                child: DropDownSearchField(
                                  textFieldConfiguration:
                                      TextFieldConfiguration(
                                    controller:
                                        dropDownSearchControllers[index],
                                  ),
                                  suggestionsCallback: (String pattern) {
                                    return filter(pattern);
                                  },
                                  itemBuilder: (BuildContext context,
                                      PantryItem itemData) {
                                    return Text(itemData.status ==
                                            PantryItemStatus.needed
                                        ? "(${itemData.name})"
                                        : itemData.name);
                                  },
                                  onSuggestionSelected:
                                      (PantryItem suggestion) {
                                    dropDownSearchControllers[index].text =
                                        suggestion.name;
                                    setState(() {
                                      ingredient.pantryItems = [
                                        IngredientToPantryItemsMapping(
                                          pantryItemId: suggestion.id!,
                                          pantryItemName: suggestion.name,
                                        ),
                                      ];
                                    });
                                    if (suggestion.status ==
                                        PantryItemStatus.needed) {
                                      // Update amount of missing pantry item
                                      DatabaseService.addPantryItemAmount(
                                          suggestion.id!,
                                          suggestion.quantities[0].quantity,
                                          suggestion.quantities[0].unit);
                                    }
                                  },
                                  displayAllSuggestionWhenTap: true,
                                )),
                            SizedBox(
                                width: 100,
                                child: TextField(
                                  controller: quantityControllers[index],
                                  decoration: InputDecoration(
                                    hintText: pantryItem == null ||
                                            pantryItem.quantities.isEmpty
                                        ? ''
                                        : pantryItem
                                            .getAvailableQuantity()[
                                                pantryItem.quantities[0].unit!]
                                            ?.toString(),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      setState(() {
                                        ingredient.pantryItems[0].quantity =
                                            double.tryParse(
                                                value.replaceAll(',', '.'));
                                      });
                                    });
                                  },
                                )),
                            SizedBox(
                                width: 100,
                                child: TextField(
                                  controller: unitControllers[index],
                                  decoration: InputDecoration(
                                    hintText: pantryItem == null ||
                                            pantryItem.quantities.isEmpty
                                        ? ''
                                        : pantryItem.quantities[0].unit
                                            ?.toString(),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      setState(() {
                                        ingredient.pantryItems[0].unit = value;
                                      });
                                    });
                                  },
                                ))

                            // Text(pantryItem?.quantities[0].unit ?? ''))
                          ]),
                    pantryItem == null
                        ? IconButton(
                            onPressed: () =>
                                showEditItemDialog(ingredient, products),
                            icon: const Icon(Icons.shopping_cart))
                        : IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => {},
                          )
                  ]);
                }),
              ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          for (PantryItem pantryItem
              in missingIngredients.getNewMissingIngredients()) {
            // TODO: remove existing missing ingredient if it is replaced

            PantryItem missingIngredient = await DatabaseService.addPantryItem(
                pantryItem.categoryId!,
                pantryItem.name,
                pantryItem.quantities,
                PantryItemStatus.needed);

            ingredients[int.parse(pantryItem.id!)].pantryItems = [
              IngredientToPantryItemsMapping(
                pantryItemId: missingIngredient.id!,
                pantryItemName: missingIngredient.name,
                quantity: missingIngredient.quantities[0].quantity,
                unit: missingIngredient.quantities[0].unit,
              ),
            ];

            missingIngredients.markAsAdded(pantryItem, missingIngredient);
          }
          await DatabaseService.linkRecipeIngredientsToPantryItems(
              widget.recipeInstance.id!,
              widget.recipeInstance.name,
              ingredients,
              previousLinkIds);
          setState(() {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ingrediënten succesvol gekoppeld!'),
              ),
            );
            Navigator.of(context).pop();
          });
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.save),
      ),
    );
  }
}
