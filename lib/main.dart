import 'package:flutter/material.dart';
import 'package:hello_world/sql_helper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'meals.dart';


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
  int _currentIndex = 0;
  bool isSpicy = false;
  bool isVegan = false;

  // Method to navigate to AnotherScreen
  void _navigateToAnotherScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnotherScreen(ingredientList: _ingredients),),
    );
  }

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

  String capitalizeFirstLetter(String input) {
    return input.isNotEmpty ? input[0].toUpperCase() + input.substring(1) : input;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme
        .of(context)
        .colorScheme;
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
                buttons(),
              ],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.deepPurpleAccent,
          onPressed: () async {
            _showForm(null);
          },
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget buttons() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0), // Add bottom padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              _navigateToAnotherScreen();
            },
            style: ElevatedButton.styleFrom(
              primary: Colors.deepPurpleAccent, // Adjust the button color
              onPrimary: Colors.white, // Change the text color
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20), // Adjust padding values
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), // Add rounded corners
              ),
              elevation: 8, // Add elevation for a lifted appearance
            ),
            child: const Text('Discover Magic'),
          ),
          // Image.network(
          //   '$img',
          //   width: 120,
          //   height: 120,
          // ),
        ],
      ),
    );
  }

  Widget settings() {
    double sliderDiscreteValue = 10;
    return Row(
      children: [
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
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        spacing: 15.0,
        runSpacing: 15.0,
        children: _ingredients.map((ingredient) {
          return Card(
            elevation: 4.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: SizedBox(
              width: 350,
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      capitalizeFirstLetter(ingredient['title']),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
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