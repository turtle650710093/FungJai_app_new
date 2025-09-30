// lib/services/emotion_database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
    String path = join(await getDatabasesPath(), 'emotion_records.db');
    
    print('🗄️ EmotionDB: Initializing database at: $path');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    print('🗄️ EmotionDB: Creating tables...');
    
    // ตาราง sessions - เก็บ session การสนทนาแต่ละครั้ง
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_set_id INTEGER NOT NULL,
        question_set_title TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        total_questions INTEGER NOT NULL,
        completed_questions INTEGER DEFAULT 0,
        is_completed INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // ตาราง emotion_records - เก็บผลการวิเคราะห์อารมณ์แต่ละคำตอบ
    await db.execute('''
      CREATE TABLE emotion_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        question_text TEXT NOT NULL,
        question_order INTEGER NOT NULL,
        emotion TEXT NOT NULL,
        confidence REAL NOT NULL,
        audio_duration REAL,
        angry_score REAL DEFAULT 0,
        frustrated_score REAL DEFAULT 0,
        happy_score REAL DEFAULT 0,
        neutral_score REAL DEFAULT 0,
        sad_score REAL DEFAULT 0,
        recorded_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE CASCADE
      )
    ''');

    // ตาราง daily_summary - สรุปอารมณ์รายวัน
    await db.execute('''
      CREATE TABLE daily_summary (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        total_sessions INTEGER DEFAULT 0,
        total_records INTEGER DEFAULT 0,
        dominant_emotion TEXT,
        avg_confidence REAL,
        emotion_counts TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    print('✅ EmotionDB: Tables created successfully');
  }

  // ============================================
  // Session Methods
  // ============================================

  /// สร้าง session ใหม่
  Future<int> createSession({
    required int questionSetId,
    required String questionSetTitle,
    required int totalQuestions,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final sessionId = await db.insert('sessions', {
      'question_set_id': questionSetId,
      'question_set_title': questionSetTitle,
      'start_time': now,
      'total_questions': totalQuestions,
      'completed_questions': 0,
      'is_completed': 0,
      'created_at': now,
    });

    print('📝 EmotionDB: Created new session: $sessionId');
    return sessionId;
  }

  /// อัพเดทความคืบหน้าของ session
  Future<void> updateSessionProgress(int sessionId, int completedQuestions) async {
    final db = await database;
    await db.update(
      'sessions',
      {'completed_questions': completedQuestions},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
    print('📊 EmotionDB: Updated session $sessionId progress: $completedQuestions');
  }

  /// ทำเครื่องหมายว่า session เสร็จสิ้น
  Future<void> completeSession(int sessionId) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'sessions',
      {
        'end_time': now,
        'is_completed': 1,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    print('✅ EmotionDB: Session $sessionId completed');
  }

  /// ดึงข้อมูล session
  Future<Map<String, dynamic>?> getSession(int sessionId) async {
    final db = await database;
    final results = await db.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    return results.isNotEmpty ? results.first : null;
  }

  /// ดึง sessions ทั้งหมด
  Future<List<Map<String, dynamic>>> getAllSessions({int limit = 50}) async {
    final db = await database;
    return await db.query(
      'sessions',
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }

  // ============================================
  // Emotion Record Methods
  // ============================================

  /// บันทึกผลการวิเคราะห์อารมณ์
  Future<int> saveEmotionRecord({
    required int sessionId,
    required String questionText,
    required int questionOrder,
    required String emotion,
    required double confidence,
    double? audioDuration,
    required Map<String, double> allPredictions,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final recordId = await db.insert('emotion_records', {
      'session_id': sessionId,
      'question_text': questionText,
      'question_order': questionOrder,
      'emotion': emotion,
      'confidence': confidence,
      'audio_duration': audioDuration,
      'angry_score': allPredictions['Angry'] ?? 0.0,
      'frustrated_score': allPredictions['Frustrated'] ?? 0.0,
      'happy_score': allPredictions['Happy'] ?? 0.0,
      'neutral_score': allPredictions['Neutral'] ?? 0.0,
      'sad_score': allPredictions['Sad'] ?? 0.0,
      'recorded_at': now,
    });

    print('💾 EmotionDB: Saved emotion record: $recordId ($emotion: ${(confidence * 100).toStringAsFixed(1)}%)');
    
    // อัพเดท daily summary
    await _updateDailySummary(DateTime.now());
    
    return recordId;
  }

  /// ดึงข้อมูลการวิเคราะห์ทั้งหมดใน session
  Future<List<Map<String, dynamic>>> getSessionRecords(int sessionId) async {
    final db = await database;
    return await db.query(
      'emotion_records',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'question_order ASC',
    );
  }

  /// ดึงข้อมูลการวิเคราะห์ทั้งหมด
  Future<List<Map<String, dynamic>>> getAllRecords({int limit = 100}) async {
    final db = await database;
    return await db.query(
      'emotion_records',
      orderBy: 'recorded_at DESC',
      limit: limit,
    );
  }

  // ============================================
  // Statistics & Analysis
  // ============================================

  /// คำนวณสถิติของ session
  Future<Map<String, dynamic>> getSessionStatistics(int sessionId) async {
    final db = await database;
    
    final records = await getSessionRecords(sessionId);
    
    if (records.isEmpty) {
      return {
        'total_records': 0,
        'emotion_counts': <String, int>{},
        'avg_confidence': 0.0,
        'dominant_emotion': 'Unknown',
      };
    }

    // นับจำนวนอารมณ์แต่ละประเภท
    Map<String, int> emotionCounts = {};
    double totalConfidence = 0.0;

    for (var record in records) {
      String emotion = record['emotion'] as String;
      emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;
      totalConfidence += record['confidence'] as double;
    }

    // หาอารมณ์ที่เด่นที่สุด
    String dominantEmotion = emotionCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    print('📊 EmotionDB: Session $sessionId stats - Records: ${records.length}, Dominant: $dominantEmotion');

    return {
      'total_records': records.length,
      'emotion_counts': emotionCounts,
      'avg_confidence': totalConfidence / records.length,
      'dominant_emotion': dominantEmotion,
    };
  }

  /// ดึงสถิติรายวัน
  Future<Map<String, dynamic>> getDailyStatistics(DateTime date) async {
    final db = await database;
    final dateStr = _formatDate(date);

    final summaries = await db.query(
      'daily_summary',
      where: 'date = ?',
      whereArgs: [dateStr],
    );

    if (summaries.isNotEmpty) {
      return summaries.first;
    }

    return {
      'date': dateStr,
      'total_sessions': 0,
      'total_records': 0,
      'dominant_emotion': 'Unknown',
    };
  }

  /// ดึงสถิติรายสัปดาห์
  Future<List<Map<String, dynamic>>> getWeeklyStatistics() async {
    final db = await database;
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 7));

    return await db.query(
      'daily_summary',
      where: 'date >= ? AND date <= ?',
      whereArgs: [_formatDate(startDate), _formatDate(endDate)],
      orderBy: 'date DESC',
    );
  }

  // ============================================
  // Daily Summary (Auto-update)
  // ============================================

  /// อัพเดทสรุปรายวันอัตโนมัติ
  Future<void> _updateDailySummary(DateTime date) async {
    final db = await database;
    final dateStr = _formatDate(date);
    final now = DateTime.now().toIso8601String();

    // หาช่วงเวลาของวันนั้น
    final startOfDay = DateTime(date.year, date.month, date.day).toIso8601String();
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

    // ดึงข้อมูลการวิเคราะห์วันนั้น
    final records = await db.query(
      'emotion_records',
      where: 'recorded_at >= ? AND recorded_at <= ?',
      whereArgs: [startOfDay, endOfDay],
    );

    if (records.isEmpty) return;

    // คำนวณสถิติ
    Map<String, int> emotionCounts = {};
    double totalConfidence = 0.0;

    for (var record in records) {
      String emotion = record['emotion'] as String;
      emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;
      totalConfidence += record['confidence'] as double;
    }

    String dominantEmotion = emotionCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    // นับจำนวน sessions
    final sessions = await db.query(
      'sessions',
      where: 'created_at >= ? AND created_at <= ?',
      whereArgs: [startOfDay, endOfDay],
    );

    // บันทึกหรืออัพเดท
    await db.insert(
      'daily_summary',
      {
        'date': dateStr,
        'total_sessions': sessions.length,
        'total_records': records.length,
        'dominant_emotion': dominantEmotion,
        'avg_confidence': totalConfidence / records.length,
        'emotion_counts': emotionCounts.toString(),
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    print('📅 EmotionDB: Updated daily summary for $dateStr');
  }

  // ============================================
  // Utility Methods
  // ============================================

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// ลบ session
  Future<void> deleteSession(int sessionId) async {
    final db = await database;
    await db.delete('sessions', where: 'id = ?', whereArgs: [sessionId]);
    await db.delete('emotion_records', where: 'session_id = ?', whereArgs: [sessionId]);
    print('🗑️ EmotionDB: Deleted session: $sessionId');
  }

  /// ล้างข้อมูลทั้งหมด
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('sessions');
    await db.delete('emotion_records');
    await db.delete('daily_summary');
    print('🗑️ EmotionDB: All data cleared');
  }

  /// ปิด database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}