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
  final List<TextEditingController> quantityControllers = [];
  final List<TextEditingController> unitControllers = [];
  final List<TextEditingController> dateControllers = [];
  final TextEditingController productController = TextEditingController();
  List<DateTime?> selectedDates = [];

  String? newProductName = "";

  @override
  void initState() {
    super.initState();
    products = widget.products;
    if (widget.item != null) {
      nameController.text = widget.item!.name;
      // If there are no quantities, add an empty one
      if (widget.item!.quantities.isEmpty) {
        widget.item!.quantities.add(PantryItemQuantity());
      }
      for (var quantity in widget.item!.quantities) {
        TextEditingController quantityController = TextEditingController();
        TextEditingController unitController = TextEditingController();
        TextEditingController dateController = TextEditingController();

        quantityController.text = quantity.quantity?.toString() ?? '';
        unitController.text = quantity.unit ?? "";
        dateController.text =
            formatDate(quantity.dateOfReceival ?? DateTime.now());
        selectedDates.add(quantity.dateOfReceival ?? DateTime.now());

        addQuantityControllers(
            quantityController, unitController, dateController);
      }
      productId = widget.item!.categoryId;
      productController.text =
          products.firstWhere((product) => product.id == productId).name;
    } else {
      addEmptyQuantity();
    }
  }

  void addQuantityControllers(
      TextEditingController quantityController,
      TextEditingController unitController,
      TextEditingController dateController) {
    quantityControllers.add(quantityController);
    unitControllers.add(unitController);
    dateControllers.add(dateController);
    selectedDates.add(DateTime.now());
  }

  void addEmptyQuantity() {
    TextEditingController quantityController = TextEditingController();
    TextEditingController unitController = TextEditingController();
    TextEditingController dateController = TextEditingController();
    dateController.text = formatDate(DateTime.now());

    addQuantityControllers(quantityController, unitController, dateController);
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
                              // TO DO: this does not work, because no context
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
          for (int i = 0; i < quantityControllers.length; i++)
            Column(
              children: [
                TextField(
                  controller: quantityControllers[i],
                  decoration: const InputDecoration(labelText: 'Hoeveelheid'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: unitControllers[i],
                  decoration: const InputDecoration(labelText: 'Eenheid'),
                ),
                TextField(
                  controller: dateControllers[i],
                  decoration: const InputDecoration(labelText: 'Datum'),
                  onTap: () async {
                    selectedDates[i] = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    setState(() {
                      dateControllers[i].text = formatDate(selectedDates[i]!);
                    });
                  },
                ),
              ],
            ),
          TextButton(
            onPressed: () {
              addEmptyQuantity();
              setState(() {});
            },
            child: const Text(
              "+ Hoeveelheid toevoegen",
            ),
          )
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Save'),
          onPressed: () {
            Navigator.of(context).pop({
              'productId': productId,
              'name': nameController.text,
              'quantities': quantityControllers
                  .map((controller) => {
                        'quantity': controller.text == ''
                            ? null
                            : double.tryParse(
                                controller.text.replaceAll(',', '.')),
                        'unit': unitControllers[
                                quantityControllers.indexOf(controller)]
                            .text,
                        'dateOfReceival': selectedDates[
                            quantityControllers.indexOf(controller)]
                      })
                  .toList(),
            });
          },
        ),
      ],
    );
  }
}
