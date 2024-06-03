import 'package:mealtime/food/types/ingredient_to_pantry_items_mapping.dart';

class Ingredient {
  String name;
  List<IngredientToPantryItemsMapping> pantryItems;

  Ingredient({
    required this.name,
    this.pantryItems = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'ingredient': name,
      'pantryItems': pantryItems,
    };
  }

  static Ingredient fromJson(Map<String, dynamic> object) {
    return Ingredient(
        name: object['ingredient'],
        pantryItems: object['pantryItems']
            ?.map<IngredientToPantryItemsMapping>(
              (pantryItem) =>
                  IngredientToPantryItemsMapping.fromJson(pantryItem),
            )
            .toList());
  }
}
