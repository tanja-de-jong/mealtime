import 'package:flutter/material.dart';
import 'package:mealtime/food/helpers/constants.dart';
import 'package:mealtime/food/types/recipe.dart';
import 'package:url_launcher/url_launcher.dart';

class RecipeDetailPage extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailPage({super.key, required this.recipe});

  @override
  RecipeDetailPageState createState() => RecipeDetailPageState();
}

class RecipeDetailPageState extends State<RecipeDetailPage> {
  Widget getSourceWidget() {
    Uri? uri = Uri.tryParse(widget.recipe.source);
    return Row(children: [
      const Text('Bron: ',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      if (uri?.hasAbsolutePath ?? false)
        InkWell(
          child: Text(
            widget.recipe.source,
            style: const TextStyle(
                color: Colors.blue, decoration: TextDecoration.underline),
          ),
          onTap: () async {
            if (await canLaunchUrl(uri!)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              throw 'Could not launch $uri';
            }
          },
        )
      else
        Text(widget.recipe.source)
    ]);
    // Any other widgets...
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe.name),
      ),
      body: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  getSourceWidget(),
                  Text(
                    'Bereidingstijd: ${widget.recipe.duration['Totale bereidingstijd']}',
                  ),
                  Text(
                    'Porties: ${widget.recipe.portions}',
                  ),
                  Text(
                    'Soort: ${widget.recipe.types.map((type) => type.label).join(', ')}',
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const Text('Ingrediënten:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  for (var ingredient in widget.recipe.ingredients)
                    Text("- ${ingredient.ingredient}",
                        style: const TextStyle(fontSize: 16)),
                  const SizedBox(
                    height: 10,
                  ),
                  const Text('Stappen:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  for (var step in widget.recipe.preparation)
                    Text("${step.trim() == "" ? "" : "- "}$step",
                        style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          )),
    );
  }
}
