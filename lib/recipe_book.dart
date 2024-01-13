import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mealtime/nav_scaffold.dart';

class Recipe {
  String name;
  String source;
  int portions;
  List<String> ingredients;
  List<String> steps;

  Recipe({
    required this.name,
    required this.source,
    required this.portions,
    required this.ingredients,
    required this.steps,
  });

  // Convert a Recipe to a Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'source': source,
      'portions': portions,
      'ingredients': ingredients,
      'steps': steps,
    };
  }

  // Convert a Map to a Recipe
  static Recipe fromMap(Map<String, dynamic> map) {
    return Recipe(
      name: map['name'],
      source: map['source'],
      portions: map['portions'],
      ingredients: List<String>.from(map['ingredients']),
      steps: List<String>.from(map['steps']),
    );
  }
}

class RecipeBook extends StatefulWidget {
  const RecipeBook({super.key});

  @override
  RecipeBookState createState() => RecipeBookState();
}

class RecipeBookState extends State<RecipeBook> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sourceController = TextEditingController();
  final _portionsController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _stepsController = TextEditingController();

  final CollectionReference recipesCollection =
      FirebaseFirestore.instance.collection('recipes');

  void _addRecipe() {
    if (_formKey.currentState!.validate()) {
      recipesCollection.add(Recipe(
        name: _nameController.text,
        source: _sourceController.text,
        portions: int.parse(_portionsController.text),
        ingredients: _ingredientsController.text.split(','),
        steps: _stepsController.text.split(','),
      ).toMap());
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavScaffold(
      appBar: AppBar(
        title: const Text('Recepten'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Navigate to the AddRecipePage when the button is pressed
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddRecipePage()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: recipesCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('Er is iets mis gegaan');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text("Laden...");
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Recipe recipe = Recipe.fromMap(document.data() as Map<String, dynamic>);
              return ListTile(
                title: Text(recipe.name),
              );
            }).toList(),
          );
        },
      ),
      selectedIndex: 2,
    );
  }
}

class AddRecipePage extends StatefulWidget {
  const AddRecipePage({super.key});

  @override
  AddRecipePageState createState() => AddRecipePageState();
}

class AddRecipePageState extends State<AddRecipePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sourceController = TextEditingController();
  final _portionsController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _stepsController = TextEditingController();

  final CollectionReference recipesCollection =
      FirebaseFirestore.instance.collection('recipes');

  void _addRecipe() {
    if (_formKey.currentState!.validate()) {
      recipesCollection.add(Recipe(
        name: _nameController.text,
        source: _sourceController.text,
        portions: int.parse(_portionsController.text),
        ingredients: _ingredientsController.text.split(','),
        steps: _stepsController.text.split(','),
      ).toMap());
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recept Toevoegen'),
      ),
      body: Form(
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
                    return 'Vul het aantal porties in'; // 'Please enter the number of portions' in Dutch
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _ingredientsController,
                decoration: const InputDecoration(labelText: 'Ingrediënten (gescheiden door komma\'s)'), // 'Ingredients (comma separated)' in Dutch
              ),
              TextFormField(
                controller: _stepsController,
                decoration: const InputDecoration(labelText: 'Stappen (gescheiden door komma\'s)'), // 'Steps (comma separated)' in Dutch
              ),
              ElevatedButton(
                onPressed: _addRecipe,
                child: const Text('Recept Toevoegen'), // 'Add Recipe' in Dutch
              ),
            ],
          ),
        ),
      ),
    );
  }
}