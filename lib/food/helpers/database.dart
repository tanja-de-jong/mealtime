import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mealtime/food/types/ingredient.dart';
import 'package:mealtime/food/types/ingredient_to_pantry_items_mapping.dart';
import 'package:mealtime/food/types/pantry_item.dart';
import 'package:mealtime/food/types/pantry_item_usage.dart';
import 'package:mealtime/food/types/product.dart';
import 'package:mealtime/food/types/recipe.dart';
import 'package:mealtime/food/types/recipe_instance.dart';

class DatabaseService {
  static List<ProductCategory> products = [];

  static final CollectionReference productCollection =
      FirebaseFirestore.instance.collection('products');
  static final CollectionReference pantry =
      FirebaseFirestore.instance.collection('pantry');
  static final CollectionReference recipes =
      FirebaseFirestore.instance.collection('recipes');
  static final CollectionReference recipeInstances =
      FirebaseFirestore.instance.collection('recipeInstances');

  static Future<List<ProductCategory>> getProducts() async {
    QuerySnapshot querySnapshot = await productCollection.get();
    products = querySnapshot.docs
        .map((doc) => ProductCategory.fromJson(
            doc.id, doc.data() as Map<String, dynamic>))
        .toList();
    return products;
  }

  static Future<ProductCategory> addProduct(String name) {
    return productCollection.add({'name': name}).then((docRef) {
      return ProductCategory.fromJson(docRef.id, {'name': name});
    });
  }

  static Future<PantryItemMap> getPantryItems() async {
    QuerySnapshot querySnapshot = await pantry.get();
    List<PantryItem> pantryItems = [];
    List<PantryItem> missingIngredients = [];
    for (var doc in querySnapshot.docs) {
      PantryItem pantryItem =
          PantryItem.fromJson(doc.id, doc.data() as Map<String, dynamic>);
      if (pantryItem.status == PantryItemStatus.needed) {
        missingIngredients.add(pantryItem);
      } else {
        pantryItems.add(pantryItem);
      }
    }

    return PantryItemMap(
        pantryItems: pantryItems, missingIngredients: missingIngredients);
  }

  static Stream<QuerySnapshot> getPantryItemStream() {
    return pantry.snapshots();
  }

  static Future<List<DocumentSnapshot>> getAllPantryItems() async {
    QuerySnapshot querySnapshot = await pantry.get();
    return querySnapshot.docs;
  }

  static Future<PantryItem> updatePantryItem(
      String id,
      String productId,
      String? name,
      double? newQuantity,
      String? newUnit,
      DateTime? newDate) async {
    await pantry.doc(id).update({
      'productId': productId,
      'name': name,
      'quantities': [
        {
          'quantity': newQuantity,
          'unit': newUnit,
          'dateOfReceival': newDate,
        }
      ],
    });
    return PantryItem.fromJson(id, {
      'productId': productId,
      'name': name,
      'quantities': [
        {'quantity': newQuantity, 'unit': newUnit, 'dateOfReceival': newDate}
      ],
    });
  }

  static void addPantryItemAmount(
      String id, double? quantity, String? unit) async {
    await pantry.doc(id).update({
      'quantities': FieldValue.arrayUnion([
        {'quantity': quantity, 'unit': unit, 'dateOfReceival': DateTime.now()}
      ])
    });
  }

  static void orderPantryItems(List items) {
    for (var item in items) {
      pantry.doc(item["id"]).update({
        'status': PantryItemStatus.ordered.name,
        'quantity': item["quantity"],
        'unit': item["unit"]
      });
    }
  }

  static Future<PantryItem> addPantryItem(String productId, String name,
      double quantity, String unit, DateTime? date, PantryItemStatus status) {
    var data = {
      'productId': productId,
      'name': name,
      'status': status.name,
      'quantities': [
        {'quantity': quantity, 'unit': unit, 'date': date}
      ]
    };

    return pantry.add(data).then((docRef) {
      return PantryItem.fromJson(docRef.id, data);
    }).catchError((error) {
      throw error;
    });
  }

  static Future<void> deletePantryItem(String id) {
    // Remove all usages of this pantry item
    return pantry.doc(id).get().then((doc) {
      PantryItem pantryItem =
          PantryItem.fromJson(doc.id, doc.data() as Map<String, dynamic>);
      for (PantryItemUsage usage in pantryItem.usages) {
        recipeInstances.doc(usage.recipeId).get().then((doc) {
          RecipeInstance recipeInstance = RecipeInstance.fromJson(
              doc.id, doc.data() as Map<String, dynamic>);
          List<Ingredient> ingredients = recipeInstance.ingredients;
          for (Ingredient ingredient in ingredients) {
            for (IngredientToPantryItemsMapping pantryItem
                in ingredient.pantryItems) {
              if (pantryItem.pantryItemId == id) {
                ingredient.pantryItems.remove(pantryItem);
              }
            }
          }
          recipeInstances.doc(recipeInstance.id).update({
            'ingredients': ingredients.map((e) => e.toJson()).toList(),
          });
        });
      }
    }).then((_) {
      return pantry.doc(id).delete();
    });
  }

  static Future<PantryItem> reservePantryItem(String id, bool reserved) async {
    await pantry.doc(id).update({'reserved': reserved});
    DocumentSnapshot docSnapshot = await pantry.doc(id).get();
    return PantryItem.fromJson(
        docSnapshot.id, docSnapshot.data() as Map<String, dynamic>);
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
      String recipeInstanceId,
      String recipeName,
      List<Ingredient> ingredients,
      List<String> previousLinkIds) async {
    try {
      // Update recipe instance with new ingredients
      recipeInstances.doc(recipeInstanceId).update({
        'ingredients': ingredients.map((e) => e.toJson()).toList(),
      });

      // Remove the recipe instance from previous linked pantry items
      for (String id in previousLinkIds) {
        DocumentSnapshot<Object?> pantryDoc = await pantry.doc(id).get();
        if (pantryDoc.data() != null) {
          List<PantryItemUsage> pantryItemUsages = PantryItem.fromJson(
                  pantryDoc.id, pantryDoc.data() as Map<String, dynamic>)
              .usages;

          List<PantryItemUsage> updatedUsages = pantryItemUsages
              .where((usage) => usage.recipeId != recipeInstanceId)
              .toList();
          pantry.doc(id).update({
            'usages': updatedUsages.map((e) => e.toJson()).toList(),
          });
        }
      }

      // Process new ingredients
      Map<String, List<PantryItemUsage>> usages = {};
      for (Ingredient ingredient in ingredients) {
        List<IngredientToPantryItemsMapping> pantryItems =
            ingredient.pantryItems;
        String name = ingredient.ingredient;

        for (IngredientToPantryItemsMapping pantryItemMapping in pantryItems) {
          DocumentSnapshot<Object?> pantryDoc =
              await pantry.doc(pantryItemMapping.pantryItemId).get();
          if (pantryDoc.data() != null) {
            if (!usages.containsKey(pantryItemMapping.pantryItemId)) {
              usages[pantryItemMapping.pantryItemId] = PantryItem.fromJson(
                      pantryDoc.id, pantryDoc.data() as Map<String, dynamic>)
                  .usages;
            }
            List<PantryItemUsage> pantryItemUsages =
                usages[pantryItemMapping.pantryItemId]!;

            // Check if the recipe instance already exists in usages
            int index = pantryItemUsages
                .indexWhere((usage) => usage.recipeId == recipeInstanceId);
            if (index != -1) {
              // Update existing usage
              PantryItemUsage existingUsage = pantryItemUsages[index];
              existingUsage.items.add(PantryItemUsageItem(
                name: name,
                quantity: pantryItemMapping.quantity,
                unit: pantryItemMapping.unit,
              ));
              pantryItemUsages[index] = existingUsage;
            } else {
              // Add new usage
              pantryItemUsages.add(PantryItemUsage(
                recipeId: recipeInstanceId,
                recipeName: recipeName,
                items: [
                  PantryItemUsageItem(
                    name: name,
                    quantity: pantryItemMapping.quantity,
                    unit: pantryItemMapping.unit,
                  ),
                ],
              ));
            }

            // Update the pantry item with new usages
            await pantry.doc(pantryItemMapping.pantryItemId).update({
              'usages': pantryItemUsages.map((e) => e.toJson()).toList(),
            });
          }
        }
      }
    } catch (e) {
      print(e);
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
      'ingredients': ingredients
          .map((ingredient) => {'ingredient': ingredient, 'pantryItems': []}),
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
    // Remove all usages of this recipe instance
    return recipeInstances.doc(id).get().then((doc) {
      RecipeInstance recipeInstance =
          RecipeInstance.fromJson(doc.id, doc.data() as Map<String, dynamic>);
      for (Ingredient ingredient in recipeInstance.ingredients) {
        for (IngredientToPantryItemsMapping pantryItem
            in ingredient.pantryItems) {
          pantry.doc(pantryItem.pantryItemId).get().then((doc) {
            PantryItem pantryItem =
                PantryItem.fromJson(doc.id, doc.data() as Map<String, dynamic>);
            List<PantryItemUsage> usages = pantryItem.usages
                .where((usage) => usage.recipeId != id)
                .toList();
            pantry.doc(pantryItem.id).update({
              'usages': usages.map((e) => e.toJson()).toList(),
            });
          });
        }
      }
    }).then((_) {
      return recipeInstances.doc(id).delete();
    });
  }

  static Future<void> updateRecipeInstanceStatus(String id, String newStatus) {
    return recipeInstances.doc(id).update({
      'status': newStatus,
    });
  }

  static Future<void> completeRecipe(RecipeInstance recipeInstance) async {
    for (Ingredient ingredient in recipeInstance.ingredients) {
      for (IngredientToPantryItemsMapping pantryItemMapping
          in ingredient.pantryItems) {
        pantry.doc(pantryItemMapping.pantryItemId).get().then((doc) async {
          if (doc.data() != null) {
            PantryItem pantryItem =
                PantryItem.fromJson(doc.id, doc.data() as Map<String, dynamic>);

            List<PantryItemUsage> usages = pantryItem.usages
                .where((usage) => usage.recipeId != recipeInstance.id)
                .toList();
            List<PantryItemQuantity> newQuantities = pantryItem.reduceQuantity(
                pantryItemMapping.unit, pantryItemMapping.quantity ?? 0);
            await pantry.doc(pantryItem.id).update({
              'usages': usages.map((e) => e.toJson()).toList(),
              'quantities': newQuantities.map((e) => e.toJson()).toList(),
            });
          }
        });
      }
    }
  }
}
