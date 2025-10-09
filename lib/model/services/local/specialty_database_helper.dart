import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:pbl6mobile/model/entities/specialty.dart';

class SpecialtyDatabaseHelper {
  static const _databaseName = "specialties.db";
  static const _databaseVersion = 1;
  static const _table = "specialties";

  SpecialtyDatabaseHelper._privateConstructor();
  static final SpecialtyDatabaseHelper instance =
  SpecialtyDatabaseHelper._privateConstructor();

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
        description TEXT,
        infoSectionsCount INTEGER NOT NULL,
        createdAt TEXT,
        updatedAt TEXT,
        deletedAt TEXT
      )
    ''');
  }

  Future<void> insertSpecialties(List<Specialty> specialties) async {
    if (specialties.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (var specialty in specialties) {
      batch.insert(
        _table,
        specialty.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Specialty>> getSpecialties({
    String? search,
    int page = 1,
    int limit = 10,
    String? sortBy,
    String? sortOrder,
  }) async {
    final db = await database;
    try {
      String? whereClause;
      List<dynamic>? whereArgs;

      if (search != null && search.isNotEmpty) {
        whereClause = 'name LIKE ?';
        whereArgs = ['%$search%'];
      }

      String? orderByClause;
      if (sortBy != null && sortBy.isNotEmpty) {
        orderByClause = '$sortBy ${sortOrder ?? 'ASC'}';
      } else {
        orderByClause = 'createdAt DESC';
      }

      final offset = (page - 1) * limit;
      final maps = await db.query(
        _table,
        where: whereClause,
        whereArgs: whereArgs,
        limit: limit,
        offset: offset,
        orderBy: orderByClause,
      );

      return maps.map((map) => Specialty.fromJson(map)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> clearSpecialties() async {
    final db = await database;
    await db.delete(_table);
  }

  Future<void> deleteSpecialty(String id) async {
    final db = await database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}