import 'package:mealtime/food/types/pantry_item_usage.dart';
import 'package:mealtime/general/utils.dart';

class PantryItem {
  final String? id;
  final String name;
  final int? quantity;
  final String? unit;
  final List<PantryItemUsage> usages;
  final DateTime dateOfReceival;

  PantryItem({
    this.id,
    required this.name,
    this.quantity,
    this.unit,
    this.usages = const [],
    required this.dateOfReceival,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'usages': usages.map((usage) => usage.toJson()).toList(),
      'dateOfReceival': dateOfReceival,
    };
  }

  static PantryItem fromJson(String? id, Map<String, dynamic> object) {
    return PantryItem(
      id: id,
      name: object['name'],
      quantity: object['quantity'],
      unit: object['unit'],
      usages: object['usages']
          ?.map<PantryItemUsage>(
            (usage) => PantryItemUsage.fromJson(usage),
          )
          .toList(),
      dateOfReceival: DateTime.parse(object['dateOfReceival']),
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
    return formatDate(dateOfReceival);
  }
}
