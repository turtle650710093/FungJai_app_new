import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static const _databaseName = "FungjaiApp.db";
  static const _databaseVersion = 1;

  // ทำให้คลาสนี้เป็น singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // มี database reference ได้เพียงอันเดียว
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    // ถ้า database เป็น null ให้ทำการ initialize
    _database = await _initDatabase();
    return _database!;
  }

  // ฟังก์ชันสำหรับ initialize database
  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion,
        onCreate: _onCreate);
  }

  // ฟังก์ชันสำหรับสร้างตารางเมื่อเปิดแอปครั้งแรก
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_text TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE emotion_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        question_id INTEGER,
        audio_path TEXT NOT NULL,
        detected_emotion TEXT NOT NULL,
        positive_score REAL,
        sad_score REAL,
        neutral_score REAL,
        angry_score REAL,
        FOREIGN KEY (question_id) REFERENCES questions (id)
      )
    ''');
    
    // เพิ่มข้อมูลคำถามเริ่มต้นเข้าไปในตาราง
    await _insertInitialQuestions(db);
  }
  
  // ฟังก์ชันสำหรับใส่คำถามเริ่มต้น
  Future<void> _insertInitialQuestions(Database db) async {
      List<String> initialQuestions = [
        "เรื่องราวที่ทำให้คุณมีความสุขที่สุดในสัปดาห์นี้คืออะไร?",
        "วันนี้มีอะไรที่ทำให้คุณยิ้มได้บ้าง เล่าให้ฟังหน่อยสิ",
        "ความทรงจำในวัยเด็กที่คุณชอบที่สุดคือเรื่องอะไร?",
        "ถ้าเปรียบเทียบความรู้สึกตอนนี้เป็นสภาพอากาศ มันจะเป็นแบบไหน?",
        "มีเพลงไหนที่ฟังแล้วทำให้นึกถึงความหลังบ้างไหม?",
        "สถานที่ที่คุณไปแล้วรู้สึกสบายใจที่สุดคือที่ไหน?",
        "เล่าถึงความสำเร็จเล็กๆ น้อยๆ ที่คุณภูมิใจให้ฟังหน่อย"
      ];
      
      for (String q in initialQuestions) {
        await db.insert('questions', {'question_text': q});
      }
      print("DEBUG: Initial questions inserted.");
  }


  // -------- Helper Methods --------

  // ฟังก์ชันสำหรับเพิ่มข้อมูล (INSERT)
  Future<int> insert(String table, Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(table, row);
  }

  // ฟังก์ชันสำหรับดึงข้อมูลทั้งหมด (QUERY ALL)
  Future<List<Map<String, dynamic>>> queryAllRows(String table) async {
    Database db = await instance.database;
    return await db.query(table);
  }

  // ฟังก์ชันสำหรับดึงข้อมูลตามเงื่อนไข (QUERY SPECIFIC)
  // ตัวอย่าง: queryRows('emotion_records', where: 'id = ?', whereArgs: [someId])
  Future<List<Map<String, dynamic>>> queryRows(String table, {String? where, List<dynamic>? whereArgs}) async {
    Database db = await instance.database;
    return await db.query(table, where: where, whereArgs: whereArgs);
  }

  // ฟังก์ชันสำหรับนับจำนวนแถว
  Future<int?> queryRowCount(String table) async {
    Database db = await instance.database;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $table'));
  }

  // ฟังก์ชันสำหรับอัปเดตข้อมูล (UPDATE)
  Future<int> update(String table, Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row['id'];
    return await db.update(table, row, where: 'id = ?', whereArgs: [id]);
  }

  // ฟังก์ชันสำหรับลบข้อมูล (DELETE)
  Future<int> delete(String table, int id) async {
    Database db = await instance.database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}