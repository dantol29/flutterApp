import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class mealDescriptionScreen extends StatefulWidget {
  final String ingredient;

  const mealDescriptionScreen({Key? key, required this.ingredient}) : super(key: key);

  @override
  _mealDescriptionScreenState createState() => _mealDescriptionScreenState(ingredient: ingredient);
}

class _mealDescriptionScreenState extends State<mealDescriptionScreen> {


  _mealDescriptionScreenState({required this.ingredient});

  String ingredient;
  String? youtubeLink;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    callFastAPI(ingredient);
  }

  Future<void> callFastAPI(String? query) async {
    isLoading = true;
    final response =  await http.get(Uri.parse('https://fastapi-production-b71a.up.railway.app/video?query=$query'));
    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      setState(() {
        youtubeLink = data['video_link'];
        isLoading = false;
      });
      debugPrint("Response from Python: ${data['video_link']}");
    } else {
      debugPrint("Failed to call Python script: ${response.statusCode}");
    }
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
              const SizedBox(height: 20),
              GestureDetector(
                child:  isLoading ? const CircularProgressIndicator() : Text(
                  youtubeLink ?? "Loading...",
                  style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                ),
                onTap: () => launchUrl(Uri.parse(youtubeLink!),
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }


}