import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:mealtime/food/helpers/constants.dart';
import 'package:mealtime/food/helpers/database.dart';
import 'package:mealtime/food/types/recipe_instance.dart';

class EditRecipeInstancePage extends StatefulWidget {
  final RecipeInstance recipeInstance;

  const EditRecipeInstancePage({super.key, required this.recipeInstance});

  @override
  _EditRecipeInstancePageState createState() => _EditRecipeInstancePageState();
}

class _EditRecipeInstancePageState extends State<EditRecipeInstancePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sourceController = TextEditingController();
  final _portionsController = TextEditingController();
  List<MealType> types = [];
  final _ingredientsController = TextEditingController();
  final _stepsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.recipeInstance.name;
    _sourceController.text = widget.recipeInstance.source;
    _portionsController.text = widget.recipeInstance.portions.toString();
    types = widget.recipeInstance.types;
    _ingredientsController.text =
        widget.recipeInstance.ingredients.map((e) => e.ingredient).join('\n');
    _stepsController.text = widget.recipeInstance.preparation.join('\n');
  }

  void _updateRecipeInstance() {
    if (_formKey.currentState!.validate()) {
      DatabaseService.updateRecipeInstanceItem(
        widget.recipeInstance.id!,
        _nameController.text,
        _sourceController.text,
        int.parse(_portionsController.text),
        widget.recipeInstance.status.name,
        types.map((e) => e.label).toList(),
        _ingredientsController.text
            .split('\n')
            .map((ingredient) => ingredient.trim())
            .toList(),
        _stepsController.text.split('\n').map((step) => step.trim()).toList(),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receptinstantie bewerken'),
      ),
      body: SingleChildScrollView(
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
                ),
                TextFormField(
                  controller: _portionsController,
                  decoration: const InputDecoration(labelText: 'Porties'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vul het aantal porties in';
                    }
                    return null;
                  },
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
                  decoration: const InputDecoration(labelText: 'Ingrediënten'),
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                ),
                TextFormField(
                  controller: _stepsController,
                  decoration: const InputDecoration(labelText: 'Bereiding'),
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                ),
                ElevatedButton(
                  onPressed: _updateRecipeInstance,
                  child: const Text('Receptinstantie bijwerken'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
