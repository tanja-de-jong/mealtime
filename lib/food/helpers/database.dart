import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mealtime/food/types/ingredient.dart';

class DatabaseService {
  static final CollectionReference pantry =
      FirebaseFirestore.instance.collection('pantry');
  static final CollectionReference recipes =
      FirebaseFirestore.instance.collection('recipes');

  static Stream<QuerySnapshot> getPantryItems() {
    return pantry.snapshots();
  }

  static Future<List<DocumentSnapshot>> getAllPantryItems() async {
    QuerySnapshot querySnapshot = await pantry.get();
    return querySnapshot.docs;
  }

  static Future<void> updatePantryItem(String id, String? name,
      double? newQuantity, String? newUnit, String? newDate) {
    return pantry.doc(id).update({
      'name': name,
      'quantity': newQuantity,
      'unit': newUnit,
      'date': newDate
    });
  }

  static Future<void> addPantryItem(
      String name, double quantity, String unit, DateTime date) {
    return pantry
        .add({'name': name, 'quantity': quantity, 'unit': unit, 'date': date});
  }

  static Future<void> deletePantryItem(String id) {
    return pantry.doc(id).delete();
  }

  // Get recipe items
  static Stream<QuerySnapshot> getRecipeItems() {
    return recipes.snapshots();
  }

  // Add a new recipe item
  // Add a new recipe item
  static Future<void> addRecipeItem(String name, String source, int portions,
      List<String> types, List<String> ingredients, List<String> preparation) {
    return recipes.add({
      'name': name,
      'source': source,
      'portions': portions,
      'types': types,
      'ingredients': ingredients
          .map((ingredient) => {'ingredient': ingredient, 'pantryItems': []}),
      'preparation': preparation,
    });
  }

  static Future<void> linkRecipeIngredientsToPantryItems(
      String recipeId, String recipeName, List<Ingredient> ingredients) async {
    recipes.doc(recipeId).update({
      'ingredients': ingredients,
    });
    for (Ingredient ingredient in ingredients) {
      List pantryItems = ingredient.pantryItems;
      String name = ingredient.name;

      for (String pantryItemId in pantryItems.map((e) => e['id'])) {
        pantry.doc(pantryItemId).update({
          'uses': FieldValue.arrayUnion([
            {
              'recipeId': recipeId,
              'recipeName': recipeName,
              'ingredient': name
            } // TO DO: rename 'ingredient' to 'name'
          ]),
        });
      }
    }
  }

  // Update an existing recipe item
  static Future<void> updateRecipeItem(
      String id,
      String name,
      String source,
      int portions,
      List<String> types,
      List<String> ingredients,
      List<String> preparation) {
    return recipes.doc(id).update({
      'name': name,
      'source': source,
      'portions': portions,
      'types': types,
      'ingredients': ingredients,
      'preparation': preparation,
    });
  }

  // Delete a recipe item
  static Future<void> deleteRecipeItem(String id) {
    return recipes.doc(id).delete();
  }
}
