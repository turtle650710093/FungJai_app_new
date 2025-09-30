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
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    print('🗄️ QuestionDB: Creating tables...');
    
    // สร้างตาราง question_sets
    await db.execute('''
      CREATE TABLE question_sets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // สร้างตาราง questions
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

    print('✅ QuestionDB: Tables created. Inserting sample data...');

    // เพิ่มข้อมูลตัวอย่าง
    await _insertSampleData(db);
  }

  Future<void> _insertSampleData(Database db) async {
    final now = DateTime.now().toIso8601String();

    // เพิ่มชุดคำถามที่ 1: คำถามทั่วไป
    int set1Id = await db.insert('question_sets', {
      'title': 'คำถามเกี่ยวกับความรู้สึก',
      'description': 'คำถามเกี่ยวกับความรู้สึกและอารมณ์ทั่วไป',
      'created_at': now,
    });

    List<String> questions1 = [
      'วันนี้คุณรู้สึกอย่างไร?',
      'มีเหตุการณ์อะไรที่ทำให้คุณประทับใจวันนี้บ้าง?',
      'คุณกังวลเรื่องอะไรบ้างในช่วงนี้?',
      'สิ่งที่ทำให้คุณมีความสุขที่สุดในวันนี้คืออะไร?',
      'คุณรู้สึกเครียดหรือไม่? ถ้าใช่ เพราะอะไร?',
    ];

    for (int i = 0; i < questions1.length; i++) {
      await db.insert('questions', {
        'question_set_id': set1Id,
        'question_text': questions1[i],
        'order_number': i + 1,
        'created_at': now,
      });
    }

    // เพิ่มชุดคำถามที่ 2: คำถามเกี่ยวกับชีวิตประจำวัน
    int set2Id = await db.insert('question_sets', {
      'title': 'คำถามเกี่ยวกับชีวิตประจำวัน',
      'description': 'คำถามเกี่ยวกับกิจกรรมและความรู้สึกในชีวิตประจำวัน',
      'created_at': now,
    });

    List<String> questions2 = [
      'เช้านี้คุณตื่นมารู้สึกอย่างไร?',
      'คุณพบเจอปัญหาอะไรในการทำงานหรือเรียนบ้างไหม?',
      'คุณรู้สึกว่าตัวเองมีพลังงานมากน้อยแค่ไหนวันนี้?',
      'มีใครหรืออะไรที่ทำให้คุณรู้สึกดีขึ้นวันนี้บ้าง?',
      'คุณคิดว่าวันนี้เป็นวันที่ดีหรือไม่? ทำไม?',
    ];

    for (int i = 0; i < questions2.length; i++) {
      await db.insert('questions', {
        'question_set_id': set2Id,
        'question_text': questions2[i],
        'order_number': i + 1,
        'created_at': now,
      });
    }

    // เพิ่มชุดคำถามที่ 3: คำถามเกี่ยวกับความสัมพันธ์
    int set3Id = await db.insert('question_sets', {
      'title': 'คำถามเกี่ยวกับความสัมพันธ์',
      'description': 'คำถามเกี่ยวกับความสัมพันธ์กับคนรอบข้าง',
      'created_at': now,
    });

    List<String> questions3 = [
      'คุณรู้สึกอย่างไรกับคนรอบข้างในช่วงนี้?',
      'มีใครที่คุณอยากพูดคุยด้วยแต่ยังไม่ได้พูดบ้างไหม?',
      'คุณรู้สึกว่าตัวเองถูกเข้าใจจากคนรอบข้างหรือไม่?',
      'มีความสัมพันธ์ใดที่ทำให้คุณเครียดในช่วงนี้บ้างไหม?',
      'คุณรู้สึกโดดเดี่ยวหรือไม่? ถ้าใช่ เพราะอะไร?',
    ];

    for (int i = 0; i < questions3.length; i++) {
      await db.insert('questions', {
        'question_set_id': set3Id,
        'question_text': questions3[i],
        'order_number': i + 1,
        'created_at': now,
      });
    }

    print('✅ QuestionDB: Inserted ${questions1.length + questions2.length + questions3.length} sample questions in 3 sets');
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

      // ดึงคำถามในชุดนั้น
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
  Future<int> addQuestionSet(String title, String? description) async {
    final db = await database;
    return await db.insert('question_sets', {
      'title': title,
      'description': description,
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