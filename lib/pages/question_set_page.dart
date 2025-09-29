import 'package:flutter/material.dart';
import 'package:fungjai_app_new/pages/question_page.dart';
import 'package:fungjai_app_new/pages/result_page.dart';
import 'package:fungjai_app_new/pages/set_summary_page.dart';
import 'package:fungjai_app_new/services/database_helper.dart';
import 'package:fungjai_app_new/services/prediction_result.dart';

class QuestionSetPage extends StatefulWidget {
  const QuestionSetPage({super.key});

  @override
  State<QuestionSetPage> createState() => _QuestionSetPageState();
}

class _QuestionSetPageState extends State<QuestionSetPage> {
  List<String> _questions = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _currentQuestionIndex = 0;
  final List<PredictionResult> _sessionResults = [];

  @override
  void initState() {
    super.initState();
    print('🚀 QuestionSetPage: Starting to load questions...');
    _loadQuestionSet();
  }

  Future<void> _loadQuestionSet() async {
    try {
      print('📂 QuestionSetPage: Getting database instance...');
      final dbHelper = DatabaseHelper.instance;
      
      print('🎯 QuestionSetPage: Fetching random question set...');
      final questionSet = await dbHelper.getRandomQuestionSet();
      
      print('✅ QuestionSetPage: Got ${questionSet.length} questions');
      questionSet.forEach((q) => print('   - $q'));

      if (mounted) {
        setState(() {
          _questions = questionSet;
          _isLoading = false;
          if (_questions.isEmpty) {
            _errorMessage = 'ไม่พบชุดคำถามในระบบ กรุณาลองใหม่อีกครั้ง';
          }
        });

        if (_questions.isNotEmpty) {
          print('🎤 QuestionSetPage: Starting first question...');
          // รอสักครู่แล้วค่อยเปิดคำถามแรก
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) _askQuestion(_currentQuestionIndex);
          });
        }
      }
    } catch (e) {
      print('❌ QuestionSetPage: Error loading questions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'เกิดข้อผิดพลาดในการโหลดคำถาม: $e';
        });
      }
    }
  }

  void _askQuestion(int index) {
    print('🎤 QuestionSetPage: Asking question $index: ${_questions[index]}');
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuestionPage(
          question: _questions[index],
          questionNumber: index + 1,
          totalQuestions: _questions.length,
          onAnswered: (result) {
            print('✅ QuestionSetPage: Got answer for question $index');
            _handleAnalysisComplete(result);
          },
        ),
      ),
    );
  }

  void _handleAnalysisComplete(PredictionResult result) {
    print('📊 QuestionSetPage: Analysis result: ${result.emotion} (${result.confidence})');
    
    _sessionResults.add(result);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ResultPage(
          analysisResult: result,
          isLastQuestion: _currentQuestionIndex == _questions.length - 1,
          onNext: () {
            Navigator.of(context).pop();
            _goToNextStep();
          },
        ),
      ),
    );
  }

  void _goToNextStep() {
    print('➡️ QuestionSetPage: Going to next step. Current: $_currentQuestionIndex, Total: ${_questions.length}');
    
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _askQuestion(_currentQuestionIndex);
    } else {
      print('🏁 QuestionSetPage: All questions completed. Going to summary.');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => SetSummaryPage(
            results: _sessionResults,
            onNextSet: () {
              Navigator.of(context).pop();
              setState(() {
                _questions = [];
                _isLoading = true;
                _errorMessage = '';
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
        backgroundColor: const Color(0xFF1B7070),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) ...[
                const CircularProgressIndicator(
                  color: Color(0xFF1B7070),
                ),
                const SizedBox(height: 24),
                const Text(
                  'กำลังเตรียมชุดคำถาม...',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'กรุณารอสักครู่',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ] else if (_errorMessage.isNotEmpty) ...[
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.orange,
                ),
                const SizedBox(height: 24),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = '';
                    });
                    _loadQuestionSet();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B7070),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('ลองใหม่'),
                ),
              ] else if (_questions.isEmpty) ...[
                const Icon(
                  Icons.help_outline,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 24),
                const Text(
                  'ไม่พบคำถามในระบบ',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black54,
                  ),
                ),
              ] else ...[
                const Icon(
                  Icons.psychology,
                  size: 64,
                  color: Color(0xFF1B7070),
                ),
                const SizedBox(height: 24),
                const Text(
                  'กำลังเตรียมคำถามแรก...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF1B7070),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'จำนวนคำถาม: ${_questions.length} คำถาม',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}