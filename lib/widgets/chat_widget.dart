import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mealtime/food/pages/recipes/recipe_list_page.dart';
import 'package:mealtime/services/openai_service.dart';

class ChatWidget extends StatefulWidget {
  final String prompt;
  final Function(String) handleResponse;
  final InputType inputType;

  const ChatWidget(
      {super.key,
      required this.prompt,
      required this.handleResponse,
      required this.inputType});

  @override
  ChatWidgetState createState() => ChatWidgetState();
}

class ChatWidgetState extends State<ChatWidget> {
  String text = "";
  final OpenAIService openAIService =
      OpenAIService(dotenv.env['OPENAI_API_KEY'] ?? '');
  String response = '';
  bool isLoading = false;

  // Future<String> extractTextFromImage(String imageUrl) async {
  //   final response = await http.post(
  //     Uri.parse('https://api.ocr.space/parse/imageurl'),
  //     headers: {
  //       'apikey': 'your-api-key-here',
  //     },
  //     body: {
  //       'url': imageUrl,
  //       'language': 'nl',
  //     },
  //   );

  //   if (response.statusCode == 200) {
  //     final jsonResponse = jsonDecode(response.body);
  //     return jsonResponse['ParsedResults'][0]['ParsedText'];
  //   } else {
  //     throw Exception('Failed to extract text from image');
  //   }
  // }

  void askQuestion(String question) async {
    setState(() {
      isLoading = true;
    });

    try {
      final result = await openAIService.askChatGPT(question);

      final decodedResult = utf8.decode(result.runes.toList());

      setState(() {
        response = decodedResult;
        print(response);
      });
    } catch (e) {
      setState(() {
        response = 'Error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
    widget.handleResponse(response);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: SingleChildScrollView(
            child: TextField(
              onChanged: (value) {
                text = value;
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Plak hier je recept...',
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (isLoading)
          const CircularProgressIndicator()
        else
          ElevatedButton(
            onPressed: () {
              askQuestion("${widget.prompt}\n$text");
            },
            child: const Text('Vraag ChatGPT'),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}
