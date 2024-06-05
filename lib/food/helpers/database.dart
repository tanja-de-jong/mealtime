import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mealtime/food/types/ingredient.dart';
import 'package:mealtime/food/types/pantry_item.dart';
import 'package:mealtime/food/types/product.dart';
import 'package:mealtime/food/types/recipe.dart';
import 'package:mealtime/food/types/recipe_instance.dart';

class DatabaseService {
  static List<Product> products = [];

  static final CollectionReference productCollection =
      FirebaseFirestore.instance.collection('products');
  static final CollectionReference pantry =
      FirebaseFirestore.instance.collection('pantry');
  static final CollectionReference recipes =
      FirebaseFirestore.instance.collection('recipes');
  static final CollectionReference recipeInstances =
      FirebaseFirestore.instance.collection('recipeInstances');

  static Future<List<Product>> getProducts() async {
    QuerySnapshot querySnapshot = await productCollection.get();
    products = querySnapshot.docs
        .map((doc) =>
            Product.fromJson(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
    return products;
  }

  static Future<void> addProduct(String name) {
    return productCollection.add({'name': name});
  }

  static Future<List<PantryItem>> getPantryItems() async {
    QuerySnapshot querySnapshot = await pantry.get();
    return querySnapshot.docs
        .map((doc) =>
            PantryItem.fromJson(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  static Stream<QuerySnapshot> getPantryItemStream() {
    return pantry.snapshots();
  }

  static Future<List<DocumentSnapshot>> getAllPantryItems() async {
    QuerySnapshot querySnapshot = await pantry.get();
    return querySnapshot.docs;
  }

  static Future<void> updatePantryItem(String id, String productId,
      String? name, double? newQuantity, String? newUnit, String? newDate) {
    return pantry.doc(id).update({
      'productId': productId,
      'name': name,
      'quantity': newQuantity,
      'unit': newUnit,
      'date': newDate
    });
  }

  static Future<void> addPantryItem(String productId, String name,
      double quantity, String unit, DateTime date) {
    return pantry.add({
      'productId': productId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'date': date
    });
  }

  static Future<void> deletePantryItem(String id) {
    return pantry.doc(id).delete();
  }

  static Future<void> reservePantryItem(String id, bool reserved) {
    return pantry.doc(id).update({'reserved': reserved});
  }

  static Future<List<Recipe>> getRecipes() async {
    QuerySnapshot querySnapshot = await recipes.get();
    return querySnapshot.docs
        .map((doc) =>
            Recipe.fromJson(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
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

  static Future<List<RecipeInstance>> getRecipeInstances() async {
    QuerySnapshot querySnapshot = await recipeInstances.get();
    return querySnapshot.docs
        .map((doc) =>
            RecipeInstance.fromJson(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  static Future<DocumentSnapshot> addRecipeInstanceItem(
      String recipeId,
      String status,
      String name,
      String source,
      int portions,
      List<String> types,
      List<String> ingredients,
      List<String> preparation) async {
    DocumentReference docRef = await recipeInstances.add({
      'recipeId': recipeId,
      'status': status,
      'plannedDates': [],
      'name': name,
      'source': source,
      'portions': portions,
      'types': types,
      'ingredients': ingredients
          .map((ingredient) => {'ingredient': ingredient, 'pantryItems': []}),
      'preparation': preparation,
    });
    DocumentSnapshot docSnap = await docRef.get();
    return docSnap;
  }

  static Future<void> deleteRecipeInstanceItem(String? id) {
    return recipeInstances.doc(id).delete();
  }

  static Future<void> updateRecipeInstanceStatus(String id, String newStatus) {
    return recipeInstances.doc(id).update({
      'status': newStatus,
    });
  }
}
