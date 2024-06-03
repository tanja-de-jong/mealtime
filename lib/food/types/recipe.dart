import 'package:mealtime/food/helpers/constants.dart';
import 'package:mealtime/food/types/ingredient.dart';

class Recipe {
  String? id;
  String name;
  String source;
  int portions;
  List<MealType> types;
  List<Ingredient> ingredients;
  List<String> steps;

  Recipe({
    this.id,
    required this.name,
    required this.source,
    required this.portions,
    required this.types,
    required this.ingredients,
    required this.steps,
  });

  // Convert a Recipe to a Map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'source': source,
      'portions': portions,
      'types': types.map((e) => e.name).toList(),
      'ingredients': ingredients,
      'steps': steps,
    };
  }

  static Recipe fromJson(String id, Map<String, dynamic> object) {
    var recipe = Recipe(
        id: id,
        name: object['name'],
        source: object['source'] ?? '',
        portions: object['portions'] ?? 0,
        types: (object['types'] as List<dynamic>?)?.map((type) {
              return mealTypeFromValue(type);
            }).toList() ??
            [],
        ingredients:
            (object['ingredients'] as List<dynamic>?)?.map((ingredient) {
                  return Ingredient.fromJson(ingredient);
                }).toList() ??
                [],
        steps: List<String>.from(
          object['preparation'] ?? [],
        ));
    return recipe;
  }
}
