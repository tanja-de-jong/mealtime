import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:mealtime/food/helpers/constants.dart';
import 'package:mealtime/food/types/recipe.dart';

class SelectRecipeDialog extends StatefulWidget {
  final List<Recipe> recipes;
  final Function addSelectedRecipe;

  const SelectRecipeDialog(this.recipes,
      {super.key, required this.addSelectedRecipe});

  @override
  SelectRecipeDialogState createState() => SelectRecipeDialogState();
}

class SelectRecipeDialogState extends State<SelectRecipeDialog> {
  Recipe? selectedRecipe;
  TextEditingController portionsController = TextEditingController(text: '');
  List<MealType> types = [];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Voeg recept toe'),
      content: Column(
        children: [
          DropdownSearch<Recipe>(
            items: widget.recipes,
            onChanged: (Recipe? newValue) {
              if (newValue != null) {
                setState(() {
                  selectedRecipe = newValue;
                  portionsController.text = selectedRecipe!.portions.toString();
                  types = selectedRecipe!.types;
                });
              }
            },
            itemAsString: (Recipe? item) => item?.name ?? '',
            dropdownDecoratorProps: const DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                labelText: "Recept",
              ),
            ),
          ),
          TextField(
            controller: portionsController,
            decoration: const InputDecoration(labelText: 'Porties'),
            keyboardType: TextInputType.number,
          ),
          DropdownSearch<MealType>.multiSelection(
            items: MealType.values.toList(),
            itemAsString: (MealType type) => type.value,
            selectedItems: const [],
            onChanged: (List<MealType>? newValues) {
              if (newValues != null) {
                setState(() {
                  types = newValues;
                });
              }
            },
            dropdownDecoratorProps: const DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                labelText: "Type",
              ),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: selectedRecipe != null
              ? () {
                  Navigator.of(context).pop();
                  widget.addSelectedRecipe(selectedRecipe!.id,
                      selectedRecipe!.name, portionsController.text, types);
                }
              : null,
          child: const Text('Opslaan'),
        ),
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
