import 'package:mealtime/food/helpers/constants.dart';
import 'package:mealtime/food/types/ingredient.dart';
import 'package:mealtime/food/types/recipe.dart';

class RecipeInstance extends Recipe {
  String recipeId;
  RecipeStatus status;
  List<DateTime> plannedDates;

  RecipeInstance({
    super.id,
    required this.recipeId,
    required this.status,
    required this.plannedDates,
    required super.name,
    required super.source,
    required super.portions,
    required super.types,
    required super.ingredients,
    required super.preparation,
    required super.duration,
  });

  @override
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
      'steps': preparation,
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
      preparation: List<String>.from(object['preparation'] ?? []),
      duration: object['duration']?.cast<String, String>() ?? {},
    );
  }
}

enum RecipeStatus {
  planned,
  ready,
  done,
}
