import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hello_world/sql_helper.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, dynamic>> _ingredients = [];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String responseText = '';
  bool isSpicy = false;
  bool isVegan = false;
  bool isLoading = false;
  int _currentIndex = 0;

  void _refreshJournals() async {
    final data = await SQLHelper.getItems();
    setState(() {
      _ingredients = data;
    });
  }

  Future <void> _deleteItem(int id) async {
    await SQLHelper.deleteItem(id);
    _refreshJournals();
  }

  Future <void> _updateItem(int id) async {
    await SQLHelper.updateItem(
        id, _titleController.text, _descriptionController.text);
    _refreshJournals();
  }

  Future<void> _addItem() async {
    await SQLHelper.createItem(
        _titleController.text, _descriptionController.text);
    _refreshJournals();
  }

  List<String> getTitles(List<Map<String, dynamic>> journals) {
    return journals.map((journal) => journal['title'] as String).toList();
  }
  
  void completionFun() async {
    setState(() {
      isLoading = true; // Set loading state to true
    });
    print(getTitles(_ingredients));
    //const apiKey = "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";
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${dotenv.env['token']}'
    };
    final body = json.encode(
      {
        "max_tokens": 60,
        "model": "gpt-3.5-turbo",
        "n": 1,
        "temperature": 1,
        "top_p": 1,
        "frequency_penalty": 0,
        "presence_penalty": 0,
        "messages": [
          {
            "role": "system",
            "content": """Given the ingredients: ${getTitles(_ingredients)}, suggest some meals I can cook. If it is not enouqh, say so. 
            Write only the name of the meal and brief description that has no more than 7 words. Use ONLY provided ingredients!
            Some flags for you: is spicy - $isSpicy, is vegan - $isVegan
            Maximum 3 meals!
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
        setState(() {
          responseText = result.toString();
          responseText = responseText.substring(responseText.indexOf("1"));
        });
        print(result);
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

  void _showForm(int? id) async {
    if (id != null) {
      final existingJournal = _ingredients.firstWhere((element) =>
      element['id'] == id);
      _titleController.text = existingJournal['title'];
      _descriptionController.text = existingJournal['description'];
    }
    showModalBottomSheet(
        context: context,
        elevation: 5,
        isScrollControlled: true,
        builder: (_) =>
            Container(
              padding: EdgeInsets.only(
                top: 15,
                left: 15,
                right: 15,
                bottom: MediaQuery
                    .of(context)
                    .viewInsets
                    .bottom + 120,
              ),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(hintText: 'Title')
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    ElevatedButton(
                        onPressed: () async {
                          if (id == null) {
                            await _addItem();
                          }
                          if (id != null) {
                            await _updateItem(id);
                          }
                          _titleController.text = '';
                          _descriptionController.text = '';
                          Navigator.of(context).pop();
                        },
                        child: Text(id == null ? 'Create New' : 'Update')),
                  ]
              ),
            ));
  }

  void _showSettings() async {
    showModalBottomSheet(
        context: context,
        elevation: 5,
        isScrollControlled: true,
        builder: (_) =>
            Container(
              padding: EdgeInsets.only(
                top: 10,
                left: 10,
                right: 10,
                bottom: MediaQuery
                    .of(context)
                    .viewInsets
                    .bottom + 20,
              ),
              child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Checkbox(
                      checkColor: Colors.white,
                      value: isSpicy,
                      onChanged: (bool? value) {
                        setState(() {
                          isSpicy = value!;
                        });
                      },
                    ),
                    const Text('Spicy'),
                    Checkbox(
                      checkColor: Colors.white,
                      value: isVegan,
                      onChanged: (bool? value) {
                        setState(() {
                          isVegan = value!;
                        });
                      },
                    ),
                    const Text('Vegan'),
                    Checkbox(
                      checkColor: Colors.white,
                      value: isVegan,
                      onChanged: (bool? value) {
                        setState(() {
                          isVegan = value!;
                        });
                      },
                    ),
                    const Text('Option'),
                    Checkbox(
                      checkColor: Colors.white,
                      value: isVegan,
                      onChanged: (bool? value) {
                        setState(() {
                          isVegan = value!;
                        });
                      },
                    ),
                    const Text('Option'),
                  ]
              ),
            ));
  }

  @override
  void initState() {
    super.initState();
    _refreshJournals();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return MaterialApp(
      home: Scaffold(
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          backgroundColor: colorScheme.surface,
          selectedItemColor: Colors.purple[700],
          unselectedItemColor: colorScheme.onSurface.withOpacity(.60),
          onTap: (value) {
            setState(() => _currentIndex = value);
          },
          items: const [
            BottomNavigationBarItem(
              label: 'Ingredients',
              icon: Icon(Icons.dinner_dining_outlined),
            ),
            BottomNavigationBarItem(
              label: 'Daily Meals',
              icon: Icon(Icons.fastfood_outlined),
            ),
            BottomNavigationBarItem(
              label: 'Favorites',
              icon: Icon(Icons.favorite_border_outlined),
            ),
            BottomNavigationBarItem(
              label: 'Profile',
              icon: Icon(Icons.person_2_outlined),
            ),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              children: [
                const SizedBox(height: 45),
                settings(),
                const SizedBox(height: 20),
                Expanded(
                  child: buildListView(),
                ),
                isLoading ? const CircularProgressIndicator() : Text(
                  responseText,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                buttons(),
              ],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.purple[600],
          onPressed: () => _showForm(null),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget buttons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () => completionFun(),
          style: ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 30)),
          child: const Text('Magic'),
        ),
        const SizedBox(width: 10), // Adjust the spacing between buttons
        ElevatedButton(
          onPressed: () {
            setState(() {
              responseText = ' ';
            });
          },
          style: ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 30)),
          child: const Text('Clear'),
        ),
      ],
    );
  }
  Widget settings(){
    double sliderDiscreteValue = 10;
    return  Row(
      children:[
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => _showSettings(),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Slider(
            value: sliderDiscreteValue,
            min: 0,
            max: 100,
            divisions: 5,
            label: sliderDiscreteValue.round().toString(),
            onChanged: (value) {
              setState(() {
                sliderDiscreteValue = value;
              });
            },
          ),
        ),
      ],
    );
  }
  Widget buildListView() {
    return SingleChildScrollView(
      child: Wrap(
        spacing: 15.0, // Adjust the spacing between items as needed
        runSpacing: 15.0, // Adjust the run spacing as needed
        children: _ingredients.map((ingredient) {
          return Card(
            color: Colors.orange[200],
            child: SizedBox(
              width: 350, // Adjust the width of each card as needed
              child: ListTile(
                title: Text(ingredient['title']),
                trailing: SizedBox(
                  width: 100,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showForm(ingredient['id']),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteItem(ingredient['id']),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Background Image
// Image.asset(
//   'assets/imag.png', // Replace with your image asset path
//   fit: BoxFit.cover,
//   width: double.infinity,
//   height: double.infinity,
// ),