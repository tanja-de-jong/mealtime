class PantryItemUsage {
  final String recipeId;
  final String recipeName;
  final List<PantryItemUsageItem> items;

  PantryItemUsage({
    required this.recipeId,
    required this.recipeName,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'recipeId': recipeId,
      'recipeName': recipeName,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  static PantryItemUsage fromJson(Map<String, dynamic> object) {
    List<PantryItemUsageItem> items = [];
    if (object['items'] != null) {
      items = (object['items'] ?? [])
          .map<PantryItemUsageItem>(
              (item) => PantryItemUsageItem.fromJson(item))
          .toList();
    } else {
      items = [
        PantryItemUsageItem(
          name: object['name'],
          quantity: object['quantity'],
          unit: object['unit'],
        ),
      ];
    }

    return PantryItemUsage(
      recipeId: object['recipeId'] ?? "",
      recipeName: object['recipeName'] ?? "",
      items: items,
    );
  }

  double getTotalQuantity() {
    return items.fold(0, (previousValue, element) {
      return previousValue + (element.quantity ?? 0);
    });
  }
}

class PantryItemUsageItem {
  final String name;
  final double? quantity;
  final String? unit;

  PantryItemUsageItem({required this.name, this.quantity, this.unit});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
    };
  }

  static PantryItemUsageItem fromJson(Map<String, dynamic> object) {
    return PantryItemUsageItem(
      name: object['name'],
      quantity: object['quantity'],
      unit: object['unit'],
    );
  }
}
