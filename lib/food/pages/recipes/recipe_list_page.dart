import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mealtime/food/helpers/database.dart';
import 'package:mealtime/food/pages/recipes/edit_recipe_page.dart';
import 'package:mealtime/food/pages/recipes/recipe_to_pantry_linker_page.dart';
import 'package:mealtime/food/types/recipe.dart';
import 'package:mealtime/food/types/recipe_instance.dart';
import 'package:mealtime/general/dialogs.dart';

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

  void addInstance(Recipe recipe) async {
    DocumentSnapshot docSnap = await DatabaseService.addRecipeInstanceItem(
        recipe.id!,
        RecipeStatus.planned.toString().split('.').last,
        recipe.name,
        recipe.source,
        recipe.portions,
        recipe.types.map((e) => e.name).toList(),
        recipe.ingredients.map((e) => e.name).toList(),
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

  void updateStatus(RecipeInstance recipeInstance) {
    RecipeStatus newStatus = recipeInstance.status == RecipeStatus.planned
        ? RecipeStatus.ready
        : RecipeStatus.done;
    DatabaseService.updateRecipeInstanceStatus(
        recipeInstance.id!, newStatus.toString().split('.').last);
    setState(() {
      recipeInstance.status = newStatus;
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
              ListView(
                children: filteredRecipeInstances
                    .map((RecipeInstance recipeInstance) {
                  return ListTile(
                      title: Text(recipeInstance.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Portions: ${recipeInstance.portions}'),
                          Text(
                              'Types: ${recipeInstance.types.map((type) => type.name).join(', ')}'),
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
                                    // TODO: add modal for checking if status after ready should become planned or done
                                    updateStatus(recipeInstance)),
                            IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => {}),
                            // Navigator.push(
                            //       context,
                            //       MaterialPageRoute(
                            //           builder: (context) =>
                            //               EditRecipeInstancePage(
                            //                   recipe: recipeInstance)),
                            //     )),
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
                                  DatabaseService.deleteRecipeInstanceItem(
                                      recipeInstance
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
                                        RecipeToPantryLinkerWidget(
                                            recipeInstance: recipeInstance),
                                  ),
                                );
                              },
                            ),
                          ]));
                }).toList(),
              ),
              ListView(
                children: filteredRecipes.map((Recipe recipe) {
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
                      trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
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
                                bool confirm =
                                    await Dialogs.showConfirmationDialog(
                                          context,
                                          'Verwijder recept',
                                          'Weet je zeker dat je dit recept wil verwijderen?',
                                        ) ??
                                        false;
                                if (confirm) {
                                  DatabaseService.deleteRecipeInstanceItem(recipe
                                      .id); // Assume this method exists in DatabaseService
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () {
                                addInstance(recipe);
                              },
                            ),
                          ]));
                }).toList(),
              )
            ]),
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
