import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:mealtime/food/helpers/database.dart';
import 'package:mealtime/food/pages/recipes/edit_recipe_instance_page.dart';
import 'package:mealtime/food/pages/recipes/edit_recipe_page.dart';
import 'package:mealtime/food/pages/recipes/recipe_detail_page.dart';
import 'package:mealtime/food/pages/recipes/recipe_to_pantry_linker_page.dart';
import 'package:mealtime/food/types/recipe.dart';
import 'package:mealtime/food/types/recipe_instance.dart';
import 'package:mealtime/food/widgets/search_bar.dart';
import 'package:mealtime/general/dialogs.dart';
import 'package:mealtime/prompts/chat_prompts.dart';
import 'package:mealtime/widgets/chat_widget.dart';

class RecipeListPage extends StatefulWidget {
  const RecipeListPage({super.key});

  @override
  RecipeListPageState createState() => RecipeListPageState();
}

class RecipeListPageState extends State<RecipeListPage>
    with SingleTickerProviderStateMixin {
  final DatabaseService dbService = DatabaseService();
  bool loading = true;
  List<Recipe> recipes = [];
  List<Recipe> filteredRecipes = [];
  List<RecipeInstance> recipeInstances = [];
  List<RecipeInstance> filteredRecipeInstances = [];

  TabController? tabController;

  Future<void> loadData() async {
    recipes = await DatabaseService.getRecipes();
    recipeInstances = (await DatabaseService.getRecipeInstances())
        .where((element) => element.status != RecipeStatus.done)
        .toList();
    setState(() {
      filteredRecipes = [...recipes];
      filteredRecipeInstances = [...recipeInstances];
      loading = false;
    });
  }

  void filterItems(
      List<Recipe> allItems, List<Recipe> filteredItems, String searchTerm) {
    // Clear existing lists
    filteredItems.clear();

    // Iterate over pantryItems and filter based on searchTerm
    for (var item in allItems) {
      bool matchesSearchTerm =
          item.name.toLowerCase().contains(searchTerm.toLowerCase()) ||
              item.source.toLowerCase().contains(searchTerm.toLowerCase());

      if (matchesSearchTerm) {
        filteredItems.add(item);
      }
    }

    // Optionally, sort each list alphabetically by name
    filteredItems.sort((a, b) => a.name.compareTo(b.name));

    setState(() {});
  }

  void handleAddRecipeResponse(String response) {
    Map<String, dynamic> recipeJson = jsonDecode(response);

    Recipe recipe = Recipe.fromJson(null, recipeJson);

    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => EditRecipePage(
                recipe: recipe,
                isNewRecipe: true,
              )),
    );
  }

  void addInstance(Recipe recipe) async {
    DocumentSnapshot docSnap = await DatabaseService.addRecipeInstanceItem(
        recipe.id!,
        RecipeStatus.planned.toString().split('.').last,
        recipe.name,
        recipe.source,
        recipe.portions,
        recipe.types.map((e) => e.name).toList(),
        recipe.ingredients.map((e) => e.ingredient).toList(),
        recipe.preparation);

    RecipeInstance newInstance = RecipeInstance.fromJson(
        docSnap.id, docSnap.data() as Map<String, dynamic>);

    setState(() {
      recipeInstances.add(newInstance);
      filteredRecipeInstances.add(newInstance);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recept toegevoegd'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  void onRecipeCreated(Recipe recipe) {
    setState(() {
      recipes.add(recipe);
      filteredRecipes.add(recipe);
    });
  }

  Future<void> updateStatus(RecipeInstance recipeInstance) async {
    RecipeStatus? newStatus;
    if (recipeInstance.status == RecipeStatus.ready) {
      // Show modal to either confirm that the recipe should be completed (RecipeStatus.done) or that is should be planned again (RecipeStatus.planned). It can also be cancelled, so that the status remains what it is (RecipeStatus.ready).
      newStatus = await Dialogs.showRecipeStatusDialog(context, recipeInstance);
      if (newStatus == null) {
        return;
      }
    } else {
      newStatus = RecipeStatus.ready;
    }

    DatabaseService.updateRecipeInstanceStatus(
        recipeInstance.id!, newStatus.toString().split('.').last);
    setState(() {
      recipeInstance.status = newStatus!;
      if (newStatus == RecipeStatus.done) {
        recipeInstances.remove(recipeInstance);
        filteredRecipeInstances.remove(recipeInstance);
      }
    });
  }

  @override
  void initState() {
    loadData();
    tabController = TabController(length: 2, vsync: this);
    super.initState();
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
        title: const Text('Recepten'),
        bottom: TabBar(
          controller: tabController,
          tabs: const <Tab>[
            Tab(text: 'Huidige recepten'),
            Tab(text: 'Alle recepten'),
          ],
        ),
      ),
      body: loading
          ? const CircularProgressIndicator()
          : TabBarView(controller: tabController, children: [
              Column(children: [
                GenericSearchBar(
                  onSearchChanged: (value) {
                    setState(() {
                      filterItems(
                          recipeInstances, filteredRecipeInstances, value);
                    });
                  },
                ),
                Expanded(
                    child: ListView(
                  children: filteredRecipeInstances
                      .map((RecipeInstance recipeInstance) {
                    return InkWell(
                        onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    RecipeDetailPage(recipe: recipeInstance),
                              ),
                            ),
                        child: ListTile(
                            title: Text(recipeInstance.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Porties: ${recipeInstance.portions}'),
                                Text(
                                    'Maaltijd: ${recipeInstance.types.map((type) => type.name).join(', ')}'),
                                Text(
                                    'Bereidingstijd: ${recipeInstance.duration['Totale bereidingstijd'] ?? 'onbekend'}'),
                              ],
                            ),
                            trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  IconButton(
                                      icon: Icon(recipeInstance.status ==
                                              RecipeStatus.planned
                                          ? Icons.circle_outlined
                                          : recipeInstance.status ==
                                                  RecipeStatus.ready
                                              ? Icons.check_circle_outline
                                              : Icons.check_circle),
                                      onPressed: () =>
                                          // TO DO: add modal for checking if status after ready should become planned or done
                                          updateStatus(recipeInstance)),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EditRecipeInstancePage(
                                          recipeInstance: recipeInstance,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () async {
                                      bool confirm =
                                          await Dialogs.showConfirmationDialog(
                                                context,
                                                'Verwijder recept',
                                                'Weet je zeker dat je dit recept wil verwijderen?',
                                              ) ??
                                              false;
                                      if (confirm) {
                                        try {
                                          DatabaseService
                                              .deleteRecipeInstanceItem(
                                                  recipeInstance.id);
                                        } catch (e) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Fout bij verwijderen van recept'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        } finally {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                            content: Text(
                                                'Recept succesvol verwijderd'),
                                            backgroundColor: Colors.green,
                                          ));
                                        }
                                        // Show snackbar for success / failure
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
                                              RecipeToPantryLinkerWidget(
                                                  recipeInstance:
                                                      recipeInstance),
                                        ),
                                      );
                                    },
                                  ),
                                ])));
                  }).toList(),
                ))
              ]),
              Column(children: [
                GenericSearchBar(
                  onSearchChanged: (value) {
                    setState(() {
                      filterItems(recipes, filteredRecipes, value);
                    });
                  },
                ),
                Expanded(
                    child: ListView(
                  children: filteredRecipes.map((Recipe recipe) {
                    return InkWell(
                        onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    RecipeDetailPage(recipe: recipe),
                              ),
                            ),
                        child: ListTile(
                            title: Text(recipe.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Porties: ${recipe.portions}'),
                                Text(
                                    'Maaltijd: ${recipe.types.map((type) => type.name).join(', ')}'),
                                Text(
                                    'Bereidingstijd: ${recipe.duration['Totale bereidingstijd'] ?? 'onbekend'}'),
                              ],
                            ),
                            trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    EditRecipePage(
                                                        recipe: recipe)),
                                          )),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () async {
                                      bool confirm =
                                          await Dialogs.showConfirmationDialog(
                                                context,
                                                'Verwijder recept',
                                                'Weet je zeker dat je dit recept wil verwijderen?',
                                              ) ??
                                              false;
                                      if (confirm) {
                                        DatabaseService.deleteRecipeItem(recipe
                                            .id!); // Assume this method exists in DatabaseService
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy),
                                    onPressed: () {
                                      addInstance(recipe);
                                    },
                                  ),
                                ])));
                  }).toList(),
                ))
              ])
            ]),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: Colors.teal,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.back_hand),
            label: 'Handmatig toevoegen',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditRecipePage()),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.text_fields),
            label: 'Toevoegen via tekst',
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  return Dialog(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight:
                            MediaQuery.of(dialogContext).size.height * 0.8,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Voeg recept toe via tekst',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width:
                                  MediaQuery.of(dialogContext).size.width * 0.8,
                              child: ChatWidget(
                                prompt: chatPrompts['createRecipeFromText']!,
                                handleResponse: (response) {
                                  Navigator.of(dialogContext).pop();
                                  handleAddRecipeResponse(response);
                                },
                                inputType: InputType.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

enum InputType {
  text,
  image,
}
