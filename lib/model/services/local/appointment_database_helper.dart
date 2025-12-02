import 'dart:convert';
import 'package:pbl6mobile/model/entities/appointment_data.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppointmentDatabaseHelper {
  static const _databaseName = "appointments.db";
  static const _databaseVersion = 1;
  static const _table = "appointments_cache";

  AppointmentDatabaseHelper._privateConstructor();
  static final AppointmentDatabaseHelper instance =
      AppointmentDatabaseHelper._privateConstructor();

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
        dataJson TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL
      )
    ''');
  }

  Future<void> insertAppointments(List<AppointmentData> appointments) async {
    if (appointments.isEmpty) return;
    final db = await database;
    final batch = db.batch();

    for (var app in appointments) {
      batch.insert(_table, {
        'id': app.id,
        'dataJson': jsonEncode(app.toJson()),
        'startTime': app.appointmentStartTime.toIso8601String(),
        'endTime': app.appointmentEndTime.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<AppointmentData>> getAppointments({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final db = await database;
    try {
      // We want appointments that overlap with the requested range [fromDate, toDate]
      // Overlap condition: (StartA <= EndB) and (EndA >= StartB)
      // Here: (app.startTime <= toDate) AND (app.endTime >= fromDate)

      final startStr = fromDate.toIso8601String();
      final endStr = toDate.toIso8601String();

      final maps = await db.query(
        _table,
        where: 'startTime <= ? AND endTime >= ?',
        whereArgs: [endStr, startStr],
      );

      return maps.map((map) {
        final jsonMap =
            jsonDecode(map['dataJson'] as String) as Map<String, dynamic>;
        return AppointmentData.fromJson(jsonMap);
      }).toList();
    } catch (e) {
      print("Error getting appointments from database: $e");
      return [];
    }
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete(_table);
  }
}
