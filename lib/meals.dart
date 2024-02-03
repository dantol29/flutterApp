import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'mealDescription.dart';



class AnotherScreen extends StatefulWidget {
  final List<Map<String, dynamic>> ingredientList;

  const AnotherScreen({Key? key, required this.ingredientList}) : super(key: key);

  @override
  _AnotherScreenState createState() => _AnotherScreenState(ingredientList: ingredientList);
}

class _AnotherScreenState extends State<AnotherScreen> {

  _AnotherScreenState({required this.ingredientList});

  bool isLoading = false;
  String responseText = '';
  bool isSpicy = false;
  bool isVegan = false;
  List<Map<String, dynamic>> ingredientList;
  List<String> meals = [];
  List<bool> isFavorite = [];


  @override
  void initState() {
    super.initState();
    completionFun();
  }

  List<String> splitStringOnNumbers(String input) {
    RegExp regex = RegExp(r'\d+\.');
    List<String> matches = regex.allMatches(input).map((match) => match.group(0)!).toList();

    List<String> meals = input.split(RegExp(r'\d+\.'));

    // Remove any empty strings resulting from splitting
    meals.removeWhere((element) => element.isEmpty);

    // Combine the number with each corresponding meal
    for (int i = 0; i < meals.length; i++) {
      meals[i] = "${matches[i]} ${meals[i]}";
    }

    return meals;
  }

  List<String> getTitles(List<Map<String, dynamic>> journals) {
    return journals.map((journal) => journal['title'] as String).toList();
  }

  void completionFun() async {
    setState(() {
      isLoading = true; // Set loading state to true
    });
    print(getTitles(ingredientList));
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer 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'
    };
    final body = json.encode(
      {
        "max_tokens": 500,
        "model": "gpt-3.5-turbo",
        "n": 1,
        "temperature": 1,
        "top_p": 1,
        "frequency_penalty": 0,
        "presence_penalty": 0,
        "messages": [
          {
            "role": "system",
            "content": """Using these ingredients: ${getTitles(ingredientList)}, suggest up to 3 meals I can cook.
             Include only meal names and brief (<7 words) descriptions. Use provided ingredients only!
             Example: 
             1. First meal - description 2. Second meal - description 3. Third meal - description
              Flags: Spicy - $isSpicy, Vegan - $isVegan.
          """
          }
        ]
      },
    );
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: headers,
        body: body,
      );
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final result = jsonResponse['choices'][0]['message'];
        print(result);
        setState(() {
          responseText = result.toString();
          responseText = responseText.substring(responseText.indexOf("1"));
          meals = splitStringOnNumbers(responseText);
          isFavorite = List.generate(meals.length, (index) => false);
          print(meals);
          print(meals.length);
        });
      } else {
        responseText = 'Error: ${response.statusCode}';
        //debugPrint(responseText);
      }
    } catch (e) {
      responseText = 'Error: $e';
      //debugPrint(responseText);
    }
    setState(() {
      isLoading = false; // Set loading state to true
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop(); // Add the functionality you want when the back button is pressed
            },
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Meals',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Suggestions based on provided ingredients',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              isLoading ? const CircularProgressIndicator() : Expanded(
                child: buildList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildList() {
    return ListView.builder(
      itemCount: meals.length,
      itemBuilder: (context, index) {
      int dashIndex = meals[index].indexOf('-');
      String mealTitle = dashIndex != -1 ? meals[index].substring(dashIndex + 1).trim() : meals[index].trim();
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: GestureDetector(
            onTap: () {
              setState(() {
                isFavorite[index] = !isFavorite[index];
              });
            },
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => mealDescriptionScreen(ingredient: mealTitle),
                  ),
                );
              },
              contentPadding: const EdgeInsets.all(16),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                      child: Text(
                        meals[index].split('-')[0].trim(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      ),
                      Icon(
                        Icons.favorite,
                        color: isFavorite[index] ? Colors.red : Colors.grey, // Change color based on the isFavorite status
                      ),
                    ],
                  ),
                  const SizedBox(height: 8), // Adjust the spacing as needed
                  Text(
                    mealTitle, // Add your small description
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

}