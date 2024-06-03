import 'package:flutter/material.dart';
import 'package:mealtime/food/types/recipe.dart';

class RecipeDetailPage extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailPage({super.key, required this.recipe});

  @override
  RecipeDetailPageState createState() => RecipeDetailPageState();
}

class RecipeDetailPageState extends State<RecipeDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Source: ${widget.recipe.source}',
                style: const TextStyle(fontSize: 18)),
            Text('Portions: ${widget.recipe.portions}',
                style: const TextStyle(fontSize: 18)),
            Text('Types: ${widget.recipe.types.join(', ')}',
                style: const TextStyle(fontSize: 18)),
            const Text('Ingredients:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            for (var ingredient in widget.recipe.ingredients)
              Text(ingredient.name, style: const TextStyle(fontSize: 16)),
            const Text('Steps:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            for (var step in widget.recipe.steps)
              Text(step, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
