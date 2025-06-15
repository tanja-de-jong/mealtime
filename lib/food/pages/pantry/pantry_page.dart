import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mealtime/food/pages/pantry/edit_pantry_item_dialog.dart';
import 'package:mealtime/food/pages/pantry/pantry_order_page.dart';
import 'package:mealtime/food/types/pantry_item.dart';
import 'package:mealtime/food/types/product.dart';
import 'package:mealtime/food/widgets/search_bar.dart';
import 'package:mealtime/general/dialogs.dart';

import '../../helpers/database.dart'; // Import the file containing the DatabaseService class

class PantryPage extends StatefulWidget {
  const PantryPage({super.key});

  @override
  PantryPageState createState() => PantryPageState();
}

class PantryPageState extends State<PantryPage>
    with SingleTickerProviderStateMixin {
  bool loading = true;
  String searchTerm = '';
  List<ProductCategory> products = [];
  List<PantryItem> pantryItems = [];
  List<PantryItem> availableItems = [];
  List<PantryItem> unavailableItems = [];
  List<PantryItem> unknownQuantityItems = [];
  List<PantryItem> missingIngredients = [];
  TabController? tabController;
  Map<PantryItem, bool> checkedItems = {};
  bool allChecked = false;
  Map<PantryItemPreservation?, bool> preservationFilters = {
    for (var preservation in [...PantryItemPreservation.values, null])
      preservation: preservation == PantryItemPreservation.frozen ? false : true
  };

  void filterItems(String searchTerm) {
    // Clear existing lists
    availableItems.clear();
    unavailableItems.clear();
    unknownQuantityItems.clear();

    // Iterate over pantryItems and filter based on searchTerm
    for (var item in pantryItems) {
      bool matchesSearchTerm =
          item.name.toLowerCase().contains(searchTerm.toLowerCase()) ||
              (item.categoryId != null &&
                  products.any((product) =>
                      product.id == item.categoryId &&
                      product.name
                          .toLowerCase()
                          .contains(searchTerm.toLowerCase())));
      if (preservationFilters.isNotEmpty) {
        matchesSearchTerm =
            matchesSearchTerm && preservationFilters[item.preservation] == true;
      }

      if (matchesSearchTerm) {
        Map<String, double> quantities = item.getAvailableQuantity();
        if (quantities.isEmpty) {
          unknownQuantityItems.add(item);
        } else if (quantities.values.any((element) => element > 0)) {
          availableItems.add(item);
        } else {
          unavailableItems.add(item);
        }
      }
    }

    // Optionally, sort each list alphabetically by name
    availableItems.sort((a, b) => a.name.compareTo(b.name));
    unavailableItems.sort((a, b) => a.name.compareTo(b.name));
    unknownQuantityItems.sort((a, b) => a.name.compareTo(b.name));

    setState(() {});
  }

  List<PantryItem> sortByProductAndName(List<PantryItem> list) {
    list.sort((a, b) {
      String? productA =
          products.firstWhereOrNull((p) => p.id == a.categoryId)?.name;
      String? productB =
          products.firstWhereOrNull((p) => p.id == b.categoryId)?.name;

      if (productA == null) return -1;
      if (productB == null) return 1;

      int primaryComparison = productA.compareTo(productB);
      if (primaryComparison != 0) return primaryComparison;
      return a.name.compareTo(b.name);
    });

    return list;
  }

  void loadData() async {
    await DatabaseService.getProducts();
    PantryItemMap allPantryItems = await DatabaseService.getPantryItems();
    pantryItems = allPantryItems.pantryItems;
    missingIngredients = allPantryItems.missingIngredients;
    filterItems("");

    setState(() {
      products = DatabaseService.products;
      products.sort((a, b) => a.name.compareTo(b.name));
      loading = false;
    });
  }

  void reserveItem(PantryItem item) async {
    PantryItem updatedPantryItem =
        await DatabaseService.reservePantryItem(item.id!, !item.reserved);

    Map<String, double> quantities = item.getAvailableQuantity();

    setState(() {
      if (quantities.isEmpty) {
        unknownQuantityItems = unknownQuantityItems
            .map((pantryItem) =>
                pantryItem.id == item.id ? updatedPantryItem : pantryItem)
            .toList();
      } else if (quantities.values.any((element) => element > 0)) {
        availableItems = availableItems
            .map((pantryItem) =>
                pantryItem.id == item.id ? updatedPantryItem : pantryItem)
            .toList();
      } else {
        unavailableItems = unavailableItems
            .map((pantryItem) =>
                pantryItem.id == item.id ? updatedPantryItem : pantryItem)
            .toList();
      }
    });
  }

  void togglePriority(PantryItem item) async {
    // TO DO: duplicate code, combine with reserveItem
    PantryItem updatedPantryItem =
        await DatabaseService.togglePriority(item.id!, !item.reserved);

    Map<String, double> quantities = item.getAvailableQuantity();

    setState(() {
      if (quantities.isEmpty) {
        unknownQuantityItems = unknownQuantityItems
            .map((pantryItem) =>
                pantryItem.id == item.id ? updatedPantryItem : pantryItem)
            .toList();
      } else if (quantities.values.any((element) => element > 0)) {
        availableItems = availableItems
            .map((pantryItem) =>
                pantryItem.id == item.id ? updatedPantryItem : pantryItem)
            .toList();
      } else {
        unavailableItems = unavailableItems
            .map((pantryItem) =>
                pantryItem.id == item.id ? updatedPantryItem : pantryItem)
            .toList();
      }
    });
  }

  void showEditItemDialog(BuildContext context, PantryItem? item,
      List<ProductCategory> products) async {
    final newItem = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) =>
          EditPantryItemDialog(item: item, products: products),
    );

    // TO DO: improve performance by keeping list sorted when adding item
    if (newItem != null) {
      if (item == null) {
        // If another PantryItem with the same name already exists: update that item instead of adding a new one
        bool itemExists = pantryItems.any((item) =>
            item.name.toLowerCase() == newItem['name']?.toLowerCase());
        if (itemExists) {
          // Update the existing item instead of adding a new one
          PantryItem updatedItem = pantryItems.firstWhere((item) =>
              item.name.toLowerCase() == newItem['name']?.toLowerCase());
          DatabaseService.addPantryItemAmount(
              updatedItem.id!, newItem['quantity'], newItem['unit']);
          // Update the pantry item in the list
          setState(() {
            updatedItem.quantities.add(PantryItemQuantity(
                quantity: newItem['quantity'],
                unit: newItem['unit'],
                dateOfReceival: newItem['date']));
            filterItems(searchTerm);
          });
        } else {
          // Add a new pantry item
          PantryItem updatedItem = await DatabaseService.addPantryItem(
              newItem['productId'],
              newItem['name']?.toLowerCase(),
              newItem['quantities'],
              PantryItemStatus.inStock);
          // Add to the list of pantry items
          setState(() {
            pantryItems.add(updatedItem);
            filterItems(searchTerm);
          });
        }
      } else {
        PantryItem updatedItem = await DatabaseService.updatePantryItem(
          item.id!,
          newItem['productId'],
          newItem['name']?.toLowerCase(),
          newItem['quantities'],
        );
        // Update the pantry item in the list
        setState(() {
          pantryItems = pantryItems
              .map((pantryItem) => pantryItem.id == item.id
                  ? PantryItem(
                      id: pantryItem.id,
                      categoryId: updatedItem.categoryId,
                      name: updatedItem.name,
                      quantities: updatedItem.quantities,
                      usages: updatedItem.usages,
                      reserved: pantryItem.reserved,
                    )
                  : pantryItem)
              .toList();
          filterItems(searchTerm);
        });
      }
    }
  }

  @override
  void initState() {
    tabController = TabController(length: 2, vsync: this);
    tabController!.addListener(() {
      setState(() {}); // Forces widget to rebuild when active tab changes.
    });
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Voorraad'),
          bottom: TabBar(
            controller: tabController,
            tabs: const <Tab>[
              Tab(text: 'Aanwezig'),
              Tab(text: 'Ontbrekend'),
            ],
          ),
        ),
        body: loading
            ? const CircularProgressIndicator()
            : TabBarView(controller: tabController, children: [
                ItemList(
                    rows: [
                      ...getRows(availableItems),
                      if (unknownQuantityItems.isNotEmpty)
                        const DataRow(cells: [
                          DataCell(SizedBox(height: 5)),
                          DataCell(SizedBox(height: 5)),
                          DataCell(SizedBox(height: 5)),
                          DataCell(SizedBox(height: 5)),
                          DataCell(SizedBox(height: 5)),
                          DataCell(SizedBox(height: 5)),
                          DataCell(SizedBox(height: 5)),
                          DataCell(SizedBox(height: 5)),
                        ]),
                      ...getRows(unknownQuantityItems),
                      if (unavailableItems.isNotEmpty)
                        const DataRow(cells: [
                          DataCell(SizedBox(height: 5)),
                          DataCell(SizedBox(height: 5)),
                          DataCell(SizedBox(height: 5)),
                          DataCell(SizedBox(height: 5)),
                          DataCell(SizedBox(height: 5)),
                          DataCell(SizedBox(height: 5)),
                          DataCell(SizedBox(height: 5)),
                          DataCell(SizedBox(height: 5)),
                        ]),
                      ...getRows(unavailableItems)
                    ],
                    filterItems: filterItems,
                    columns: [
                      'Acties',
                      DataColumn(
                          label: Row(children: [
                        const Text(
                          'Houdbaarheid',
                        ),
                        PopupMenuButton(
                            itemBuilder: (BuildContext context) => [
                                  ...[...PantryItemPreservation.values, null]
                                      .map((preservation) {
                                    return PopupMenuItem(
                                      child: Row(
                                        children: [
                                          Checkbox(
                                              value: preservationFilters[
                                                  preservation],
                                              onChanged: (bool? checked) {
                                                setState(() {
                                                  preservationFilters[
                                                          preservation] =
                                                      checked ?? false;
                                                  filterItems(searchTerm);
                                                });
                                              }),
                                          Text(preservation?.label ??
                                              'Onbekend'),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                            icon: const Icon(Icons.filter_list)),
                      ])),
                      'Categorie',
                      'Naam',
                      'Totaal',
                      'Beschikbaar',
                      'Datum',
                      'Gebruik'
                    ]),
                ItemList(
                  rows: sortByProductAndName(missingIngredients)
                      .map((item) => DataRow(cells: [
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  IconButton(
                                      icon: Icon(
                                          checkedItems.containsKey(item) &&
                                                  checkedItems[item]!
                                              ? Icons.check_box
                                              : Icons.check_box_outline_blank),
                                      onPressed: () => setState(() {
                                            checkedItems[item] =
                                                checkedItems.containsKey(item)
                                                    ? !checkedItems[item]!
                                                    : true;
                                            if (allChecked) allChecked = false;
                                          })),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () async {
                                      bool confirm =
                                          await Dialogs.showConfirmationDialog(
                                                context,
                                                'Remove pantry item',
                                                'Are you sure you want to remove this pantry item?',
                                              ) ??
                                              false;
                                      if (confirm) {
                                        DatabaseService.deletePantryItem(item
                                            .id!); // Assume this method exists in DatabaseService
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            DataCell(Text(item.name)),
                            DataCell((Column(
                                children: item.quantities
                                    .map((quantity) => Text(
                                        '${quantity.quantity} ${quantity.unit}'))
                                    .toList()))),
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: item.usages
                                    .expand<Widget>((usage) =>
                                        usage.items.map((item) => SizedBox(
                                              width: 400,
                                              child: Text(
                                                '${item.name}: ${usage.recipeName}',
                                                overflow: TextOverflow.ellipsis,
                                                softWrap: false,
                                                maxLines: 1,
                                              ),
                                            )))
                                    .toList(),
                              ),
                            ),
                          ]))
                      .toList(),
                  filterItems: () => {},
                  columns: [
                    DataColumn(
                        label: IconButton(
                            onPressed: () {
                              setState(() {
                                allChecked = !allChecked;
                                for (var item in missingIngredients) {
                                  checkedItems[item] = allChecked;
                                }
                              });
                            },
                            icon: Icon(allChecked
                                ? Icons.check_box
                                : Icons.check_box_outline_blank))),
                    'Naam',
                    'Aantal',
                    'Gebruik'
                  ],
                )
              ]),
        floatingActionButton: tabController?.index == 0
            ? FloatingActionButton(
                child: const Icon(Icons.add),
                onPressed: () => showEditItemDialog(context, null, products))
            : FloatingActionButton(
                child: const Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PantryOrderPage(
                            items: missingIngredients
                                .where((item) =>
                                    checkedItems.containsKey(item) &&
                                    checkedItems[item]!)
                                .toList())),
                  );
                }));
  }

  void navigateToRecipe(String recipeId) {}

  List<DataRow> getRows(List<PantryItem> list) {
    return list.map((PantryItem item) {
      return DataRow(cells: <DataCell>[
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                  icon: Icon(item.reserved
                      ? Icons.check_circle
                      : Icons.circle_outlined),
                  onPressed: () => reserveItem(item)),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => showEditItemDialog(context, item, products),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  bool confirm = await Dialogs.showConfirmationDialog(
                        context,
                        'Remove pantry item',
                        'Are you sure you want to remove this pantry item?',
                      ) ??
                      false;
                  if (confirm) {
                    DatabaseService.deletePantryItem(item.id!);
                  }
                },
              ),
            ],
          ),
        ),
        // if (MediaQuery.of(context)
        //         .size
        //         .width >=
        //     700)
        DataCell(
          DropdownButton<PantryItemPreservation>(
            value: item.preservation,
            onChanged: (newValue) {
              setState(() {
                item.preservation = newValue;
                DatabaseService.setPreservationStatus(item.id!, newValue!);
              });
            },
            items: PantryItemPreservation.values
                .map((PantryItemPreservation value) {
              return DropdownMenuItem<PantryItemPreservation>(
                value: value,
                child: Text(value.label),
              );
            }).toList(),
          ),
        ),
        DataCell(Text(item.categoryId == null
            ? ""
            : products
                .firstWhere((product) => product.id == item.categoryId)
                .name)),
        DataCell(Text(
          item.name,
          style: TextStyle(
            decoration: item.reserved ? TextDecoration.lineThrough : null,
          ),
        )),
        DataCell(Column(
            children: item.quantities
                .map(
                    (item) => Text('${item.quantity ?? ''} ${item.unit ?? ''}'))
                .toList())),
        DataCell((Column(
            children: item
                .getAvailableQuantity()
                .entries
                .map((entry) => Text('${entry.value} ${entry.key}'))
                .toList()))),
        DataCell(Column(
            children: item.quantities
                .map((quantity) => Text(quantity.getDaysOld()))
                .toList())),
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: item.usages
                .expand<Widget>((usage) => usage.items.map((item) => SizedBox(
                      width: 400,
                      child: Text(
                        '${item.name}: ${usage.recipeName}',
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        maxLines: 1,
                      ),
                    )))
                .toList(),
          ),
        ),
      ]);
    }).toList();
  }
}

class ItemList extends StatefulWidget {
  final List columns;
  final List<DataRow> rows;
  final Function filterItems;

  const ItemList(
      {super.key,
      required this.rows,
      required this.filterItems,
      required this.columns});

  @override
  State<ItemList> createState() => ItemListState();
}

class ItemListState extends State<ItemList> {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      GenericSearchBar(
        onSearchChanged: (value) {
          setState(() {
            widget.filterItems(value);
          });
        },
      ),
      widget.rows.isEmpty
          ? const Text('Er zijn geen items.')
          : Expanded(
              child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: ConstrainedBox(
                              constraints: BoxConstraints(
                                  minWidth: constraints.maxWidth),
                              child: DataTable(
                                  dataRowMaxHeight: double.infinity,
                                  columns: widget.columns
                                      .map((c) => c is String
                                          ? DataColumn(label: Text(c))
                                          : c as DataColumn)
                                      .toList(),
                                  rows: widget.rows))))))
    ]);
  }
}
