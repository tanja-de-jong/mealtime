import 'package:collection/collection.dart';
import 'package:mealtime/food/types/ingredient.dart';
import 'package:mealtime/food/types/pantry_item_usage.dart';
import 'package:mealtime/general/utils.dart';

class PantryItem {
  final String? categoryId; // TO DO: make this field required
  final String? id;
  final String name;
  final List<PantryItemUsage> usages;
  final bool reserved;
  final PantryItemStatus status;
  final List<PantryItemQuantity> quantities;

  PantryItem({
    this.id,
    this.categoryId,
    required this.name,
    this.usages = const [],
    this.reserved = false,
    this.status = PantryItemStatus.inStock,
    this.quantities = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': categoryId,
      'name': name,
      'usages': usages.map((usage) => usage.toJson()).toList(),
      'reserved': reserved,
      'status': status,
      'quantities': quantities.map((quantity) => quantity.toJson()).toList(),
    };
  }

  static void updateUsages(
      List<PantryItemUsage> list, PantryItemUsage newUsage) {
    bool found = false;
    for (PantryItemUsage usage in list) {
      if (usage.recipeId == newUsage.recipeId) {
        usage.items.addAll(newUsage.items);
      }
      found = true;
    }

    if (!found) {
      list.add(newUsage);
    }
  }

  static PantryItem fromJson(String? id, Map<String, dynamic> object) {
    var quantitiesObject = object['quantities'] ??
        (object.containsKey("quantity")
            ? [
                {
                  "quantity": object['quantity'],
                  "unit": object['unit'],
                  "dateOfReceival":
                      DateTime.tryParse(object['dateOfReceival'] ?? "")
                }
              ]
            : []);
    List<PantryItemQuantity> quantities = quantitiesObject
        .map<PantryItemQuantity>(
            (quantity) => PantryItemQuantity.fromJson(quantity))
        .toList();
    var result = PantryItem(
        id: id,
        categoryId: object['productId'],
        name: object['name'],
        usages: (object['usages'] ?? [])
            .map<PantryItemUsage>((usage) => PantryItemUsage.fromJson(usage))
            .toList(),
        reserved: object['reserved'] ?? false,
        status: PantryItemStatus.values.firstWhere(
          (status) =>
              status.toString() == 'PantryItemStatus.${object['status']}',
          orElse: () => object['missing'] != null && object['missing'] == true
              ? PantryItemStatus.needed
              : PantryItemStatus.inStock,
        ),
        quantities: quantities);
    return result;
  }

  @override
  String toString() {
    String itemString = name;
    for (PantryItemQuantity quantity in quantities) {
      itemString += ': ${quantity.quantity} ${quantity.unit}';
    }
    return itemString;
  }

  Map<String, double> getAvailableQuantity() {
    if (quantities.isEmpty) {
      return {};
    }
    Map<String, double> usagesByUnit = {};
    for (PantryItemUsage usage in usages) {
      for (PantryItemUsageItem item in usage.items) {
        String key = item.unit ?? "";
        if (item.quantity != null) {
          if (usagesByUnit.containsKey(key)) {
            usagesByUnit[key] = usagesByUnit[key]! + (item.quantity ?? 0);
          } else {
            usagesByUnit[key] = item.quantity!;
          }
        }
      }
    }

    if (quantities.isEmpty ||
        quantities.every((element) => element.quantity == null)) {
      return usagesByUnit;
    }
    Set<String> units = {
      ...usagesByUnit.keys,
      ...quantities.map((quantity) => quantity.unit!)
    };
    Map<String, double> result = {};
    for (String unit in units) {
      double quantity = quantities
              .firstWhereOrNull((quantity) => quantity.unit == unit)
              ?.quantity ??
          0;
      double? usage = usagesByUnit[unit];
      result[unit] = quantity - (usage ?? 0);
    }
    return result;
  }

  List<PantryItemQuantity> reduceQuantity(String? unit, double amount) {
    List<PantryItemQuantity> newQuantities = [];
    for (PantryItemQuantity quantity in quantities) {
      if (quantity.unit == unit) {
        newQuantities.add(PantryItemQuantity(
          quantity: (quantity.quantity ?? 0) - amount,
          unit: quantity.unit,
          dateOfReceival: quantity.dateOfReceival,
        ));
      } else {
        newQuantities.add(quantity);
      }
    }
    return newQuantities;
  }
}

class PantryItemMap {
  final List<PantryItem> pantryItems;
  final List<PantryItem> missingIngredients;

  PantryItemMap({
    required this.pantryItems,
    required this.missingIngredients,
  });
}

class MissingIngredientsMap {
  Map<PantryItem, bool> missingIngredients = {};

  MissingIngredientsMap();

  void add(PantryItem item, bool isNew) {
    missingIngredients[item] = isNew;
  }

  bool contains(Ingredient ingredient) {
    return ingredient.pantryItems.isNotEmpty &&
        missingIngredients.keys
            .where((
              item,
            ) =>
                item.id == ingredient.pantryItems[0].pantryItemId)
            .isNotEmpty;
  }

  PantryItem? get(Ingredient ingredient) {
    return missingIngredients.keys.firstWhereOrNull((
      item,
    ) =>
        item.id == ingredient.pantryItems[0].pantryItemId);
  }

  List<PantryItem> getNewMissingIngredients() {
    return missingIngredients.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  void markAsAdded(PantryItem oldItem, PantryItem newItem) {
    missingIngredients.remove(oldItem);
    missingIngredients[newItem] = false;
  }
}

enum PantryItemStatus {
  inStock,
  ordered,
  needed,
}

class PantryItemQuantity {
  double? quantity;
  late final String? unit;
  late final DateTime? dateOfReceival;

  PantryItemQuantity({this.quantity, this.unit, this.dateOfReceival});

  static PantryItemQuantity fromJson(Map<String, dynamic> object) {
    return PantryItemQuantity(
        quantity: object['quantity'],
        unit: object['unit'],
        dateOfReceival: parseDate(object['dateOfReceival']));
  }

  String getDaysOld() {
    if (dateOfReceival == null) {
      return '';
    }
    DateTime now = DateTime.now();
    Duration difference = now.difference(dateOfReceival!);
    return '${difference.inDays} dagen';
  }

  Map<String, dynamic> toJson() {
    return {
      'quantity': quantity,
      'unit': unit,
      'dateOfReceival': dateOfReceival,
    };
  }
}
