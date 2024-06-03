import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mealtime/food/helpers/database.dart';
import 'package:mealtime/food/pages/recipes/edit_recipe_page.dart';
import 'package:mealtime/food/pages/recipes/recipe_to_pantry_linker_page.dart';
import 'package:mealtime/food/types/recipe.dart';
import 'package:mealtime/general/dialogs.dart';

class RecipeListPage extends StatefulWidget {
  const RecipeListPage({super.key});

  @override
  RecipeListPageState createState() => RecipeListPageState();
}

class RecipeListPageState extends State<RecipeListPage> {
  final DatabaseService dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recepten'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: DatabaseService.getRecipeItems(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('Er is iets mis gegaan');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text("Laden...");
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Recipe recipe = Recipe.fromJson(
                  document.id, document.data() as Map<String, dynamic>);
              return ListTile(
                  title: Text(recipe.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Portions: ${recipe.portions}'),
                      Text(
                          'Types: ${recipe.types.map((type) => type.name).join(', ')}'),
                    ],
                  ),
                  trailing:
                      Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                    IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      EditRecipePage(recipe: recipe)),
                            )),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        bool confirm = await Dialogs.showConfirmationDialog(
                              context,
                              'Verwijder recept',
                              'Weet je zeker dat je dit recept wil verwijderen?',
                            ) ??
                            false;
                        if (confirm) {
                          DatabaseService.deleteRecipeItem(document
                              .id); // Assume this method exists in DatabaseService
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.link),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RecipeToPantryLinkerWidget(recipe: recipe),
                          ),
                        );
                      },
                    ),
                  ]));
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EditRecipePage()),
          );
        },
      ),
    );
  }
}
