import 'package:flutter/material.dart';
import 'package:hello_world/sql_helper.dart';

void main() {
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
  List<Map<String, dynamic>> _journals = [];
  List<Map<String, dynamic>> _meals = [];

  void _refreshMeals() async {
    final data = await SQLHelper.getMeals();
    setState(() {
      _meals = data;
    });
  }

  void _refreshJournals() async {
    final data = await SQLHelper.getItems();
    setState(() {
      _journals = data;
    });
  }

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Future<void> _addMeal() async {
    await SQLHelper.createMeal(
        _titleController.text, _descriptionController.text);
    _refreshMeals();
  }

  Future <void> _updateMeal(int id) async {
    await SQLHelper.updateMeal(
        id, _titleController.text, _descriptionController.text);
    _refreshMeals();
  }

  Future <void> _deleteMeal(int id) async {
    await SQLHelper.deleteMeal(id);
    _refreshMeals();
  }

  Future <void> _compareItem(int id) async {
    int i = 0;
    int len = _journals.length;
    print("$len");
    while (i < len) {
      if (_journals[i]['title'] == _journals[id]['title']) {
        debugPrint("$i found");
      }
      i++;
    }
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

  void _showForm(int? id, int is_meal) async {
    if (id != null && is_meal == 0) {
      final existingJournal = _journals.firstWhere((element) =>
      element['id'] == id);
      _titleController.text = existingJournal['title'];
      _descriptionController.text = existingJournal['description'];
    }
    if (id != null && is_meal == 1) {
      final existingJournal = _meals.firstWhere((element) =>
      element['id'] == id);
      _titleController.text = existingJournal['meal_name'];
      _descriptionController.text = existingJournal['ingredient'];
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
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                          hintText: 'Description'),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    ElevatedButton(
                        onPressed: () async {
                          if (id == null && is_meal == 0) {
                            await _addItem();
                          }
                          if (id == null && is_meal == 1) {
                            await _addMeal();
                          }
                          if (id != null && is_meal == 0) {
                            await _updateItem(id);
                          }
                          if (id != null && is_meal == 1) {
                            await _updateMeal(id);
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

  @override
  void initState() {
    super.initState();
    _refreshJournals();
    _refreshMeals();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text("SQL"),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.note)),
              Tab(icon: Icon(Icons.food_bank)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView.builder(
              itemCount: _journals.length,
              itemBuilder: (context, index) => Card(
                color: Colors.orange[200],
                margin: const EdgeInsets.all(15),
                child: ListTile(
                  title: Text(_journals[index]['title']),
                  subtitle: Text(_journals[index]['description']),
                  trailing: SizedBox(
                    width: 100,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () =>
                              _showForm(_journals[index]['id'], 0),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () =>
                              _deleteItem(_journals[index]['id']),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Second Tab View
            ListView.builder(
              itemCount: _meals.length,
              itemBuilder: (context, index) => Card(
                color: Colors.green[200],
                margin: const EdgeInsets.all(15),
                child: ListTile(
                  title: Text(_meals[index]['meal_name']),
                  subtitle: Text(_meals[index]['ingredient']),
                  trailing: SizedBox(
                    width: 100,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () =>
                              _showForm(_meals[index]['id'], 1),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () =>
                              _deleteMeal(_meals[index]['id']),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Get the current tab index

            // Show the form based on the current tab index
            _showForm(null, 0);
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}