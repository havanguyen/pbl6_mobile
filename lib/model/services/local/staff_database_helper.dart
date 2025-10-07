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
        isMale INTEGER ,
        dateOfBirth TEXT,
        createdAt TEXT,
        updatedAt TEXT ,
        deletedAt TEXT
      )
    ''');
  }

  Future<void> insertStaffs(List<Staff> staffs) async {
    if (staffs.isEmpty) {
      print('No staffs to insert');
      return;
    }

    final db = await database;
    final batch = db.batch();

    for (var staff in staffs) {
      try {
        print('Inserting staff: ${staff.id}, dateOfBirth: ${staff.dateOfBirth}, deletedAt: ${staff.deletedAt}');
        batch.insert(
          _table,
          {
            'id': staff.id,
            'email': staff.email,
            'fullName': staff.fullName,
            'phone': staff.phone,
            'role': staff.role,
            'isMale': staff.isMale == null ? null : (staff.isMale! ? 1 : 0),
            'dateOfBirth': staff.dateOfBirth?.toIso8601String() ?? null ,
            'createdAt': staff.createdAt?.toIso8601String() ?? null ,
            'updatedAt': staff.updatedAt?.toIso8601String() ?? null,
            'deletedAt': staff.deletedAt?.toIso8601String() ?? null,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (e) {
        print('Error inserting staff ${staff.id}: $e');
      }
    }

    try {
      await batch.commit(noResult: true);
      print('Inserted ${staffs.length} staffs into database');
    } catch (e) {
      print('Batch commit error: $e');
    }
  }

  Future<List<Staff>> getStaffs({
    String? search,
    bool? isMale,
    String? email,
    String? createdFrom,
    String? createdTo,
    String? sortBy,
    String? sortOrder,
    int page = 1,
    int limit = 10,
  }) async {
    final db = await database;
    try {
      List<String> whereClauses = [];
      List<dynamic> whereArgs = [];
      whereClauses.add('role = ?');
      whereArgs.add('ADMIN');

      if (search != null && search.isNotEmpty) {
        whereClauses.add('(fullName LIKE ? OR email LIKE ?)');
        whereArgs.add('%$search%');
        whereArgs.add('%$search%');
      }
      if (isMale != null) {
        whereClauses.add('isMale = ?');
        whereArgs.add(isMale ? 1 : 0);
      }
      if (email != null && email.isNotEmpty) {
        whereClauses.add('email = ?');
        whereArgs.add(email);
      }

      if (createdFrom != null && createdFrom.isNotEmpty) {
        whereClauses.add('createdAt >= ?');
        whereArgs.add(createdFrom);
      }
      if (createdTo != null && createdTo.isNotEmpty) {
        whereClauses.add('createdAt <= ?');
        whereArgs.add(createdTo);
      }

      final offset = (page - 1) * limit;

      String orderBy = '';
      if (sortBy != null && sortBy.isNotEmpty) {
        orderBy = '$sortBy ${sortOrder ?? 'ASC'}';
      } else {
        orderBy = 'createdAt DESC';
      }
      String query = 'SELECT * FROM $_table';
      if (whereClauses.isNotEmpty) {
        query += ' WHERE ${whereClauses.join(' AND ')}';
      }
      query += ' ORDER BY $orderBy LIMIT ? OFFSET ?';
      whereArgs.add(limit);
      whereArgs.add(offset);

      print('Executing query: $query with args: $whereArgs');

      final List<Map<String, dynamic>> maps = await db.rawQuery(query, whereArgs);
      print('Retrieved ${maps.length} staffs from database');

      return maps.map((map) {
        try {
          return Staff(
            id: map['id'] as String,
            email: map['email'] as String,
            fullName: map['fullName'] as String,
            phone: map['phone'] as String?,
            role: map['role'] as String,
            isMale: map['isMale'] == null || map['isMale'] is! int ? null : map['isMale'] == 1,
            dateOfBirth: map['dateOfBirth'] == null || map['dateOfBirth'] == '' ? null : DateTime.tryParse(map['dateOfBirth'] as String),
            createdAt: map['createdAt'] == null || map['createdAt'] == '' ? null : DateTime.tryParse(map['createdAt'] as String),
            updatedAt: map['updatedAt'] == null || map['updatedAt'] == '' ? null : DateTime.tryParse(map['updatedAt'] as String),
            deletedAt: map['deletedAt'] == null || map['deletedAt'] == '' ? null : DateTime.tryParse(map['deletedAt'] as String),
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