import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:math';

class DatabaseHelper {
  static const _databaseName = "FungjaiApp.db";
  static const _databaseVersion = 1;

  // Singleton pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion,
        onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE question_sets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        set_name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        set_id INTEGER NOT NULL,
        question_text TEXT NOT NULL,
        FOREIGN KEY (set_id) REFERENCES question_sets (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE emotion_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        question_id INTEGER,
        audio_path TEXT NOT NULL,
        detected_emotion TEXT NOT NULL,
        confidence REAL,
        FOREIGN KEY (question_id) REFERENCES questions (id)
      )
    ''');
    
    await _insertInitialData(db);
  }
  
  Future<void> _insertInitialData(Database db) async {
    // เพิ่มชุดคำถาม
    final questionSets = [
      'ความทรงจำในวัยเด็ก',
      'ครอบครัวและคนสำคัญ', 
      'เหตุการณ์สำคัญในชีวิต',
      'บ้านและความอบอุ่น'
    ];

    final questions = [
      // ชุดที่ 1: ความทรงจำในวัยเด็ก
      [
        "ในวัยเด็กคุณชอบทำกิจกรรมอะไรกับเพื่อนมากที่สุด?",
        "มีสถานที่ไหนในวัยเด็กที่คุณชอบไปบ่อยๆ เพราะอะไร?", 
        "มีของเล่นชิ้นไหนที่คุณผูกพันเป็นพิเศษ?",
        "เคยได้รับของขวัญชิ้นที่ประทับใจที่สุดในวัยเด็กไหม? เล่าให้ฟังหน่อย",
        "หากย้อนเวลากลับไปได้หนึ่งวันในวัยเด็ก คุณอยากกลับไปวันที่ไหน?"
      ],
      // ชุดที่ 2: ครอบครัวและคนสำคัญ
      [
        "ใครคือคนที่คุณรู้สึกผูกพันมากที่สุดในชีวิต?",
        "คุณจำได้ไหมว่าเคยมีช่วงเวลาประทับใจอะไรกับเขา?",
        "มีคำพูดไหนจากเขาที่คุณยังจำได้จนถึงวันนี้?", 
        "เมื่อคิดถึงเขาตอนนี้ คุณรู้สึกอย่างไร?",
        "ถ้าเขาอยู่ตรงหน้าคุณตอนนี้ คุณอยากพูดอะไรกับเขา?"
      ],
      // ชุดที่ 3: เหตุการณ์สำคัญในชีวิต
      [
        "คุณเคยเจอเหตุการณ์สำคัญอะไรในชีวิตที่เปลี่ยนคุณไปมากที่สุด?",
        "ตอนนั้นคุณรู้สึกยังไง? กลัว ตื่นเต้น หรือมีความหวัง?",
        "คุณจัดการกับความรู้สึกในช่วงเวลานั้นอย่างไร?",
        "คุณได้เรียนรู้อะไรจากเหตุการณ์นั้นบ้าง?",
        "ถ้าให้ย้อนกลับไปอีกครั้ง คุณจะเลือกทำแบบเดิมไหม?"
      ],
      // ชุดที่ 4: บ้านและความอบอุ่น
      [
        "บ้านหลังแรกที่คุณอยู่เป็นแบบไหน? จำรายละเอียดได้ไหม?",
        "มื้อาหารกับครอบครัวที่คุณประทับใจที่สุดคือมื้อไหน?",
        "คุณมีบทบาทหรือหน้าที่อะไรในบ้านตอนนั้น?",
        "มีใครในครอบครัวที่คอยดูแลและเป็นแบบอย่างให้คุณบ้าง?",
        "ถ้าพูดถึงคำว่า \"บ้าน\" ตอนนี้ คุณนึกถึงอะไรเป็นอย่างแรก?"
      ]
    ];

    // Insert question sets และ questions
    for (int i = 0; i < questionSets.length; i++) {
      int setId = await db.insert('question_sets', {'set_name': questionSets[i]});
      
      for (String question in questions[i]) {
        await db.insert('questions', {
          'set_id': setId,
          'question_text': question
        });
      }
    }
  }

Future<List<String>> getRandomQuestionSet() async {
  try {
    print('🗄️ DatabaseHelper: Getting database instance...');
    final db = await database;
    
    print('🗄️ DatabaseHelper: Querying question_sets table...');
    final sets = await db.query('question_sets');
    print('🗄️ DatabaseHelper: Found ${sets.length} question sets');
    
    if (sets.isEmpty) {
      print('❌ DatabaseHelper: No question sets found!');
      return [];
    }
    
    final randomSet = sets[Random().nextInt(sets.length)];
    final setId = randomSet['id'];
    final setName = randomSet['set_name'];
    print('🎯 DatabaseHelper: Selected set: $setName (ID: $setId)');
    
    print('🗄️ DatabaseHelper: Querying questions for set $setId...');
    final questions = await db.query(
      'questions',
      where: 'set_id = ?',
      whereArgs: [setId],
      orderBy: 'id ASC'
    );
    
    print('🗄️ DatabaseHelper: Found ${questions.length} questions');
    
    final questionList = questions.map((q) => q['question_text'] as String).toList();
    print('✅ DatabaseHelper: Returning questions: ${questionList.length}');
    
    return questionList;
  } catch (e) {
    print('❌ DatabaseHelper: Error in getRandomQuestionSet: $e');
    rethrow;
  }
} 

  // Helper methods
  Future<int> insert(String table, Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> queryAllRows(String table) async {
    Database db = await instance.database;
    return await db.query(table);
  }
}