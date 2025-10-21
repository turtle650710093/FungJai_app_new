import 'package:flutter/material.dart';
import 'package:fungjai_app_new/pages/question_page.dart';
import 'package:fungjai_app_new/pages/result_page.dart';
import 'package:fungjai_app_new/pages/set_summary_page.dart';
import 'package:fungjai_app_new/services/question_database_helper.dart';
import 'package:fungjai_app_new/services/emotion_database_helper.dart';
import 'package:fungjai_app_new/services/prediction_result.dart';
import 'session_summary_page.dart';

class QuestionSetPage extends StatefulWidget {
  const QuestionSetPage({super.key});

  @override
  State<QuestionSetPage> createState() => _QuestionSetPageState();
}

class _QuestionSetPageState extends State<QuestionSetPage> {
  List<Map<String, dynamic>> _questionsWithAudio = []; // ✅ เปลี่ยนจาก List<String>
  bool _isLoading = true;
  String _errorMessage = '';
  int _currentQuestionIndex = 0;
  final List<PredictionResult> _sessionResults = [];

  int? _currentSessionId;
  final EmotionDatabaseHelper _emotionDb = EmotionDatabaseHelper();

  @override
  void initState() {
    super.initState();
    print('🚀 QuestionSetPage: Starting to load questions...');
    _loadQuestionSet();
  }

  Future<void> _loadQuestionSet() async {
    try {
      print('📂 QuestionSetPage: Getting database instance...');

      final db = QuestionDatabaseHelper();

      print('🎯 QuestionSetPage: Fetching random question set...');
      final questionSet = await db.getRandomQuestionSetWithAudio(); // ✅ ใช้ method ใหม่

      print('✅ QuestionSetPage: Got ${questionSet.length} questions');

      if (mounted) {
        setState(() {
          _questionsWithAudio = questionSet; // ✅ เปลี่ยนชื่อตัวแปร
          _isLoading = false;
          if (_questionsWithAudio.isEmpty) {
            _errorMessage = 'ไม่พบชุดคำถามในระบบ กรุณาลองใหม่อีกครั้ง';
          }
        });

        if (_questionsWithAudio.isNotEmpty) {
          // สร้าง session ใหม่
          _currentSessionId = await _emotionDb.createSession(
            questionSetId: questionSet.first['question_set_id'] as int, // ✅ ใช้ ID จริง
            questionSetTitle: 'ชุดคำถามที่ ${questionSet.first['question_set_id']}', // ✅ ใช้ ID แทน title
            totalQuestions: _questionsWithAudio.length,
          );
          print('📝 Created session ID: $_currentSessionId');

          print('🎤 QuestionSetPage: Starting first question...');
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
    final questionData = _questionsWithAudio[index]; // ✅ ใช้ _questionsWithAudio
    
    print('🎤 QuestionSetPage: Asking question $index: ${questionData['question_text']}');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuestionPage(
          question: questionData['question_text'] as String,
          audioPath: questionData['audio_path'] as String?, // ✅ ส่ง audio path
          questionNumber: index + 1,
          totalQuestions: _questionsWithAudio.length, // ✅ ใช้ _questionsWithAudio
          onAnswered: (result) {
            print('✅ QuestionSetPage: Got answer for question $index');
            _handleAnalysisComplete(result);
          },
        ),
      ),
    );
  }

  Future<void> _handleAnalysisComplete(PredictionResult result) async {
    print(
      '📊 QuestionSetPage: Analysis result: ${result.emotion} (${result.confidence})',
    );

    _sessionResults.add(result);

    // บันทึกลง emotion database
    if (_currentSessionId != null) {
      try {
        final currentQuestion = _questionsWithAudio[_currentQuestionIndex]; // ✅ ใช้ _questionsWithAudio
        
        await _emotionDb.saveEmotionRecord(
          sessionId: _currentSessionId!,
          questionText: currentQuestion['question_text'] as String, // ✅ ใช้ข้อมูลจาก map
          questionOrder: _currentQuestionIndex,
          emotion: result.emotion,
          confidence: result.confidence,
          allPredictions: result.allPredictions,
        );

        await _emotionDb.updateSessionProgress(
          _currentSessionId!,
          _currentQuestionIndex + 1,
        );

        print('💾 Saved emotion record for question $_currentQuestionIndex');
      } catch (e) {
        print('❌ Error saving emotion record: $e');
      }
    }

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ResultPage(
          analysisResult: result,
          isLastQuestion: _currentQuestionIndex == _questionsWithAudio.length - 1, // ✅ ใช้ _questionsWithAudio
          onNext: () {
            Navigator.of(context).pop();
            _goToNextStep();
          },
        ),
      ),
    );
  }

  Future<void> _goToNextStep() async {
    print(
      '➡️ QuestionSetPage: Going to next step. Current: $_currentQuestionIndex, Total: ${_questionsWithAudio.length}', // ✅ ใช้ _questionsWithAudio
    );

    if (_currentQuestionIndex < _questionsWithAudio.length - 1) { // ✅ ใช้ _questionsWithAudio
      setState(() {
        _currentQuestionIndex++;
      });
      _askQuestion(_currentQuestionIndex);
    } else {
      print('🏁 QuestionSetPage: All questions completed.');

      // Complete session
      if (_currentSessionId != null) {
        await _emotionDb.completeSession(_currentSessionId!);
        final stats = await _emotionDb.getSessionStatistics(_currentSessionId!);

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => SessionSummaryPage(
                sessionId: _currentSessionId!,
                statistics: stats,
              ),
            ),
          );
        }
      } else {
        // Fallback ถ้าไม่มี session
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => SetSummaryPage(
                results: _sessionResults,
                onNextSet: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _questionsWithAudio = []; // ✅ ใช้ _questionsWithAudio
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
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5DC),
        appBar: AppBar(
          title: const Text('ชุดคำถาม'),
          backgroundColor: const Color(0xFF1B7070),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF1B7070)),
              SizedBox(height: 24),
              Text('กำลังเตรียมชุดคำถาม...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
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
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
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
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      body: Container(),
    );
  }
}