const Map<String, String> chatPrompts = {
  "createRecipeFromText": '''
    The following text is copied from a website. Your task is to extract the exact recipe details as they are presented on the website. Do not make assumptions or provide alternative results. Use the website's content only.

    Return a JSON object with the following structure:
    {
      "name": "The name of the recipe as written on the website.",
      "source": "The URL of the recipe.",
      "portions": An integer representing the number of portions, or 0 if no portion size is listed.
      "types": A list of strings representing the meal types, which is zero, one, or more of: ["lunch", "dinner"].
      "ingredients": [
        {"ingredient": "Exact amount and name of the ingredient as listed on the website. Amount must be included if it is listed on the website.", "pantryItems": []}
      ],
      "preparation": [
        "Step 1 as listed on the website",
        "Step 2 as listed on the website"
      ]
    }

    Do not deviate from the content of the website. If you encounter difficulties extracting the data, return a clear error message.
  ''',
};
