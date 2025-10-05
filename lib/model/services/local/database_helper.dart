import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../entities/work_location.dart';

class DatabaseHelper {
  static const _databaseName = "work_locations.db";
  static const _databaseVersion = 1;
  static const _table = "work_locations";

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_table (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        phone TEXT NOT NULL,
        timezone TEXT NOT NULL,
        isActive INTEGER,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> insertLocations(List<WorkLocation> locations) async {
    final db = await database;
    final batch = db.batch();
    for (var location in locations) {
      final data = location.toJson();
      data['isActive'] = (location.isActive ? 1 : 0);
      batch.insert(
        _table,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }


  Future<List<WorkLocation>> getLocations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_table);
    return List.generate(maps.length, (i) => WorkLocation.fromJson(maps[i]));
  }

  Future<void> clearLocations() async {
    final db = await database;
    await db.delete(_table);
  }
}