import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:pbl6mobile/model/entities/staff.dart';

class StaffDatabaseHelper {
  static const _databaseName = "staffs.db";
  static const _databaseVersion = 1;
  static const _table = "staffs";

  StaffDatabaseHelper._privateConstructor();
  static final StaffDatabaseHelper instance =
  StaffDatabaseHelper._privateConstructor();

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
        isMale INTEGER,
        dateOfBirth TEXT,
        createdAt TEXT,
        updatedAt TEXT,
        deletedAt TEXT
      )
    ''');
  }

  Future<void> insertStaffs(List<Staff> staffs) async {
    if (staffs.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (var staff in staffs) {
      final Map<String, dynamic> staffMap = staff.toJson();

      if (staffMap.containsKey('isMale') && staffMap['isMale'] != null) {
        staffMap['isMale'] = staffMap['isMale'] == true ? 1 : 0;
      }

      batch.insert(
        _table,
        staffMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    print('Đã chèn/cập nhật ${staffs.length} nhân viên vào database');
  }

  Future<List<Staff>> getStaffs({
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
        orderByClause = '$sortBy ${sortOrder ?? 'ASC'}';
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

      print('Đã lấy ${maps.length} nhân viên từ database cho vai trò $role');
      return maps.map((map) {
        final newMap = Map<String, dynamic>.from(map);
        if (newMap.containsKey('isMale') && newMap['isMale'] != null) {
          newMap['isMale'] = newMap['isMale'] == 1;
        }
        return Staff.fromJson(newMap);
      }).toList();

    } catch (e) {
      print('Lỗi khi lấy nhân viên từ database: $e');
      return [];
    }
  }

  Future<void> clearStaffs({required String role}) async {
    final db = await database;
    await db.delete(_table, where: 'role = ?', whereArgs: [role]);
    print('Đã xóa nhân viên vai trò $role khỏi database');
  }

  Future<void> deleteStaff(String id) async {
    final db = await database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
    print('Đã xóa nhân viên có id $id khỏi database');
  }
}