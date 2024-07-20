import 'package:flutter/material.dart';
import 'package:mealtime/food/helpers/database.dart';
import 'package:mealtime/food/types/pantry_item.dart';

class PantryOrderPage extends StatefulWidget {
  final List<PantryItem> items;

  const PantryOrderPage({super.key, required this.items});

  @override
  State<PantryOrderPage> createState() => _PantryOrderPageState();
}

class _PantryOrderPageState extends State<PantryOrderPage> {
  late List<TextEditingController> _quantityControllers;
  late List<TextEditingController> _unitControllers;

  @override
  void initState() {
    super.initState();
    _quantityControllers = List.generate(
        widget.items.length,
        (index) => TextEditingController(
            text: widget.items[index].quantities[0].quantity.toString()));
    _unitControllers = List.generate(
        widget.items.length,
        (index) => TextEditingController(
            text: widget.items[index].quantities[0].unit));
  }

  @override
  void dispose() {
    for (var controller in _quantityControllers) {
      controller.dispose();
    }
    for (var controller in _unitControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveItems() {
    var items = [];
    for (int i = 0; i < widget.items.length; i++) {
      items.add({
        "id": widget.items[i].id,
        "quantity": int.parse(_quantityControllers[i].text),
        "unit": _unitControllers[i].text
      });
    }
    DatabaseService.orderPantryItems(items);

    // Here, you would typically update your backend or local database with the new item states
    // For now, just pop the navigator or show a success message
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pantry Order'),
      ),
      body: ListView.builder(
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2, // Adjust flex as needed to allocate space
                  child: Text(widget.items[index].name),
                ),
                Expanded(
                  flex: 3, // Adjust flex for proper sizing
                  child: TextFormField(
                    controller: _quantityControllers[index],
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3, // Adjust flex for proper sizing
                  child: TextFormField(
                    controller: _unitControllers[index],
                    decoration: const InputDecoration(labelText: 'Unit'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveItems,
        child: const Icon(Icons.save),
      ),
    );
  }
}
