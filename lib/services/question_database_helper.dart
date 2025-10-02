import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class QuestionDatabaseHelper {
  static final QuestionDatabaseHelper _instance = QuestionDatabaseHelper._internal();
  static Database? _database;

  factory QuestionDatabaseHelper() => _instance;

  QuestionDatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'fungjai_questions.db');
    
    print('📦 QuestionDB: Initializing database at: $path');
    bool dbExists = await databaseExists(path);

    if (dbExists) {
      print('✅ QuestionDB: Database already exists, opening...');
      return await openDatabase(path, version: 1);
    }

    print('📝 QuestionDB: Creating new database...');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    print('🔨 QuestionDB: Creating tables...');
    
    // สร้างตาราง question_sets
    await db.execute('''
      CREATE TABLE question_sets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // สร้างตาราง questions (ต้องสร้างก่อนสร้าง index)
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_set_id INTEGER NOT NULL,
        question_text TEXT NOT NULL,
        order_number INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (question_set_id) REFERENCES question_sets (id) ON DELETE CASCADE
      )
    ''');

    // สร้าง index หลังจากสร้างตารางแล้ว
    await db.execute('''
      CREATE INDEX idx_questions_set_id ON questions(question_set_id)
    ''');

    print('✅ QuestionDB: Tables created');

    await _insertSampleDataOptimized(db);
  }

  Future<void> _insertSampleDataOptimized(Database db) async {
    print('📝 QuestionDB: Inserting sample data (optimized)...');
    
    final startTime = DateTime.now();
    final now = startTime.toIso8601String();

    await db.transaction((txn) async {

      int set1Id = await txn.insert('question_sets', {
        'title': 'ความทรงจำวัยเด็ก',
        'created_at': now,
      });

      int set2Id = await txn.insert('question_sets', {
        'title': 'ความรักและความผูกพันในชีวิต',
        'created_at': now,
      });

      int set3Id = await txn.insert('question_sets', {
        'title': 'การเปลี่ยนผ่านในชีวิต',
        'created_at': now,
      });

      int set4Id = await txn.insert('question_sets', {
        'title': 'ครอบครัวและบ้าน',
        'created_at': now,
      });

      int set5Id = await txn.insert('question_sets', {
        'title': 'ปัจจุบัน ความพอใจในชีวิต',
        'created_at': now,
      });

      int set6Id = await txn.insert('question_sets', {
        'title': 'ปัจจุบัน ความวิตกกังวล',
        'created_at': now,
      });

      final batch = txn.batch();

      // Set 1
      List<String> questions1 = [
        'ในวัยเด็กคุณชอบทำกิจกรรมอะไรกับเพื่อนมากที่สุด?',
        'มีสถานที่ไหนในวัยเด็กที่คุณชอบไปบ่อยๆ เพราะอะไร?',
        'มีของเล่นชิ้นไหนที่คุณผูกพันเป็นพิเศษ?',
        'เคยได้รับของขวัญชิ้นที่ประทับใจที่สุดในวัยเด็กไหม? เล่าให้ฟังหน่อยสิคะ',
        'หากย้อนเวลากลับไปได้หนึ่งวันในวัยเด็ก คุณอยากกลับไปวันไหน? และทำไมถึงเลือกวันนั้น?',
      ];

      for (int i = 0; i < questions1.length; i++) {
        batch.insert('questions', {
          'question_set_id': set1Id,
          'question_text': questions1[i],
          'order_number': i + 1,
          'created_at': now,
        });
      }

      // Set 2
      List<String> questions2 = [
        'ใครคือคนที่คุณรู้สึกผูกพันที่สุดในชีวิต?',
        'คุณจำได้ไหมว่าเคยมีช่วงเวลาประทับใจอะไรกับเขา?',
        'มีคำพูดไหนจากเขาที่คุณยังจำได้จนถึงวันนี้?',
        'เมื่อคิดถึงเขาตอนนี้ คุณรู้สึกอย่างไร?',
        'ถ้าเขาอยู่ตรงหน้าคุณตอนนี้ คุณอยากพูดอะไรกับเขา?',
      ];

      for (int i = 0; i < questions2.length; i++) {
        batch.insert('questions', {
          'question_set_id': set2Id,
          'question_text': questions2[i],
          'order_number': i + 1,
          'created_at': now,
        });
      }

      // Set 3
      List<String> questions3 = [
        'คุณเคยเจอเหตุการณ์สำคัญอะไรในชีวิตที่เปลี่ยนคุณไปมากที่สุด?',
        'ตอนนั้นคุณรู้สึกยังไง? กลัว ตื่นเต้น หรือมีความหวัง',
        'คุณจัดการกับความรู้สึกในช่วงเวลานั้นอย่างไร?',
        'คุณได้เรียนรู้อะไรจากเหตุการณ์นั้นบ้าง?',
        'ถ้าให้ย้อนกลับไปอีกครั้ง คุณจะเลือกทำแบบเดิมไหม เพราะอะไร?',
      ];

      for (int i = 0; i < questions3.length; i++) {
        batch.insert('questions', {
          'question_set_id': set3Id,
          'question_text': questions3[i],
          'order_number': i + 1,
          'created_at': now,
        });
      }

      // Set 4
      List<String> questions4 = [
        'บ้านหลังแรกที่คุณอยู่เป็นแบบไหน? จำรายละเอียดได้ไหม',
        'มื้ออาหารกับครอบครัวที่คุณประทับใจที่สุดคือมื้อไหน?',
        'คุณมีบทบาทหรือหน้าที่อะไรในบ้านตอนนั้น?',
        'มีใครในครอบครัวที่คอยดูแลและเป็นแบบอย่างให้คุณบ้าง?',
        'ถ้าพูดถึงคำว่า "บ้าน" ตอนนี้ คุณนึกถึงอะไรเป็นอย่างแรก?',
      ];

      for (int i = 0; i < questions4.length; i++) {
        batch.insert('questions', {
          'question_set_id': set4Id,
          'question_text': questions4[i],
          'order_number': i + 1,
          'created_at': now,
        });
      }

      // Set 5
      List<String> questions5 = [
        'ตอนนี้คุณรู้สึกพอใจกับอะไรในชีวิตบ้าง?',
        'คุณได้อะไรมาบ้างในช่วงที่ผ่านมาจนถึงจุดที่คุณพอใจในชีวิตตอนนี้?',
        'มีอะไรที่คิดว่าอยากจะให้ตัวเองรู้สึกดีขึ้นอีกไหมหลังจากนี้?',
      ];

      for (int i = 0; i < questions5.length; i++) {
        batch.insert('questions', {
          'question_set_id': set5Id,
          'question_text': questions5[i],
          'order_number': i + 1,
          'created_at': now,
        });
      }

      // Set 6
      List<String> questions6 = [
        'ตอนนี้คุณรู้สึกกังวลเรื่องอะไรอยู่ไหม?',
        'แล้วทำอะไรมาบ้างเพื่อช่วยให้เหตุการณ์นี้ดีขึ้น?',
        'หลังจากพยายามทำเต็มที่แล้วเหตุการณ์เปลี่ยนไปอย่างไรบ้าง?',
      ];

      for (int i = 0; i < questions6.length; i++) {
        batch.insert('questions', {
          'question_set_id': set6Id,
          'question_text': questions6[i],
          'order_number': i + 1,
          'created_at': now,
        });
      }

      // ✅ Commit batch
      await batch.commit(noResult: true);
    });

    final duration = DateTime.now().difference(startTime);
    final totalQuestions = 5 + 5 + 5 + 5 + 3 + 3; // = 26
    print('✅ QuestionDB: Inserted $totalQuestions questions in 6 sets in ${duration.inMilliseconds}ms');
  }

  /// ดึงชุดคำถามแบบสุ่ม
  Future<List<String>> getRandomQuestionSet() async {
    final db = await database;
    
    print('🎲 QuestionDB: Fetching random question set...');
    
    try {
      // ดึง question set แบบสุ่ม
      final setResult = await db.rawQuery('''
        SELECT id, title FROM question_sets 
        ORDER BY RANDOM() 
        LIMIT 1
      ''');

      if (setResult.isEmpty) {
        print('❌ QuestionDB: No question sets found');
        return [];
      }

      final setId = setResult.first['id'] as int;
      final setTitle = setResult.first['title'] as String;
      
      print('📋 QuestionDB: Selected set: $setTitle (ID: $setId)');

      final questions = await db.query(
        'questions',
        where: 'question_set_id = ?',
        whereArgs: [setId],
        orderBy: 'order_number ASC',
      );

      print('✅ QuestionDB: Found ${questions.length} questions');

      return questions.map((q) => q['question_text'] as String).toList();
      
    } catch (e) {
      print('❌ QuestionDB: Error fetching questions: $e');
      return [];
    }
  }

  /// ดึงคำถามทั้งหมดในชุด
  Future<List<Map<String, dynamic>>> getQuestionsBySetId(int setId) async {
    final db = await database;
    return await db.query(
      'questions',
      where: 'question_set_id = ?',
      whereArgs: [setId],
      orderBy: 'order_number ASC',
    );
  }

  /// ดึงชุดคำถามทั้งหมด
  Future<List<Map<String, dynamic>>> getAllQuestionSets() async {
    final db = await database;
    return await db.query('question_sets', orderBy: 'id ASC');
  }

  /// เพิ่มชุดคำถามใหม่
  Future<int> addQuestionSet(String title) async {
    final db = await database;
    return await db.insert('question_sets', {
      'title': title,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// เพิ่มคำถามใหม่
  Future<int> addQuestion(int setId, String questionText, int orderNumber) async {
    final db = await database;
    return await db.insert('questions', {
      'question_set_id': setId,
      'question_text': questionText,
      'order_number': orderNumber,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}