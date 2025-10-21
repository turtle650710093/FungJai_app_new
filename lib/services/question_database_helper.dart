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
      return await openDatabase(path, version: 2); // เพิ่ม version
    }

    print('📝 QuestionDB: Creating new database...');
    
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    print('🔨 QuestionDB: Creating tables...');
    
    // ✅ ลบ title ออก เหลือแค่ id
    await db.execute('''
      CREATE TABLE question_sets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_set_id INTEGER NOT NULL,
        question_text TEXT NOT NULL,
        audio_path TEXT,
        order_number INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (question_set_id) REFERENCES question_sets (id) ON DELETE CASCADE
      )
    ''');

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
      // ✅ สร้าง 7 ชุดคำถาม (ไม่ต้องมี title)
      int set1Id = await txn.insert('question_sets', {'created_at': now});
      int set2Id = await txn.insert('question_sets', {'created_at': now});
      int set3Id = await txn.insert('question_sets', {'created_at': now});
      int set4Id = await txn.insert('question_sets', {'created_at': now});
      int set5Id = await txn.insert('question_sets', {'created_at': now});
      int set6Id = await txn.insert('question_sets', {'created_at': now});
      int set7Id = await txn.insert('question_sets', {'created_at': now});

      final batch = txn.batch();

      // Set 1
      List<Map<String, String>> questions1 = [
        {
          'text': 'วันนี้ได้ทานอะไรอร่อย ๆ บ้างคะ?',
          'audio': 'assets/audio/1.1.m4a',
        },
        {
          'text': 'ถ้าให้เลือกระหว่างของคาวกับของหวาน ชอบแบบไหนมากกว่ากันคะ?',
          'audio': 'assets/audio/1.2.m4a',
        },
        {
          'text': 'มีของอร่อยเมนูโปรดมั้ยคะ?',
          'audio': 'assets/audio/1.3.m4a',
        },
        {
          'text': 'ชอบกินผลไม้ไหมคะ? มีผลไม้ที่ชอบเป็นพิเศษรึเปล่าคะ?',
          'audio': 'assets/audio/1.4.m4a',
        },
        {
          'text': 'ระหว่างชาอุ่น ๆ กับกาแฟหอม ๆ ชอบแบบไหนมากกว่ากันคะ?',
          'audio': 'assets/audio/1.5.m4a',
        },
      ];

      for (int i = 0; i < questions1.length; i++) {
        batch.insert('questions', {
          'question_set_id': set1Id,
          'question_text': questions1[i]['text'],
          'audio_path': questions1[i]['audio'],
          'order_number': i + 1,
          'created_at': now,
        });
      }

      // Set 2
      List<Map<String, String>> questions2 = [
        {
          'text': 'วันนี้ตื่นมาทันดูแดดยามเช้าไหมคะ?',
          'audio': 'assets/audio/2.1.m4a',
        },
        {
          'text': 'ตื่นเช้ามาแล้ว มักจะทำอะไรเป็นอย่างแรกคะ?',
          'audio': 'assets/audio/2.2.m4a',
        },
        {
          'text': 'ช่วงบ่าย ๆ มีกิจกรรมประจำที่มักจะทำไหมคะ?',
          'audio': 'assets/audio/2.3.m4a',
        },
        {
          'text': 'เข้านอนดึกไหมคะ หรือเป็นคนนอนเร็ว?',
          'audio': 'assets/audio/2.4.m4a',
        },
        {
          'text': 'วันนี้อากาศเป็นใจมั้ยคะ~ ออกไปเดินเล่นได้ไหม?',
          'audio': 'assets/audio/2.5.m4a',
        },
      ];

      for (int i = 0; i < questions2.length; i++) {
        batch.insert('questions', {
          'question_set_id': set2Id,
          'question_text': questions2[i]['text'],
          'audio_path': questions2[i]['audio'],
          'order_number': i + 1,
          'created_at': now,
        });
      }

      // Set 3
      List<Map<String, String>> questions3 = [
        {
          'text': 'ปกติเปิดทีวีดูบ้างไหมคะ มีรายการทีวีที่ชอบเป็นพิเศษบ้างไหมคะ?',
          'audio': 'assets/audio/3.1.m4a',
        },
        {
          'text': 'เวลาว่าง ๆ ชอบเปิดเพลงฟังไหมคะ และแนวที่ชอบเป็นแบบไหนคะ?',
          'audio': 'assets/audio/3.2.m4a',
        },
        {
          'text': 'ถ้าให้เลือกสีที่ชอบที่สุด จะเลือกสีอะไรดีคะ?',
          'audio': 'assets/audio/3.3.m4a',
        },
        {
          'text': 'ถ้ามีสวนดอกไม้เล็ก ๆ ที่บ้าน อยากปลูกดอกอะไรไว้บ้างคะ?',
          'audio': 'assets/audio/3.4.m4a',
        },
        {
          'text': 'ถ้ามีสัตว์เลี้ยงได้หนึ่งตัว จะอยากเลี้ยงอะไรดีคะ?',
          'audio': 'assets/audio/3.5.m4a',
        },
      ];

      for (int i = 0; i < questions3.length; i++) {
        batch.insert('questions', {
          'question_set_id': set3Id,
          'question_text': questions3[i]['text'],
          'audio_path': questions3[i]['audio'],
          'order_number': i + 1,
          'created_at': now,
        });
      }

      // Set 4
      List<Map<String, String>> questions4 = [
        {
          'text': 'วันนี้พอมีเวลาว่างให้พักผ่อนบ้างรึเปล่าคะ?',
          'audio': 'assets/audio/4.1.m4a',
        },
        {
          'text': 'เวลาว่าง ๆ มักจะชอบทำอะไรเป็นพิเศษคะ?',
          'audio': 'assets/audio/4.2.m4a',
        },
        {
          'text': 'ปกติมีหนังสือหรือนิตยสารที่ชอบอ่านประจำไหมคะ?',
          'audio': 'assets/audio/4.3.m4a',
        },
        {
          'text': 'ชอบปลูกต้นไม้หรือดูแลสวนบ้างไหมคะ?',
          'audio': 'assets/audio/4.4.m4a',
        },
        {
          'text': 'มีมุมโปรดที่ชอบนั่งพักผ่อนบ้างไหมคะ?',
          'audio': 'assets/audio/4.5.m4a',
        },
      ];

      for (int i = 0; i < questions4.length; i++) {
        batch.insert('questions', {
          'question_set_id': set4Id,
          'question_text': questions4[i]['text'],
          'audio_path': questions4[i]['audio'],
          'order_number': i + 1,
          'created_at': now,
        });
      }

      // Set 5
      List<Map<String, String>> questions5 = [
        {
          'text': 'วันนี้ได้ทักทายใครบ้างคะ?',
          'audio': 'assets/audio/5.1.m4a',
        },
        {
          'text': 'ได้ใช้เวลากับลูกหลานบ้างไหม? คงมีเรื่องให้เล่าเยอะเลยนะคะ',
          'audio': 'assets/audio/5.2.m4a',
        },
        {
          'text': 'ถ้ามีคนอยากคุยด้วย อยากให้เขาโทรมาหรือแวะมาคุยข้าง ๆ กันมากกว่าคะ?',
          'audio': 'assets/audio/5.3.m4a',
        },
        {
          'text': 'เวลาได้เจอลูกหลานบ่อย ๆ คงอบอุ่นใจดีนะคะ?',
          'audio': 'assets/audio/5.4.m4a',
        },
        {
          'text': 'เวลาลูกหลานมาเยี่ยม อยู่กันพร้อมหน้า มักจะทำอะไรกันสนุก ๆ บ้างคะ?',
          'audio': 'assets/audio/5.5.m4a',
        },
      ];

      for (int i = 0; i < questions5.length; i++) {
        batch.insert('questions', {
          'question_set_id': set5Id,
          'question_text': questions5[i]['text'],
          'audio_path': questions5[i]['audio'],
          'order_number': i + 1,
          'created_at': now,
        });
      }

      // Set 6
      List<Map<String, String>> questions6 = [
        {
          'text': 'วันนี้รู้สึกสดชื่นดีไหมคะ?',
          'audio': 'assets/audio/6.1.m4a',
        },
        {
          'text': 'ปกติได้ออกมาเดินยืดเส้นยืดสายบ้างไหมคะ? ปกติเดินนานแค่ไหนเอ่ย',
          'audio': 'assets/audio/6.2.m4a',
        },
        {
          'text': 'เมื่อคืนหลับสบายไหมคะ?',
          'audio': 'assets/audio/6.3.m4a',
        },
        {
          'text': 'วันนี้ได้ดื่มน้ำเยอะไหมคะ? ปกติดื่มวันละกี่แก้ว?',
          'audio': 'assets/audio/6.4.m4a',
        },
        {
          'text': 'ยาก็สำคัญนะคะ วันนี้ได้ทานครบทุกมื้อหรือยัง?',
          'audio': 'assets/audio/6.5.m4a',
        },
      ];

      for (int i = 0; i < questions6.length; i++) {
        batch.insert('questions', {
          'question_set_id': set6Id,
          'question_text': questions6[i]['text'],
          'audio_path': questions6[i]['audio'],
          'order_number': i + 1,
          'created_at': now,
        });
      }

      // Set 7
      List<Map<String, String>> questions7 = [
        {
          'text': 'เทศกาลไหนที่พอถึงแล้วรู้สึกมีความสุขที่สุดคะ?',
          'audio': 'assets/audio/8.1.m4a',
        },
        {
          'text': 'วันสงกรานต์ปกติชอบทำกิจกรรมอะไรเป็นพิเศษคะ?',
          'audio': 'assets/audio/8.2.m4a',
        },
        {
          'text': 'วันปีใหม่เป็นช่วงเวลาพิเศษ ปกติใช้เวลาทำอะไรบ้างคะ?',
          'audio': 'assets/audio/8.3.m4a',
        },
        {
          'text': 'การได้ไปวัด เหมือนเป็นการพักใจดี ๆ อย่างหนึ่งเลย~ ชอบไปไหมคะ?',
          'audio': 'assets/audio/8.4.m4a',
        },
        {
          'text': 'งานประเพณีแบบไหนที่รู้สึกประทับใจหรือชอบมากที่สุดคะ?',
          'audio': 'assets/audio/8.5.m4a',
        },
      ];

      for (int i = 0; i < questions7.length; i++) {
        batch.insert('questions', {
          'question_set_id': set7Id,
          'question_text': questions7[i]['text'],
          'audio_path': questions7[i]['audio'],
          'order_number': i + 1,
          'created_at': now,
        });
      }

      await batch.commit(noResult: true);
    });

    final duration = DateTime.now().difference(startTime);
    print('✅ QuestionDB: Inserted 35 questions in 7 sets in ${duration.inMilliseconds}ms');
  }

  /// ✅ ดึงชุดคำถามแบบสุ่มพร้อม audio path (ไม่มี title แล้ว)
  Future<List<Map<String, dynamic>>> getRandomQuestionSetWithAudio() async {
    final db = await database;
    
    print('🎲 QuestionDB: Fetching random question set with audio...');
    
    try {
      // ✅ เอา title ออก
      final setResult = await db.rawQuery('''
        SELECT id FROM question_sets 
        ORDER BY RANDOM() 
        LIMIT 1
      ''');

      if (setResult.isEmpty) {
        print('❌ QuestionDB: No question sets found');
        return [];
      }

      final setId = setResult.first['id'] as int;
      
      print('📋 QuestionDB: Selected set ID: $setId');

      final questions = await db.query(
        'questions',
        where: 'question_set_id = ?',
        whereArgs: [setId],
        orderBy: 'order_number ASC',
      );

      print('✅ QuestionDB: Found ${questions.length} questions with audio');

      return questions;
      
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

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}