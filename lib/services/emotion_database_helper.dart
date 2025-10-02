import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';

class EmotionDatabaseHelper {
  static final EmotionDatabaseHelper _instance = EmotionDatabaseHelper._internal();
  static Database? _database;

  factory EmotionDatabaseHelper() => _instance;
  EmotionDatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'fungjai_emotions.db');
    print('📦 EmotionDB: Initializing at: $path');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    print('🔨 EmotionDB: Creating tables...');
    
    // ✅ ตาราง sessions
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_set_id INTEGER NOT NULL,
        question_set_title TEXT NOT NULL,
        total_questions INTEGER NOT NULL,
        completed_questions INTEGER DEFAULT 0,
        start_time TEXT NOT NULL,
        end_time TEXT,
        status TEXT DEFAULT 'in_progress'
      )
    ''');

    // ✅ ตาราง emotion_records
    await db.execute('''
      CREATE TABLE emotion_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        question_order INTEGER NOT NULL,
        question_text TEXT NOT NULL,
        emotion TEXT NOT NULL,
        confidence REAL NOT NULL,
        angry_score REAL DEFAULT 0.0,
        frustrated_score REAL DEFAULT 0.0,
        happy_score REAL DEFAULT 0.0,
        neutral_score REAL DEFAULT 0.0,
        sad_score REAL DEFAULT 0.0,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_session_id ON emotion_records(session_id)');
    await db.execute('CREATE INDEX idx_timestamp ON emotion_records(timestamp)');

    print('✅ EmotionDB: Tables created');
  }

  
  Future<int> createSession({
    required int questionSetId,
    required String questionSetTitle,
    required int totalQuestions,
  }) async {
    final db = await database;
    return await db.insert('sessions', {
      'question_set_id': questionSetId,
      'question_set_title': questionSetTitle,
      'total_questions': totalQuestions,
      'completed_questions': 0,
      'start_time': DateTime.now().toIso8601String(),
      'status': 'in_progress',
    });
  }

  Future<void> updateSessionProgress(int sessionId, int completedQuestions) async {
    final db = await database;
    await db.update(
      'sessions',
      {'completed_questions': completedQuestions},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> completeSession(int sessionId) async {
    final db = await database;
    await db.update(
      'sessions',
      {
        'status': 'completed',
        'end_time': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<Map<String, dynamic>?> getSession(int sessionId) async {
    final db = await database;
    final results = await db.query('sessions', where: 'id = ?', whereArgs: [sessionId]);
    return results.isEmpty ? null : results.first;
  }

  
  Future<int> saveEmotionRecord({
    required int sessionId,
    required String questionText,
    required int questionOrder,
    required String emotion,
    required double confidence,
    required Map<String, double> allPredictions,
  }) async {
    final db = await database;
    return await db.insert('emotion_records', {
      'session_id': sessionId,
      'question_text': questionText,
      'question_order': questionOrder,
      'emotion': emotion,
      'confidence': confidence,
      'angry_score': allPredictions['Angry'] ?? 0.0,
      'frustrated_score': allPredictions['Frustrated'] ?? 0.0,
      'happy_score': allPredictions['Happy'] ?? 0.0,
      'neutral_score': allPredictions['Neutral'] ?? 0.0,
      'sad_score': allPredictions['Sad'] ?? 0.0,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // ✅ เพิ่มฟังก์ชันนี้ใน EmotionDatabaseHelper

Future<List<Map<String, dynamic>>> getRecordsByMonth(DateTime month) async {
  final db = await database;
  
  // สร้าง start และ end ของเดือน
  final startOfMonth = DateTime(month.year, month.month, 1);
  final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
  
  final startStr = startOfMonth.toIso8601String();
  final endStr = endOfMonth.toIso8601String();
  
  print('📅 Getting records for month: ${DateFormat('MMMM yyyy').format(month)}');
  print('   Range: $startStr to $endStr');
  
  final records = await db.query(
    'emotion_records',
    where: 'timestamp >= ? AND timestamp <= ?',
    whereArgs: [startStr, endStr],
    orderBy: 'timestamp DESC',
  );
  
  print('✅ Found ${records.length} records');
  
  return records;
}

// ✅ เพิ่มฟังก์ชันช่วยดึงข้อมูลตาม date range
Future<List<Map<String, dynamic>>> getRecordsByDateRange(
  DateTime start,
  DateTime end,
) async {
  final db = await database;
  
  final startStr = start.toIso8601String();
  final endStr = end.toIso8601String();
  
  print('📅 Getting records from $startStr to $endStr');
  
  final records = await db.query(
    'emotion_records',
    where: 'timestamp >= ? AND timestamp <= ?',
    whereArgs: [startStr, endStr],
    orderBy: 'timestamp DESC',
  );
  
  print('✅ Found ${records.length} records');
  
  return records;
}

  Future<List<Map<String, dynamic>>> getAllEmotionRecords() async {
    final db = await database;
    return await db.query('emotion_records', orderBy: 'timestamp DESC');
  }

  Future<List<Map<String, dynamic>>> getRecordsBySessionId(int sessionId) async {
    final db = await database;
    return await db.query(
      'emotion_records',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'question_order ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getSessionRecords(int sessionId) async {
    return await getRecordsBySessionId(sessionId);
  }

  // ========== STATISTICS ==========
  
  Future<Map<String, dynamic>> getSessionStatistics(int sessionId) async {
    final records = await getRecordsBySessionId(sessionId);
    
    Map<String, int> emotionCounts = {};
    double totalConfidence = 0.0;
    
    for (var record in records) {
      String emotion = record['emotion'];
      emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;
      totalConfidence += record['confidence'];
    }
    
    String? dominantEmotion;
    if (emotionCounts.isNotEmpty) {
      dominantEmotion = emotionCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }
    
    return {
      'total_records': records.length,
      'emotion_counts': emotionCounts,
      'avg_confidence': records.isEmpty ? 0.0 : totalConfidence / records.length,
      'dominant_emotion': dominantEmotion ?? 'Unknown',
    };
  }

  Future<int> deleteAllRecords() async {
    final db = await database;
    return await db.delete('emotion_records');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}