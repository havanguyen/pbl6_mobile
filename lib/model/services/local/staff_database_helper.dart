import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:pbl6mobile/model/entities/staff.dart';

class StaffDatabaseHelper {
  static const _databaseName = "staffs.db";
  static const _databaseVersion = 1;
  static const _table = "staffs";

  StaffDatabaseHelper._privateConstructor();
  static final StaffDatabaseHelper instance = StaffDatabaseHelper._privateConstructor();

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
        email TEXT NOT NULL,
        fullName TEXT NOT NULL,
        phone TEXT,
        role TEXT NOT NULL,
        isMale INTEGER NOT NULL,
        dateOfBirth TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> insertStaffs(List<Staff> staffs) async {
    if (staffs.isEmpty) return;

    final db = await database;
    final batch = db.batch();

    for (var staff in staffs) {
      try {
        batch.insert(
          _table,
          {
            'id': staff.id,
            'email': staff.email,
            'fullName': staff.fullName,
            'phone': staff.phone,
            'role': staff.role,
            'isMale': staff.isMale ? 1 : 0,
            'dateOfBirth': staff.dateOfBirth.toIso8601String(),
            'createdAt': staff.createdAt.toIso8601String(),
            'updatedAt': staff.updatedAt.toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (e) {
        print('Error inserting staff ${staff.id}: $e');
      }
    }

    await batch.commit(noResult: true);
    print('Inserted ${staffs.length} staffs into database');
  }

  Future<List<Staff>> getStaffs() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(_table);
      print('Retrieved ${maps.length} staffs from database');

      return maps.map((map) {
        try {
          return Staff(
            id: map['id'] as String,
            email: map['email'] as String,
            fullName: map['fullName'] as String,
            phone: map['phone'] as String?,
            role: map['role'] as String,
            isMale: (map['isMale'] as int) == 1,
            dateOfBirth: DateTime.parse(map['dateOfBirth'] as String),
            createdAt: DateTime.parse(map['createdAt'] as String),
            updatedAt: DateTime.parse(map['updatedAt'] as String),
          );
        } catch (e) {
          print('Error parsing staff from database: $e');
          print('Problematic data: $map');
          return null;
        }
      }).where((staff) => staff != null).cast<Staff>().toList();
    } catch (e) {
      print('Error getting staffs from database: $e');
      return [];
    }
  }

  Future<void> clearStaffs() async {
    final db = await database;
    await db.delete(_table);
    print('Cleared all staffs from database');
  }

  // Thêm method để debug
  Future<void> debugDatabase() async {
    final db = await database;
    final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'"
    );
    print('Database tables: $tables');

    final staffCount = await db.rawQuery('SELECT COUNT(*) as count FROM $_table');
    print('Staff count in database: $staffCount');
  }
}