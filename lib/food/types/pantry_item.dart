import 'package:mealtime/food/types/pantry_item_usage.dart';
import 'package:mealtime/general/utils.dart';

class PantryItem {
  final String? productId; // TO DO: make this field required
  final String? id;
  final String name;
  final double? quantity;
  final String? unit;
  final List<PantryItemUsage> usages;
  final DateTime? dateOfReceival;
  final bool reserved;

  PantryItem({
    this.id,
    this.productId,
    required this.name,
    this.quantity,
    this.unit,
    this.usages = const [],
    this.dateOfReceival,
    this.reserved = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'usages': usages.map((usage) => usage.toJson()).toList(),
      'dateOfReceival': dateOfReceival,
      'reserved': reserved,
    };
  }

  static PantryItem fromJson(String? id, Map<String, dynamic> object) {
    return PantryItem(
      id: id,
      productId: object['productId'],
      name: object['name'],
      quantity: object['quantity'],
      unit: object['unit'],
      usages: (object['usages'] ?? object['uses'] ?? [])
          .map<PantryItemUsage>(
            (usage) => PantryItemUsage.fromJson(usage),
          )
          .toList(),
      dateOfReceival: DateTime.tryParse(object['dateOfReceival'] ?? ""),
      reserved: object['reserved'] ?? false,
    );
  }

  @override
  String toString() {
    String itemString = name;
    if (quantity != null && unit != null) {
      itemString += ': ${quantity ?? ""} ${unit ?? ""}';
    }
    return itemString;
  }

  String dateOfReceivalString() {
    return dateOfReceival == null ? "" : formatDate(dateOfReceival!);
  }
}
