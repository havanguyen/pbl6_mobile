import 'package:pbl6mobile/model/entities/info_section.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:pbl6mobile/model/entities/specialty.dart';

class SpecialtyDatabaseHelper {
  static const _databaseName = "specialties.db";
  static const _databaseVersion = 3;
  static const _specialtiesTable = "specialties";
  static const _infoSectionsTable = "info_sections";

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
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE $_infoSectionsTable (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          content TEXT NOT NULL,
          specialtyId TEXT NOT NULL,
          createdAt TEXT,
          updatedAt TEXT
        )
      ''');
    }
    if (oldVersion < 3) {
      // Check if column exists before adding (optional but safe) or just add
      // SQLite 'ADD COLUMN' is safe if check not strictly needed in simple upgrade path,
      // but sqflite doesn't support 'IF NOT EXISTS' for columns directly in all versions.
      // Simply executing add column.
      try {
        await db.execute(
          'ALTER TABLE $_specialtiesTable ADD COLUMN iconUrl TEXT',
        );
      } catch (e) {
        // Column might already exist if dev re-ran code
        print("Error adding column iconUrl: $e");
      }
    }
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE $_specialtiesTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        iconUrl TEXT,
        infoSectionsCount INTEGER NOT NULL,
        createdAt TEXT,
        updatedAt TEXT,
        deletedAt TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE $_infoSectionsTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        content TEXT NOT NULL,
        specialtyId TEXT NOT NULL,
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');
  }

  // --- Specialty Methods ---

  Future<void> insertSpecialties(List<Specialty> specialties) async {
    if (specialties.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (var specialty in specialties) {
      batch.insert(
        _specialtiesTable,
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
        _specialtiesTable,
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
    await db.delete(_specialtiesTable);
    await db.delete(_infoSectionsTable); // Xóa luôn info sections
  }

  Future<void> deleteSpecialty(String id) async {
    final db = await database;
    await db.delete(_specialtiesTable, where: 'id = ?', whereArgs: [id]);
    await db.delete(
      _infoSectionsTable,
      where: 'specialtyId = ?',
      whereArgs: [id],
    );
  }

  // --- InfoSection Methods ---

  Future<void> insertInfoSections(List<InfoSection> sections) async {
    if (sections.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (var section in sections) {
      batch.insert(
        _infoSectionsTable,
        section.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<InfoSection>> getInfoSections(String specialtyId) async {
    final db = await database;
    try {
      final maps = await db.query(
        _infoSectionsTable,
        where: 'specialtyId = ?',
        whereArgs: [specialtyId],
        orderBy: 'createdAt DESC',
      );
      return maps.map((map) => InfoSection.fromJson(map)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> clearInfoSections(String specialtyId) async {
    final db = await database;
    await db.delete(
      _infoSectionsTable,
      where: 'specialtyId = ?',
      whereArgs: [specialtyId],
    );
  }
}
