import 'package:pbl6mobile/model/entities/patient.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class PatientDatabaseHelper {
  static final PatientDatabaseHelper instance = PatientDatabaseHelper._init();
  static Database? _database;

  PatientDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute(_createPatientTableScript);
  }

  static const _tablePatients = 'patients';

  static const _columnId = 'id';
  static const _columnFullName = 'fullName';
  static const _columnEmail = 'email';
  static const _columnPhone = 'phone';
  static const _columnIsMale = 'isMale';
  static const _columnDateOfBirth = 'dateOfBirth';
  static const _columnAddressLine = 'addressLine';
  static const _columnDistrict = 'district';
  static const _columnProvince = 'province';
  static const _columnCreatedAt = 'createdAt';
  static const _columnUpdatedAt = 'updatedAt';
  static const _columnDeletedAt = 'deletedAt';

  static const String _createPatientTableScript = '''
  CREATE TABLE $_tablePatients (
    $_columnId TEXT PRIMARY KEY,
    $_columnFullName TEXT NOT NULL,
    $_columnEmail TEXT NOT NULL,
    $_columnPhone TEXT,
    $_columnIsMale INTEGER,
    $_columnDateOfBirth TEXT,
    $_columnAddressLine TEXT,
    $_columnDistrict TEXT,
    $_columnProvince TEXT,
    $_columnCreatedAt TEXT,
    $_columnUpdatedAt TEXT,
    $_columnDeletedAt TEXT
  )
  ''';

  Future<void> cachePatients(List<Patient> patients) async {
    final db = await instance.database;
    final batch = db.batch();

    batch.delete(_tablePatients);

    for (final patient in patients) {
      batch.insert(
        _tablePatients,
        _patientToMap(patient),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Patient>> getCachedPatients() async {
    final db = await instance.database;
    try {
      final maps = await db.query(_tablePatients);
      if (maps.isEmpty) {
        return [];
      }
      return maps.map((map) => _mapToPatient(map)).toList();
    } catch (e) {
      print("Error getCachedPatients: $e");
      return [];
    }
  }

  Future<void> clearPatients() async {
    final db = await instance.database;
    await db.delete(_tablePatients);
  }

  Map<String, dynamic> _patientToMap(Patient patient) {
    return {
      _columnId: patient.id,
      _columnFullName: patient.fullName,
      _columnEmail: patient.email,
      _columnPhone: patient.phone,
      _columnIsMale: patient.isMale == null ? null : (patient.isMale! ? 1 : 0),
      _columnDateOfBirth: patient.dateOfBirth?.toIso8601String(),
      _columnAddressLine: patient.addressLine,
      _columnDistrict: patient.district,
      _columnProvince: patient.province,
      _columnCreatedAt: patient.createdAt?.toIso8601String(),
      _columnUpdatedAt: patient.updatedAt?.toIso8601String(),
      _columnDeletedAt: patient.deletedAt?.toIso8601String(),
    };
  }

  Patient _mapToPatient(Map<String, dynamic> map) {
    return Patient(
      id: map[_columnId],
      fullName: map[_columnFullName],
      email: map[_columnEmail],
      phone: map[_columnPhone],
      isMale: map[_columnIsMale] == null ? null : (map[_columnIsMale] == 1),
      dateOfBirth: map[_columnDateOfBirth] == null
          ? null
          : DateTime.parse(map[_columnDateOfBirth]),
      addressLine: map[_columnAddressLine],
      district: map[_columnDistrict],
      province: map[_columnProvince],
      createdAt: map[_columnCreatedAt] == null
          ? null
          : DateTime.parse(map[_columnCreatedAt]),
      updatedAt: map[_columnUpdatedAt] == null
          ? null
          : DateTime.parse(map[_columnUpdatedAt]),
      deletedAt: map[_columnDeletedAt] == null
          ? null
          : DateTime.parse(map[_columnDeletedAt]),
    );
  }
}