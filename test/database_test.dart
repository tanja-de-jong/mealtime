import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mealtime/food/helpers/constants.dart';
import 'package:mealtime/food/helpers/database.dart';
import 'package:mealtime/food/types/ingredient.dart';
import 'package:mealtime/food/types/ingredient_to_pantry_items_mapping.dart';
import 'package:mealtime/food/types/pantry_item.dart';
import 'package:mealtime/food/types/product.dart';
import 'package:mealtime/food/types/recipe.dart';
import 'package:mealtime/food/types/recipe_instance.dart';
import 'package:test/test.dart';

void main() {
  group('DatabaseService', () {
    test('getProducts should return a list of ProductCategory', () async {
      List<ProductCategory> products = await DatabaseService.getProducts();
      expect(products, isA<List<ProductCategory>>());
    });

    test('addProduct should add a new ProductCategory', () async {
      String productName = 'New Product';
      ProductCategory product = await DatabaseService.addProduct(productName);
      expect(product.name, productName);
    });

    test('getPantryItems should return a PantryItemMap', () async {
      PantryItemMap pantryItemMap = await DatabaseService.getPantryItems();
      expect(pantryItemMap, isA<PantryItemMap>());
    });

    test('getPantryItemStream should return a Stream<QuerySnapshot>', () {
      Stream<QuerySnapshot> stream = DatabaseService.getPantryItemStream();
      expect(stream, isA<Stream<QuerySnapshot>>());
    });

    test('getAllPantryItems should return a list of DocumentSnapshot',
        () async {
      List<DocumentSnapshot> pantryItems =
          await DatabaseService.getAllPantryItems();
      expect(pantryItems, isA<List<DocumentSnapshot>>());
    });

    test('updatePantryItem should update a PantryItem', () async {
      String pantryItemId = 'pantryItemId';
      String productId = 'productId';
      String name = 'New Name';
      List quantities = [1, 2, 3];
      PantryItem pantryItem = await DatabaseService.updatePantryItem(
          pantryItemId, productId, name, quantities);
      expect(pantryItem.id, pantryItemId);
      expect(pantryItem.categoryId, productId);
      expect(pantryItem.name, name);
      expect(pantryItem.quantities, quantities);
    });

    test('addPantryItemAmount should add a new amount to a PantryItem',
        () async {
      String pantryItemId = 'pantryItemId';
      double quantity = 1.5;
      String unit = 'kg';
      DatabaseService.addPantryItemAmount(pantryItemId, quantity, unit);
      // No assertion, just checking if the method runs without errors
    });

    test('orderPantryItems should update the status of PantryItems', () {
      List<Map<String, dynamic>> items = [
        {'id': 'item1', 'quantity': 1, 'unit': 'kg'},
        {'id': 'item2', 'quantity': 2, 'unit': 'lbs'},
      ];
      DatabaseService.orderPantryItems(items);
      // No assertion, just checking if the method runs without errors
    });

    test('addPantryItem should add a new PantryItem', () async {
      String productId = 'productId';
      String name = 'New Pantry Item';
      List quantities = [1, 2, 3];
      PantryItemStatus status = PantryItemStatus.needed;
      PantryItem pantryItem = await DatabaseService.addPantryItem(
          productId, name, quantities, status);
      expect(pantryItem.categoryId, productId);
      expect(pantryItem.name, name);
      expect(pantryItem.quantities, quantities);
      expect(pantryItem.status, status);
    });

    test('deletePantryItem should delete a PantryItem', () async {
      String pantryItemId = 'pantryItemId';
      await DatabaseService.deletePantryItem(pantryItemId);
      // No assertion, just checking if the method runs without errors
    });

    test('reservePantryItem should update the reserved status of a PantryItem',
        () async {
      String pantryItemId = 'pantryItemId';
      bool reserved = true;
      PantryItem pantryItem =
          await DatabaseService.reservePantryItem(pantryItemId, reserved);
      expect(pantryItem.id, pantryItemId);
      expect(pantryItem.reserved, reserved);
    });

    test('getRecipes should return a list of Recipe', () async {
      List<Recipe> recipes = await DatabaseService.getRecipes();
      expect(recipes, isA<List<Recipe>>());
    });

    test('addRecipeItem should add a new Recipe', () async {
      String name = 'New Recipe';
      String source = 'New Source';
      int portions = 4;
      List<String> types = ['type1', 'type2'];
      List<String> ingredients = ['ingredient1', 'ingredient2'];
      List<String> preparation = ['step1', 'step2'];
      await DatabaseService.addRecipeItem(
          name, source, portions, types, ingredients, preparation);
      // No assertion, just checking if the method runs without errors
    });

    test(
        'linkRecipeIngredientsToPantryItems should link ingredients to pantry items',
        () async {
      String recipeInstanceId = 'recipeInstanceId';
      String recipeName = 'Recipe Name';
      List<Ingredient> ingredients = [
        Ingredient(
          ingredient: 'ingredient1',
          pantryItems: [
            IngredientToPantryItemsMapping(
                pantryItemId: 'pantryItemId1',
                quantity: 1,
                unit: 'kg',
                pantryItemName: 'pantryItemName1'),
            IngredientToPantryItemsMapping(
                pantryItemId: 'pantryItemId2',
                quantity: 2,
                unit: 'lbs',
                pantryItemName: 'pantryItemName2'),
          ],
        ),
        Ingredient(
          ingredient: 'ingredient2',
          pantryItems: [
            IngredientToPantryItemsMapping(
                pantryItemId: 'pantryItemId3',
                quantity: 3,
                unit: 'kg',
                pantryItemName: 'pantryItemName3'),
            IngredientToPantryItemsMapping(
                pantryItemId: 'pantryItemId4',
                quantity: 4,
                unit: 'lbs',
                pantryItemName: 'pantryItemName4'),
          ],
        ),
      ];
      List<String> previousLinkIds = ['previousLinkId1', 'previousLinkId2'];
      await DatabaseService.linkRecipeIngredientsToPantryItems(
          recipeInstanceId, recipeName, ingredients, previousLinkIds);
      // No assertion, just checking if the method runs without errors
    });

    test('updateRecipeItem should update an existing Recipe', () async {
      String id = 'recipeId';
      String name = 'Updated Recipe';
      String source = 'Updated Source';
      int portions = 6;
      List<String> types = ['type1', 'type2', 'type3'];
      List<String> ingredients = ['ingredient1', 'ingredient2', 'ingredient3'];
      List<String> preparation = ['step1', 'step2', 'step3'];
      await DatabaseService.updateRecipeItem(
          id, name, source, portions, types, ingredients, preparation);
      // No assertion, just checking if the method runs without errors
    });

    test('deleteRecipeItem should delete a Recipe', () async {
      String id = 'recipeId';
      await DatabaseService.deleteRecipeItem(id);
      // No assertion, just checking if the method runs without errors
    });

    test('getRecipeInstances should return a list of RecipeInstance', () async {
      List<RecipeInstance> recipeInstances =
          await DatabaseService.getRecipeInstances();
      expect(recipeInstances, isA<List<RecipeInstance>>());
    });

    test('addRecipeInstanceItem should add a new RecipeInstance', () async {
      String recipeId = 'recipeId';
      String status = 'status';
      String name = 'New Recipe Instance';
      String source = 'New Source';
      int portions = 4;
      List<String> types = ['type1', 'type2'];
      List<String> ingredients = ['ingredient1', 'ingredient2'];
      List<String> preparation = ['step1', 'step2'];
      DocumentSnapshot docSnapshot =
          await DatabaseService.addRecipeInstanceItem(
        recipeId,
        status,
        name,
        source,
        portions,
        types,
        ingredients,
        preparation,
      );
      expect(docSnapshot, isA<DocumentSnapshot>());
    });

    test('deleteRecipeInstanceItem should delete a RecipeInstance', () async {
      String id = 'recipeInstanceId';
      await DatabaseService.deleteRecipeInstanceItem(id);
      // No assertion, just checking if the method runs without errors
    });

    test(
        'updateRecipeInstanceStatus should update the status of a RecipeInstance',
        () async {
      String id = 'recipeInstanceId';
      String newStatus = 'newStatus';
      await DatabaseService.updateRecipeInstanceStatus(id, newStatus);
      // No assertion, just checking if the method runs without errors
    });

    test('completeRecipe should complete a RecipeInstance', () async {
      RecipeInstance recipeInstance = RecipeInstance(
        id: 'recipeInstanceId',
        recipeId: 'recipeId',
        status: RecipeStatus.ready,
        plannedDates: [],
        name: 'Recipe Instance',
        source: 'Source',
        portions: 4,
        types: [MealType.dinner],
        ingredients: [
          Ingredient(
            ingredient: 'ingredient1',
            pantryItems: [
              IngredientToPantryItemsMapping(
                  pantryItemId: 'pantryItemId1',
                  quantity: 1,
                  unit: 'kg',
                  pantryItemName: 'pantryItemName1'),
              IngredientToPantryItemsMapping(
                  pantryItemId: 'pantryItemId2',
                  quantity: 2,
                  unit: 'lbs',
                  pantryItemName: 'pantryItemName2'),
            ],
          ),
          Ingredient(
            ingredient: 'ingredient2',
            pantryItems: [
              IngredientToPantryItemsMapping(
                  pantryItemId: 'pantryItemId3',
                  quantity: 3,
                  unit: 'kg',
                  pantryItemName: 'pantryItemName3'),
              IngredientToPantryItemsMapping(
                  pantryItemId: 'pantryItemId4',
                  quantity: 4,
                  unit: 'lbs',
                  pantryItemName: 'pantryItemName4'),
            ],
          ),
        ],
        preparation: ['step1', 'step2'],
      );
      await DatabaseService.completeRecipe(recipeInstance);
      // No assertion, just checking if the method runs without errors
    });
  });
}
