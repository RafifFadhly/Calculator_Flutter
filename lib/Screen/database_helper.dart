import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'calculator_history.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'calculator_history.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE history(id INTEGER PRIMARY KEY AUTOINCREMENT, expression TEXT, result TEXT)',
        );
      },
    );
  }

  Future<void> insertHistory(CalculatorHistory history) async {
    final db = await database;
    await db.insert(
      'history',
      history.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CalculatorHistory>> getHistory() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('history');

    return List.generate(maps.length, (i) {
      return CalculatorHistory(
        id: maps[i]['id'],
        expression: maps[i]['expression'],
        result: maps[i]['result'],
      );
    });
  }

  Future<void> deleteHistory(int id) async {
    final db = await database;
    await db.delete(
      'history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAllHistory() async {
    final db = await database;
    await db.delete('history');
  }
}
