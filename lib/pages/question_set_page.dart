import 'package:flutter/material.dart';
import 'package:fungjai_app_new/helpers/database_helper.dart';
import 'package:fungjai_app_new/pages/question_page.dart';
import 'package:fungjai_app_new/pages/result_page.dart';
import 'package:fungjai_app_new/pages/set_summary_page.dart';
import 'package:fungjai_app_new/services/prediction_result.dart';

class QuestionSetPage extends StatefulWidget {
  const QuestionSetPage({super.key});

  @override
  State<QuestionSetPage> createState() => _QuestionSetPageState();
}

class _QuestionSetPageState extends State<QuestionSetPage> {
  // --- State Variables ---
  List<String> _questions = [];
  bool _isLoading = true; // สถานะสำหรับตอนดึงคำถามจาก DB
  int _currentQuestionIndex = 0;
  final List<PredictionResult> _sessionResults = [];

  @override
  void initState() {
    super.initState();
    _loadQuestionSet();
  }

  // [NEW] ดึงชุดคำถามแบบสุ่มจาก SQLite
  Future<void> _loadQuestionSet() async {
    final dbHelper = DatabaseHelper.instance;
    final questionSet = await dbHelper.getRandomQuestionSet();
    if (mounted) {
      setState(() {
        _questions = questionSet;
        _isLoading = false;
      });
      // ถ้ามีคำถาม ให้เริ่มคำถามแรก
      if (_questions.isNotEmpty) {
        _askQuestion(_currentQuestionIndex);
      }
    }
  }

  // [NEW] ฟังก์ชันสำหรับนำทางไปหน้าคำถาม
  void _askQuestion(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuestionPage(
          question: _questions[index],
          questionNumber: index + 1,
          totalQuestions: _questions.length,
          // ส่งผลลัพธ์กลับมาที่นี่เมื่อตอบเสร็จ
          onAnswered: (result) {
            _handleAnalysisComplete(result);
          },
        ),
      ),
    );
  }

  // [NEW] เมื่อวิเคราะห์ผลของข้อนั้นๆ เสร็จ
  void _handleAnalysisComplete(PredictionResult result) {
    // เก็บผลลัพธ์
    _sessionResults.add(result);

    // แสดงหน้าผลลัพธ์รายข้อ
      Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => ResultPage(
        analysisResult: result, // ส่งผลลัพธ์ของข้อนี้
        isLastQuestion: _currentQuestionIndex == _questions.length - 1,
        onNext: () {
          Navigator.of(context).pop(); // ปิด ResultPage
          _goToNextStep();
          },
        ),
      ),
    );
  }

  // [NEW] ตัดสินใจว่าจะไปข้อถัดไป หรือไปหน้าสรุป
  void _goToNextStep() {
    if (_currentQuestionIndex < _questions.length - 1) {
      // ยังมีคำถามถัดไป
      setState(() {
        _currentQuestionIndex++;
      });
      _askQuestion(_currentQuestionIndex);
    } else {
      // เป็นข้อสุดท้ายแล้ว, ไปหน้าสรุปผล
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => SetSummaryPage(
            results: _sessionResults,
            onNextSet: () {
               // หากผู้ใช้ต้องการทำชุดคำถามใหม่
               // รีเซ็ต state แล้วเริ่มโหลดชุดคำถามใหม่
               Navigator.of(context).pop();
               setState(() {
                  _questions = [];
                  _isLoading = true;
                  _currentQuestionIndex = 0;
                  _sessionResults.clear();
               });
               _loadQuestionSet();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        title: const Text('ชุดคำถาม'),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _questions.isEmpty
                ? const Text('ไม่พบชุดคำถามในระบบ')
                : const Text('กำลังเตรียมคำถาม...'), // หน้านี้จะแสดงแค่แวบเดียว
      ),
    );
  }
}