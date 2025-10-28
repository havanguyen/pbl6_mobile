import 'package:pbl6mobile/model/entities/question.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logger/logger.dart';

class QuestionDatabaseHelper {
  static final QuestionDatabaseHelper instance =
  QuestionDatabaseHelper._privateConstructor();
  static Database? _database;
  final Logger _logger = Logger();

  QuestionDatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'questions.db');
      _logger.i('Database path: $path');
      return await openDatabase(path, version: 1, onCreate: _createDatabase);
    } catch (e) {
      _logger.e('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _createDatabase(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE questions(
          id TEXT PRIMARY KEY,
          title TEXT,
          body TEXT,
          authorName TEXT,
          authorEmail TEXT,
          specialtyId TEXT,
          status TEXT,
          createdAt TEXT,
          updatedAt TEXT
        )
      ''');
      _logger.i('Table questions created successfully');
    } catch (e) {
      _logger.e('Error creating table questions: $e');
      rethrow;
    }
  }

  Future<void> batchInsertQuestions(List<Question> questions) async {
    final db = await instance.database;
    final batch = db.batch();
    try {
      for (final question in questions) {
        batch.insert(
          'questions',
          {
            'id': question.id,
            'title': question.title,
            'body': question.body,
            'authorName': question.authorName,
            'authorEmail': question.authorEmail,
            'specialtyId': question.specialtyId,
            'status': question.status,
            'createdAt': question.createdAt.toIso8601String(),
            'updatedAt': question.updatedAt.toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
      _logger.i('Batch inserted ${questions.length} questions successfully');
    } catch (e) {
      _logger.e('Error batch inserting questions: $e');
      rethrow;
    }
  }

  Future<List<Question>> getCachedQuestions() async {
    try {
      final db = await instance.database;
      final List<Map<String, dynamic>> maps = await db.query('questions');
      _logger.i('Retrieved ${maps.length} questions from cache');
      if (maps.isEmpty) {
        return [];
      }
      return List.generate(maps.length, (i) {
        try {
          return Question(
            id: maps[i]['id'],
            title: maps[i]['title'],
            body: maps[i]['body'],
            authorName: maps[i]['authorName'],
            authorEmail: maps[i]['authorEmail'],
            specialtyId: maps[i]['specialtyId'],
            publicIds: [],
            status: maps[i]['status'],
            createdAt: DateTime.parse(maps[i]['createdAt']),
            updatedAt: DateTime.parse(maps[i]['updatedAt']),
          );
        } catch (e) {
          _logger.e('Error parsing question from map: ${maps[i]}, Error: $e');
          return Question(
              id: maps[i]['id'] ?? 'error_id',
              title: maps[i]['title'] ?? 'Error Title',
              body: maps[i]['body'] ?? '',
              authorName: maps[i]['authorName'] ?? 'Error Name',
              authorEmail: maps[i]['authorEmail'] ?? 'error@example.com',
              publicIds: [],
              status: maps[i]['status'] ?? 'ERROR',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now());
        }
      });
    } catch (e) {
      _logger.e('Error getting cached questions: $e');
      return [];
    }
  }

  Future<void> clearQuestions() async {
    try {
      final db = await instance.database;
      await db.delete('questions');
      _logger.i('Cleared questions table');
    } catch (e) {
      _logger.e('Error clearing questions table: $e');
      rethrow;
    }
  }
}