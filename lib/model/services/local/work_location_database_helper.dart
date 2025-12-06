import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../entities/work_location.dart';

class WorkLocationDatabaseHelper {
  static const _databaseName = "work_locations.db";
  static const _databaseVersion = 2;
  static const _table = "work_locations";

  WorkLocationDatabaseHelper._privateConstructor();
  static final WorkLocationDatabaseHelper instance =
      WorkLocationDatabaseHelper._privateConstructor();

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
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_table (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT,
        phone TEXT,
        timezone TEXT,
        googleMapUrl TEXT,
        isActive INTEGER,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Recreate table to apply nullability changes and add new column
      await db.execute('DROP TABLE IF EXISTS $_table');
      await _onCreate(db, newVersion);
    }
  }

  Future<void> insertLocations(List<WorkLocation> locations) async {
    final db = await database;
    final batch = db.batch();
    for (var location in locations) {
      final data = location.toJson();
      data['isActive'] = (location.isActive ? 1 : 0);
      batch.insert(_table, data, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<WorkLocation>> getLocations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_table);
    return maps.map((map) {
      final newMap = Map<String, dynamic>.from(map);
      if (newMap.containsKey('isActive') && newMap['isActive'] != null) {
        newMap['isActive'] = newMap['isActive'] == 1;
      }
      return WorkLocation.fromJson(newMap);
    }).toList();
  }

  Future<void> clearLocations() async {
    final db = await database;
    await db.delete(_table);
  }
}
