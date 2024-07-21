import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealtime/food/helpers/constants.dart';
import 'package:mealtime/food/pages/recipes/recipe_detail_page.dart';
import 'package:mealtime/food/types/ingredient.dart';
import 'package:mealtime/food/types/recipe.dart';

void main() {
  testWidgets('RecipeDetailPage shows correct texts',
      (WidgetTester tester) async {
    // Define a mock recipe to pass to RecipeDetailPage
    final mockRecipe = Recipe(
      portions: 4,
      types: [MealType.lunch, MealType.dinner],
      ingredients: [
        Ingredient(ingredient: 'Ingredient1'),
        Ingredient(ingredient: 'Ingredient2')
      ],
      preparation: ['Step1', 'Step2'],
      name: 'recipe1',
      source: 'source',
    );

    // Build our app and trigger a frame.
    await tester
        .pumpWidget(MaterialApp(home: RecipeDetailPage(recipe: mockRecipe)));

    // for (final element in find.byType(Text).evaluate()) {
    //   final textWidget = element.widget as Text;
    //   print(textWidget.data);
    // }

    // Verify that certain texts are found within the widget
    expect(find.text('Porties: 4'), findsOneWidget);
    expect(find.text('Soort: Lunch, Diner'), findsOneWidget);
    expect(find.text('- Ingredient1'), findsOneWidget);
    expect(find.text('- Ingredient2'), findsOneWidget);
    expect(find.text('- Step1'), findsOneWidget);
    expect(find.text('- Step2'), findsOneWidget);
    expect(find.text('recipe1'), findsOneWidget);
    expect(find.text('source'), findsOneWidget);
  });
}
