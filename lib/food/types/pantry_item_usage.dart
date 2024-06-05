class PantryItemUsage {
  final String recipeId;
  final String recipeName;
  final String ingredient;

  PantryItemUsage({
    required this.recipeId,
    required this.recipeName,
    required this.ingredient,
  });

  Map<String, dynamic> toJson() {
    return {
      'recipeId': recipeId,
      'recipeName': recipeName,
      'ingredient': ingredient,
    };
  }

  static PantryItemUsage fromJson(Map<String, dynamic> object) {
    return PantryItemUsage(
      recipeId: object['recipeId'] ?? "",
      recipeName: object['recipeName'] ?? "",
      ingredient: object['ingredient'],
    );
  }

  @override
  String toString() {
    return '$recipeName: $ingredient';
  }
}
