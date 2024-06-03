class IngredientToPantryItemsMapping {
  final String pantryItemId;
  final double? quantity;

  IngredientToPantryItemsMapping({
    required this.pantryItemId,
    this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'pantryItemId': pantryItemId,
      'quantity': quantity,
    };
  }

  static IngredientToPantryItemsMapping fromJson(Map<String, dynamic> object) {
    return IngredientToPantryItemsMapping(
      pantryItemId: object['id'],
      quantity: object['quantity'],
    );
  }
}
