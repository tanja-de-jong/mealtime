import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:mealtime/food/helpers/constants.dart';
import 'package:mealtime/food/types/recipe.dart';

import '../../helpers/database.dart';

class EditRecipePage extends StatefulWidget {
  final Recipe? recipe;
  final bool isNewRecipe;

  const EditRecipePage({super.key, this.recipe, this.isNewRecipe = false});

  @override
  EditRecipePageState createState() => EditRecipePageState();
}

class EditRecipePageState extends State<EditRecipePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sourceController = TextEditingController();
  final _portionsController = TextEditingController();
  List<MealType> types = [];
  final _ingredientsController = TextEditingController();
  final _stepsController = TextEditingController();
  final _durationController = TextEditingController();
  final DatabaseService dbService = DatabaseService();
  bool urlExistsWarning = false;

  @override
  void initState() {
    super.initState();
    if (widget.recipe != null) {
      _nameController.text = widget.recipe!.name;
      _sourceController.text = widget.recipe!.source;
      _portionsController.text = widget.recipe!.portions.toString();
      types = widget.recipe!.types;
      _ingredientsController.text = widget.recipe!.ingredients
          .map(
            (e) => e.ingredient,
          )
          .join('\n');
      _stepsController.text = widget.recipe!.preparation.join('\n');
      _durationController.text =
          widget.recipe!.duration['Totale bereidingstijd'] ?? 'onbekend';
    }
    _checkUrlExists(_sourceController.text);
  }

  void _addRecipe() {
    if (_formKey.currentState!.validate()) {
      if (!widget.isNewRecipe) {
        // Update existing recipe
        DatabaseService.updateRecipeItem(
          widget.recipe!.id!,
          _nameController.text,
          _sourceController.text,
          int.parse(_portionsController.text),
          types.map((e) => e.label).toList(),
          _ingredientsController.text
              .split('\n')
              .map((ingredient) => ingredient.trim())
              .toList(),
          _stepsController.text.split('\n').map((step) => step.trim()).toList(),
          {
            'Totale bereidingstijd': _durationController.text,
          },
        );
      } else {
        // Add new recipe
        DatabaseService.addRecipeItem(
          _nameController.text,
          _sourceController.text,
          int.parse(_portionsController.text),
          types.map((e) => e.label).toList(),
          _ingredientsController.text
              .split('\n')
              .map((ingredient) => ingredient.trim())
              .toList(),
          _stepsController.text.split('\n').map((step) => step.trim()).toList(),
          {
            'Totale bereidingstijd': _durationController.text,
          },
        );
      }
      Navigator.pop(context);
    }
  }

  void _checkUrlExists(String url) async {
    final exists = await DatabaseService.recipeExistsWithSource(url);
    setState(() {
      urlExistsWarning = exists;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.recipe != null ? 'Recept bewerken' : 'Recept toevoegen'),
      ),
      body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Naam'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vul een naam in';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _sourceController,
                    decoration: const InputDecoration(labelText: 'Bron'),
                    onChanged: (value) {
                      if (value.startsWith('http://') ||
                          value.startsWith('https://')) {
                        _checkUrlExists(value);
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return null;
                      }
                      return null;
                    },
                  ),
                  if (urlExistsWarning)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Er bestaat al een recept met deze bron',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  TextFormField(
                    controller: _portionsController,
                    decoration: const InputDecoration(labelText: 'Porties'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vul het aantal porties in'; // 'Please enter the number of portions' in Dutch
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _durationController,
                    decoration:
                        const InputDecoration(labelText: 'Bereidingstijd'),
                  ),
                  DropdownSearch<MealType>.multiSelection(
                    items: MealType.values.toList(),
                    itemAsString: (MealType type) => type.label,
                    selectedItems: types,
                    onChanged: (List<MealType>? newValues) {
                      if (newValues != null) {
                        setState(() {
                          types = newValues;
                        });
                      }
                    },
                  ),
                  TextFormField(
                    controller: _ingredientsController,
                    decoration:
                        const InputDecoration(labelText: 'Ingrediënten'),
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    minLines: 5, // Add this line to make the text field bigger
                  ),
                  TextFormField(
                      controller: _stepsController,
                      decoration: const InputDecoration(labelText: 'Bereiding'),
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      minLines: 5),
                  ElevatedButton(
                    onPressed: _addRecipe,
                    child: Text(widget.isNewRecipe
                        ? 'Recept Toevoegen'
                        : 'Recept Bijwerken'), // 'Update Recipe' or 'Add Recipe' in Dutch
                  ),
                ],
              ),
            ),
          )),
    );
  }
}
