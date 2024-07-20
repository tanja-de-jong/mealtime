import 'package:drop_down_search_field/drop_down_search_field.dart';
import 'package:flutter/material.dart';
import 'package:mealtime/food/helpers/database.dart';
import 'package:mealtime/food/types/pantry_item.dart';
import 'package:mealtime/food/types/product.dart';
import 'package:mealtime/general/utils.dart';

class EditPantryItemDialog extends StatefulWidget {
  final PantryItem? item;
  final List<ProductCategory> products;

  const EditPantryItemDialog({super.key, this.item, required this.products});

  @override
  EditPantryItemDialogState createState() => EditPantryItemDialogState();
}

class EditPantryItemDialogState extends State<EditPantryItemDialog> {
  List<ProductCategory> products = [];
  String? productId;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController productController = TextEditingController();
  DateTime? selectedDate = DateTime.now();

  String? newProductName = "";

  @override
  void initState() {
    super.initState();
    products = widget.products;
    if (widget.item != null) {
      nameController.text = widget.item!.name;
      quantityController.text =
          widget.item!.quantities[0].quantity?.toString() ?? '';
      unitController.text = widget.item!.quantities[0].unit ?? "";
      dateController.text = formatDate(
          widget.item!.quantities[0].dateOfReceival ?? DateTime.now());
      productId = widget.item!.categoryId;
    } else {
      dateController.text = formatDate(DateTime.now());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Voeg item toe' : 'Pas item aan'),
      content: Column(
        children: [
          DropDownSearchField(
              textFieldConfiguration: TextFieldConfiguration(
                controller: productController,
              ),
              suggestionsCallback: (String pattern) {
                return products
                    .where((product) => product.name
                        .toLowerCase()
                        .contains(pattern.toLowerCase()))
                    .toList();
              },
              itemBuilder: (BuildContext context, ProductCategory productData) {
                return ListTile(
                  title: Text(productData.name),
                );
              },
              onSuggestionSelected: (ProductCategory suggestion) {
                productController.text = suggestion.name;
                setState(() {
                  productId = suggestion.id;
                  nameController.text = suggestion.name;
                });
              },
              displayAllSuggestionWhenTap: true),
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Voeg nieuw product toe'),
                    content: TextField(
                      onChanged: (value) {
                        setState(() {
                          newProductName = value;
                        });
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
                          NavigatorState navigator = Navigator.of(context);
                          ProductCategory? product = products
                              .where(
                                  (product) => product.name == newProductName)
                              .firstOrNull;
                          // Product already exists
                          if (product != null) {
                            setState(() {
                              productId = product.id;
                              nameController.text = products
                                  .firstWhere((p) => p.id == productId)
                                  .name;
                            });
                          } else {
                            // Add new product
                            ProductCategory newProduct =
                                await DatabaseService.addProduct(
                                    newProductName!);
                            setState(() {
                              int insertIndex = products.indexWhere((product) =>
                                  product.compareTo(newProduct) > 0);
                              if (insertIndex == -1) {
                                products.add(newProduct);
                              } else {
                                products.insert(insertIndex, newProduct);
                              }

                              productId = newProduct.id;
                            });
                          }

                          navigator.pop();
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
              selectedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              setState(() {
                dateController.text = formatDate(selectedDate!);
              });
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
              'quantity': quantityController.text == ''
                  ? null
                  : double.tryParse(
                      quantityController.text.replaceAll(',', '.')),
              'unit': unitController.text == '' ? null : unitController.text,
              'date': selectedDate,
            });
          },
        ),
      ],
    );
  }
}
