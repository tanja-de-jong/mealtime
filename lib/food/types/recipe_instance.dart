import 'package:mealtime/food/helpers/constants.dart';
import 'package:mealtime/food/types/ingredient.dart';

class RecipeInstance {
  String? id;
  String recipeId;
  RecipeStatus status;
  List<DateTime> plannedDates;
  String name;
  String source;
  int portions;
  List<MealType> types;
  List<Ingredient> ingredients;
  List<String> steps;

  RecipeInstance({
    this.id,
    required this.recipeId,
    required this.status,
    required this.plannedDates,
    required this.name,
    required this.source,
    required this.portions,
    required this.types,
    required this.ingredients,
    required this.steps,
  });

  Map<String, dynamic> toJson() {
    return {
      'recipeId': recipeId,
      'status': status.toString().split('.').last,
      'plannedDates':
          plannedDates.map((date) => date.toIso8601String()).toList(),
      'name': name,
      'source': source,
      'portions': portions,
      'types': types.map((e) => e.name).toList(),
      'ingredients': ingredients,
      'steps': steps,
    };
  }

  static RecipeInstance fromJson(String id, Map<String, dynamic> object) {
    return RecipeInstance(
      id: id,
      recipeId: object['recipeId'],
      status: RecipeStatus.values.firstWhere(
          (e) => e.toString() == 'RecipeStatus.${object['status']}'),
      plannedDates: (object['plannedDates'] as List<dynamic>)
          .map((date) => DateTime.parse(date))
          .toList(),
      name: object['name'],
      source: object['source'] ?? '',
      portions: object['portions'] ?? 0,
      types: (object['types'] as List<dynamic>?)?.map((type) {
            return mealTypeFromValue(type);
          }).toList() ??
          [],
      ingredients: (object['ingredients'] as List<dynamic>?)?.map((ingredient) {
            return Ingredient.fromJson(ingredient);
          }).toList() ??
          [],
      steps: List<String>.from(object['preparation'] ?? []),
    );
  }
}

enum RecipeStatus {
  planned,
  ready,
  done,
}
