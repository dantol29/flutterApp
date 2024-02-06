import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class mealDescriptionScreen extends StatefulWidget {
  final String mealTitle;
  final List<Map<String, dynamic>> ingredientList;

  const mealDescriptionScreen({Key? key, required this.mealTitle, required this.ingredientList}) : super(key: key);

  @override
  _mealDescriptionScreenState createState() => _mealDescriptionScreenState(mealTitle: mealTitle, ingredientList: ingredientList);
}

class _mealDescriptionScreenState extends State<mealDescriptionScreen> {


  _mealDescriptionScreenState({required this.mealTitle, required this.ingredientList});
  String mealTitle;
  List<Map<String, dynamic>> ingredientList;
  String? youtubeLink;
  String? imgLink;
  String youtubeImgLink = '';
  String responseText = '';
  bool isLoading = false;
  String time = '';
  String difficulty = '';
  String servings = '';
  String ingredients = '';

  @override
  void initState() {
    super.initState();
    completionFun();
    callFastAPI(mealTitle);
  }

  List<String> getTitles(List<Map<String, dynamic>> journals) {
    return journals.map((journal) => journal['title'] as String).toList();
  }

  Future<void> callFastAPI(String? query) async {

    query = "$query recipe";
    final responseImage =  await http.get(Uri.parse('https://fastapi-production-b71a.up.railway.app/image?query=$query'));
    if (responseImage.statusCode == 200) {
      Map<String, dynamic> data = json.decode(responseImage.body);
      setState(() {
        imgLink = data['image_url'];
      });
      debugPrint("Response from Python: ${data['image_url']}");
    } else {
      debugPrint("Failed to call Python script: ${responseImage.statusCode}");
    }

    final response =  await http.get(Uri.parse('https://fastapi-production-b71a.up.railway.app/video?query=$query'));
    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      setState(() {
        youtubeLink = data['video_link'];
        youtubeImgLink = data['thumbnail_url'];
        youtubeImgLink = youtubeImgLink.replaceFirst("/default.jpg", "/mqdefault.jpg");
      });
      debugPrint("Response from Python: ${data['video_link']}");
    } else {
      debugPrint("Failed to call Python script: ${response.statusCode}");
    }
  }

  void completionFun() async {
    setState(() {
      isLoading = true; // Set loading state to true
    });
    print(getTitles(ingredientList));
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${dotenv.env['token']}'
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
            "content": """
            Using only the provided ingredients: ${getTitles(ingredientList)},
            please write a recipe for $mealTitle.
            Divide the recipe into clear steps and write two newline characters '\n' after each step.
            Do not make it too detailed, avoid obvious steps.
            At the beginning write how many minutes it takes to prepare the meal (t:30:t).
            How many people it serves (s:4:s).
            The level of difficulty (easy, medium, hard, Gordon Ramsy) (d:easy:d).
            Write all ingredients in the format: 1. 100g of sugar\n 2. 200g of flour\n
            And write 'END' after to know where parameters end and the recipe starts.
            Write 'ENDINGREDIENTS' after to know where ingredients end and the recipe starts.
            Example:
            t:10:t
            s:1:s
            d:easy:d
            END
            1. 100g of sugar
            2. 200g of flour
            ENDINGREDIENTS
            1: Preheat the oven to 350°F
            2: Mix the ingredients in a large bowl
            3: Pour the mixture into a baking dish
            4: Bake for 25 minutes
            """,
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
          RegExp targetRegExp = RegExp(r't:(\d+)');
          RegExp sourceRegExp = RegExp(r's:(\d+)');
          RegExp difficultyRegExp = RegExp(r'd:(\w+)');

          time = targetRegExp.firstMatch(responseText)?.group(1) ?? '';
          servings = sourceRegExp.firstMatch(responseText)?.group(1) ?? '';
          difficulty = difficultyRegExp.firstMatch(responseText)?.group(1) ?? '';
          ingredients = responseText.split('ENDINGREDIENTS')[0].split('END')[1];
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
    print(responseText);
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
        body: isLoading ? const LinearProgressIndicator() : Column(
          children: [
            title(),
            const SizedBox(height: 20),
            params(),
            const SizedBox(height: 10),
            ingredientsAndPhoto(),
            const SizedBox(height: 10),
            recipe(),
            const SizedBox(height: 10),
            youtube(),
          ],
        ),
      ),
    );
  }

  Widget title(){
    return Center (
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            flex: 7, // 7 parts of the space
            child: Text(
              mealTitle.substring(mealTitle.indexOf(".") + 2),
              style: const TextStyle(fontSize: 22, color: Colors.black, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),
          const Flexible(
            flex: 1, // 1 part of the space
            child: Icon(Icons.favorite_border_outlined),
          ),
        ],
      ),
    );
  }

  Widget recipe() {
    return Expanded(
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Recipe',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Text(
                responseText.substring(responseText.indexOf("ENDINGREDIENTS") + 14).trim(),
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget params(){
    return Container(
      height: 70, // this can be adjusted to control the height ratio
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          children: [
            const SizedBox(width: 15),
            const Icon(Icons.access_time_outlined),
            Text(
              '  $time min',
              style: const TextStyle(fontSize: 17),
            ),
            const SizedBox(width: 15),
            const Icon(Icons.leaderboard_outlined),
            Text(
              '  $difficulty',
              style: const TextStyle(fontSize: 17),
            ),
            const SizedBox(width: 15),
            const Icon(Icons.food_bank_outlined),
            Text(
              '  $servings servings',
              style: const TextStyle(fontSize: 17),
            ),
        ],
        ),
      ),
    );
  }

  Widget ingredientsAndPhoto() {
    return Row(
      children: [
        SizedBox(
          height: 190,
          width: 230,
          child: Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(2),
              child: Column(
                children: [
                  const Text(
                    'Ingredients',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ingredients.substring(1),
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          height: 190,
          width: 150,
          child: Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: Image.network(
                youtubeImgLink!,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget youtube(){
    return Container(
      height: 50,
      width: 380,
      child:
          Card(
          elevation: 4,
          child: GestureDetector(
            child: const Center(
            child: Text(
              "Useful video",
              style: TextStyle(
                color: Colors.indigo,
                fontSize: 20,
              ),
            ),
          ),
            onTap: () => launchUrl(Uri.parse(youtubeLink!)),
          ),
        ),
    );
  }
}
