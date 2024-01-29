import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sql;

class SQLHelper
{

  static Future<void> deleteMeal(int id) async {
    final db =  await SQLHelper.db();
    try {
      await db.delete("meals", where: "id = ?", whereArgs: [id]);
    } catch (err) {
      debugPrint("Something went wrong when deleting a meal: $err");
    }
  }

  static Future<int> updateMeal(int id, String title, String? description) async{
    final db = await SQLHelper.db();
    final data = {
      'meal_name': title,
      'ingredient': description
    };
    final result = await db.update('meals', data, where: "id = ?", whereArgs: [id]);
    return result;
  }

  static Future<int> createMeal(String title, String? ingredient) async{
    final db = await SQLHelper.db();
    final data = {'meal_name': title, 'ingredient': ingredient};
    final id = await db.insert('meals', data,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return id;
  }

  static Future<List<Map<String, dynamic>>> getMeals() async {
    final db = await SQLHelper.db();
    return db.query('meals', orderBy: "id");
  }

  static Future<void> createTables(sql.Database database) async {
    await database.execute("""CREATE TABLE items (
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    title TEXT,
    description TEXT,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
  );
  """);

    await database.execute("""CREATE TABLE meals (
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    meal_name TEXT,
    ingredient TEXT
  );
  """);
  }

  static Future<sql.Database> db() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    String path = documentsDirectory.path + "sqflite2.db"; // Use join to concatenate path correctly
    return sql.openDatabase(
      path, // Use the correct path variable here
      version: 1,
      onCreate: (sql.Database database, int version) async {
        await createTables(database);
      },
    );
  }

  static Future<int> createItem(String title, String? description) async{
    final db = await SQLHelper.db();
    final data = {'title': title, 'description': description};
    final id = await db.insert('items', data,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return id;
  }

  static Future<List<Map<String, dynamic>>> getItems() async {
    final db = await SQLHelper.db();
    return db.query('items', orderBy: "id");
  }

  static Future<List<Map<String, dynamic>>> getItem(int id) async {
    final db = await SQLHelper.db();
    return db.query('items', where: "id = ?", whereArgs: [id], limit: 1);
  }

  static Future<int> updateItem(int id, String title, String? description) async{
    final db = await SQLHelper.db();
    final data = {
      'title': title,
      'description': description,
      'createdAt': DateTime.now().toString()
    };
    final result = await db.update('items', data, where: "id = ?", whereArgs: [id]);
    return result;
  }

  static Future<void> deleteItem(int id) async {
    final db =  await SQLHelper.db();
    try {
      await db.delete("items", where: "id = ?", whereArgs: [id]);
    } catch (err) {
      debugPrint("Something went wrong when deleting an item: $err");
    }
  }
}