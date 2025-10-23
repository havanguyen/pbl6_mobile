import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:pbl6mobile/model/entities/doctor.dart';

class DoctorDatabaseHelper {
  static const _databaseName = "doctors.db";
  static const _databaseVersion = 2;
  static const _table = "doctors";

  DoctorDatabaseHelper._privateConstructor();
  static final DoctorDatabaseHelper instance =
  DoctorDatabaseHelper._privateConstructor();

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
    await _createTableV1(db);
    await _onUpgrade(db, 1, version);
  }

  Future<void> _createTableV1(Database db) async {
    await db.execute('''
      CREATE TABLE $_table (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        fullName TEXT NOT NULL,
        phone TEXT,
        role TEXT NOT NULL,
        isMale INTEGER,
        dateOfBirth TEXT,
        createdAt TEXT,
        updatedAt TEXT,
        deletedAt TEXT
      )
    ''');
  }
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE $_table ADD COLUMN avatarUrl TEXT');
      print("Database upgraded: Added avatarUrl column to doctors table.");
    }
  }

  Future<void> insertDoctors(List<Doctor> doctors) async {
    if (doctors.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (var doctor in doctors) {
      final Map<String, dynamic> doctorMap = doctor.toJson();

      if (doctorMap.containsKey('isMale') && doctorMap['isMale'] != null) {
        doctorMap['isMale'] = doctorMap['isMale'] == true ? 1 : 0;
      }

      batch.insert(
        _table,
        doctorMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Doctor>> getDoctors({
    required String role,
    String? search,
    bool? isMale,
    int page = 1,
    int limit = 10,
    String? sortBy,
    String? sortOrder,
  }) async {
    final db = await database;
    try {
      List<String> whereClauses = ['role = ?'];
      List<dynamic> whereArgs = [role];

      if (search != null && search.isNotEmpty) {
        whereClauses.add('(fullName LIKE ? OR email LIKE ?)');
        whereArgs.add('%$search%');
        whereArgs.add('%$search%');
      }
      if (isMale != null) {
        whereClauses.add('isMale = ?');
        whereArgs.add(isMale ? 1 : 0);
      }

      String? orderByClause;
      if (sortBy != null && sortBy.isNotEmpty) {
        final columns = ['id', 'email', 'fullName', 'createdAt', 'updatedAt'];
        if (columns.contains(sortBy)) {
          orderByClause = '$sortBy ${sortOrder ?? 'ASC'}';
        } else {
          orderByClause = 'createdAt DESC';
        }
      } else {
        orderByClause = 'createdAt DESC';
      }


      final offset = (page - 1) * limit;
      final maps = await db.query(
        _table,
        where: whereClauses.join(' AND '),
        whereArgs: whereArgs,
        limit: limit,
        offset: offset,
        orderBy: orderByClause,
      );

      return maps.map((map) {
        final newMap = Map<String, dynamic>.from(map);
        if (newMap.containsKey('isMale') && newMap['isMale'] != null) {
          newMap['isMale'] = newMap['isMale'] == 1;
        }
        return Doctor.fromJson(newMap);
      }).toList();
    } catch (e) {
      print("Error getting doctors from database: $e");
      return [];
    }
  }

  Future<void> clearDoctors({required String role}) async {
    final db = await database;
    await db.delete(_table, where: 'role = ?', whereArgs: [role]);
  }

  Future<void> deleteDoctor(String id) async {
    final db = await database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}