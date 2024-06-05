import 'package:flutter/material.dart';
import 'package:mealtime/food/types/pantry_item.dart';
import 'package:mealtime/food/types/product.dart';
import 'package:mealtime/general/dialogs.dart';
import 'package:mealtime/general/utils.dart';

import '../../helpers/database.dart'; // Import the file containing the DatabaseService class

class PantryPage extends StatefulWidget {
  const PantryPage({super.key});

  @override
  PantryPageState createState() => PantryPageState();
}

class PantryPageState extends State<PantryPage> {
  bool loading = true;
  String searchTerm = '';
  List<Product> products = [];
  List<PantryItem> pantryItems = [];
  List<PantryItem> filteredPantryItems = [];

  void filterItems(String searchTerm) {
    filteredPantryItems = pantryItems
        .where((item) =>
            item.name.toLowerCase().contains(searchTerm.toLowerCase()) ||
            item.productId != null &&
                products
                    .firstWhere((product) => product.id == item.productId)
                    .name
                    .toLowerCase()
                    .contains(searchTerm.toLowerCase()))
        .toList();
    setState(() {
      filteredPantryItems.sort((a, b) => a.name.compareTo(b.name));
    });
  }

  void loadData() async {
    await DatabaseService.getProducts();
    pantryItems = await DatabaseService.getPantryItems();
    filterItems("");

    setState(() {
      products = DatabaseService.products;
      loading = false;
    });
  }

  void reserveItem(PantryItem item) async {
    await DatabaseService.reservePantryItem(item.id!, !item.reserved);
    setState(() {
      filteredPantryItems = filteredPantryItems
          .map((pantryItem) => pantryItem.id == item.id
              ? PantryItem(
                  id: pantryItem.id,
                  productId: pantryItem.productId,
                  name: pantryItem.name,
                  quantity: pantryItem.quantity,
                  unit: pantryItem.unit,
                  usages: pantryItem.usages,
                  dateOfReceival: pantryItem.dateOfReceival,
                  reserved: !pantryItem.reserved,
                )
              : pantryItem)
          .toList();
    });
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Voorraad'),
        ),
        body: loading
            ? const CircularProgressIndicator()
            : Column(children: [
                TextField(
                  onChanged: (value) {
                    setState(() {
                      filterItems(value);
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Search',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                Expanded(
                    child: LayoutBuilder(
                        builder: (context, constraints) =>
                            SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                        minWidth: constraints.maxWidth),
                                    child: DataTable(
                                      dataRowMaxHeight: double.infinity,
                                      columns: const <DataColumn>[
                                        DataColumn(label: Text('Product')),
                                        DataColumn(
                                          label: Text('Naam'),
                                        ),
                                        DataColumn(
                                          label: Text('Aantal'),
                                        ),
                                        DataColumn(
                                          label: Text('Gebruik'),
                                        ),
                                        DataColumn(label: Text('Acties'))
                                      ],
                                      rows: filteredPantryItems
                                          .map((PantryItem item) {
                                        return DataRow(cells: <DataCell>[
                                          DataCell(Text(item.productId == null
                                              ? ""
                                              : products
                                                  .firstWhere((product) =>
                                                      product.id ==
                                                      item.productId)
                                                  .name)),
                                          DataCell(Text(
                                            item.name,
                                            style: TextStyle(
                                              decoration: item.reserved
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                          )),
                                          DataCell(Text(
                                              item.quantity?.toString() ??
                                                  ' ${item.unit ?? ''}')),
                                          DataCell(
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: item.usages
                                                  .map<Widget>((usage) {
                                                return Text(usage.toString());
                                              }).toList(),
                                            ),
                                          ),
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: <Widget>[
                                                IconButton(
                                                    icon: Icon(item.reserved
                                                        ? Icons.check_circle
                                                        : Icons
                                                            .circle_outlined),
                                                    onPressed: () =>
                                                        reserveItem(item)),
                                                IconButton(
                                                  icon: const Icon(Icons.edit),
                                                  onPressed: () =>
                                                      showEditItemDialog(
                                                          context,
                                                          item,
                                                          products),
                                                ),
                                                IconButton(
                                                  icon:
                                                      const Icon(Icons.delete),
                                                  onPressed: () async {
                                                    bool confirm = await Dialogs
                                                            .showConfirmationDialog(
                                                          context,
                                                          'Remove pantry item',
                                                          'Are you sure you want to remove this pantry item?',
                                                        ) ??
                                                        false;
                                                    if (confirm) {
                                                      DatabaseService
                                                          .deletePantryItem(item
                                                              .id!); // Assume this method exists in DatabaseService
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
                                          )
                                        ]);
                                      }).toList(),
                                    )))))
              ]),
        floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () => showEditItemDialog(context, null, products)));
  }

  void navigateToRecipe(String recipeId) {}
}

void showEditItemDialog(
    BuildContext context, PantryItem? item, products) async {
  String? productId = item?.productId;
  final TextEditingController nameController =
      TextEditingController(text: item?.name);
  final TextEditingController quantityController =
      TextEditingController(text: item?.quantity?.toString());
  final TextEditingController unitController =
      TextEditingController(text: item?.unit);
  final TextEditingController dateController = TextEditingController(
      text: formatDate(item?.dateOfReceival ?? DateTime.now()));

  String? newProductName = "";

  final newItem = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(item == null ? 'Voeg item toe' : 'Pas item aan'),
      content: Column(
        children: [
          DropdownButtonFormField<String>(
            value: item?.productId,
            items: products.map<DropdownMenuItem<String>>((Product product) {
              return DropdownMenuItem<String>(
                value: product.id,
                child: Text(product.name),
              );
            }).toList(),
            onChanged: (String? value) {
              productId = value;
            },
            onSaved: (String? value) {
              productId = value;
            },
            decoration: const InputDecoration(
              labelText: 'Product',
            ),
          ),
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Voeg nieuw product toe'),
                    content: TextField(
                      onChanged: (value) {
                        newProductName = value;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Naam',
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Annuleer'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: const Text('Voeg toe'),
                        onPressed: () async {
                          DatabaseService.addProduct(newProductName!);
                          DatabaseService.getProducts();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
            child: const Text(
              "+ Nieuw product",
            ),
          ),
          TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Naam'),
          ),
          TextField(
            controller: quantityController,
            decoration: const InputDecoration(labelText: 'Hoeveelheid'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          TextField(
            controller: unitController,
            decoration: const InputDecoration(labelText: 'Eenheid'),
          ),
          TextField(
            controller: dateController,
            decoration: const InputDecoration(labelText: 'Datum'),
            onTap: () async {
              DateTime? selectedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (selectedDate != null) {
                dateController.text = formatDate(selectedDate);
              }
            },
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Save'),
          onPressed: () {
            Navigator.of(context).pop({
              'productId': productId,
              'name': nameController.text,
              'quantity':
                  double.tryParse(quantityController.text.replaceAll(',', '.')),
              'unit': unitController.text,
              'date': dateController.text,
            });
          },
        ),
      ],
    ),
  );

  if (newItem != null) {
    if (item == null) {
      DatabaseService.addPantryItem(
        newItem['productId'],
        newItem['name'].toLowerCase(),
        newItem['quantity'],
        newItem['unit'].toLowerCase(),
        newItem['date'],
      );
    } else {
      DatabaseService.updatePantryItem(
        item.id!,
        newItem['productId'],
        newItem['name'].toLowerCase(),
        newItem['quantity'],
        newItem['unit'].toLowerCase(),
        newItem['date'],
      );
    }
  }
}
