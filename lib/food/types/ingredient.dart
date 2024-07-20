import 'package:mealtime/food/types/ingredient_to_pantry_items_mapping.dart';

class Ingredient {
  String ingredient;
  List<IngredientToPantryItemsMapping> pantryItems;

  Ingredient({
    required this.ingredient,
    this.pantryItems = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'ingredient': ingredient,
      'pantryItems': pantryItems.map((e) => e.toJson()).toList(),
    };
  }

  static Ingredient fromJson(Map<String, dynamic> object) {
    return Ingredient(
      ingredient: object['ingredient'] ?? '',
      pantryItems:
          object.containsKey('pantryItems') && object['pantryItems'] is List
              ? (object['pantryItems'] as List)
                  .map<IngredientToPantryItemsMapping>((pantryItem) =>
                      IngredientToPantryItemsMapping.fromJson(
                          pantryItem as Map<String, dynamic>))
                  .toList()
              : [],
    );
  }

  String? getFirstPantryItemId() {
    return pantryItems.isNotEmpty ? pantryItems.first.pantryItemId : null;
  }
}
