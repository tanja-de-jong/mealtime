class IngredientToPantryItemsMapping {
  final String pantryItemId;
  final String pantryItemName;
  double? quantity;
  String? unit;

  IngredientToPantryItemsMapping({
    required this.pantryItemId,
    required this.pantryItemName,
    this.quantity,
    this.unit,
  });

  Map<String, dynamic> toJson() {
    return {
      'pantryItemId': pantryItemId,
      'quantity': quantity,
      'unit': unit,
      'pantryItemName': pantryItemName,
    };
  }

  void reduceQuantity(double amount) {
    quantity = (quantity ?? 0) - amount;
  }

  static IngredientToPantryItemsMapping fromJson(Map<String, dynamic> object) {
    return IngredientToPantryItemsMapping(
      pantryItemId: object['pantryItemId'] ?? object['id'],
      quantity: object['quantity'],
      unit: object['unit'],
      pantryItemName: object['pantryItemName'] ?? '',
    );
  }
}
