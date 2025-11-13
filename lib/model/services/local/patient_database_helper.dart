import 'package:pbl6mobile/model/entities/patient.dart';
import 'package:pbl6mobile/model/services/local/work_location_database_helper.dart';
import 'package:sqflite/sqflite.dart';

class PatientDatabaseHelper {
  final dbHelper = DatabaseHelper.instance;

  static const tablePatients = 'patients';

  static const columnId = 'id';
  static const columnFullName = 'fullName';
  static const columnEmail = 'email';
  static const columnPhone = 'phone';
  static const columnIsMale = 'isMale';
  static const columnDateOfBirth = 'dateOfBirth';
  static const columnAddressLine = 'addressLine';
  static const columnDistrict = 'district';
  static const columnProvince = 'province';
  static const columnCreatedAt = 'createdAt';
  static const columnUpdatedAt = 'updatedAt';
  static const columnDeletedAt = 'deletedAt';

  static const String createTableScript = '''
  CREATE TABLE $tablePatients (
    $columnId TEXT PRIMARY KEY,
    $columnFullName TEXT NOT NULL,
    $columnEmail TEXT NOT NULL,
    $columnPhone TEXT,
    $columnIsMale INTEGER,
    $columnDateOfBirth TEXT,
    $columnAddressLine TEXT,
    $columnDistrict TEXT,
    $columnProvince TEXT,
    $columnCreatedAt TEXT,
    $columnUpdatedAt TEXT,
    $columnDeletedAt TEXT
  )
  ''';

  Future<void> cachePatients(List<Patient> patients) async {
    final db = await dbHelper.database;
    final batch = db.batch();
    batch.delete(tablePatients);
    for (final patient in patients) {
      batch.insert(
        tablePatients,
        _patientToMap(patient),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Patient>> getCachedPatients() async {
    final db = await dbHelper.database;
    try {
      final maps = await db.query(tablePatients);
      if (maps.isEmpty) {
        return [];
      }
      return maps.map((map) => _mapToPatient(map)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> clearPatients() async {
    final db = await dbHelper.database;
    await db.delete(tablePatients);
  }

  Map<String, dynamic> _patientToMap(Patient patient) {
    return {
      columnId: patient.id,
      columnFullName: patient.fullName,
      columnEmail: patient.email,
      columnPhone: patient.phone,
      columnIsMale: patient.isMale == null
          ? null
          : (patient.isMale! ? 1 : 0),
      columnDateOfBirth: patient.dateOfBirth?.toIso8601String(),
      columnAddressLine: patient.addressLine,
      columnDistrict: patient.district,
      columnProvince: patient.province,
      columnCreatedAt: patient.createdAt?.toIso8601String(),
      columnUpdatedAt: patient.updatedAt?.toIso8601String(),
      columnDeletedAt: patient.deletedAt?.toIso8601String(),
    };
  }

  Patient _mapToPatient(Map<String, dynamic> map) {
    return Patient(
      id: map[columnId],
      fullName: map[columnFullName],
      email: map[columnEmail],
      phone: map[columnPhone],
      isMale: map[columnIsMale] == null
          ? null
          : (map[columnIsMale] == 1),
      dateOfBirth: map[columnDateOfBirth] == null
          ? null
          : DateTime.parse(map[columnDateOfBirth]),
      addressLine: map[columnAddressLine],
      district: map[columnDistrict],
      province: map[columnProvince],
      createdAt: map[columnCreatedAt] == null
          ? null
          : DateTime.parse(map[columnCreatedAt]),
      updatedAt: map[columnUpdatedAt] == null
          ? null
          : DateTime.parse(map[columnUpdatedAt]),
      deletedAt: map[columnDeletedAt] == null
          ? null
          : DateTime.parse(map[columnDeletedAt]),
    );
  }
}