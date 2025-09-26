import 'package:flutter/material.dart';
import 'package:fungjai_app_new/pages/welcome_page.dart';
import 'package:fungjai_app_new/services/prediction_result.dart';

class SetSummaryPage extends StatelessWidget {
  final List<PredictionResult> results;
  final VoidCallback onNextSet;

  const SetSummaryPage({
    super.key,
    required this.results,
    required this.onNextSet,
  });

  // คำนวณเปอร์เซ็นต์บวกโดยรวมจาก 5 คำตอบ
   double _calculateOverallPositivePercentage() {
    if (results.isEmpty) return 0.0;
    
    int positiveCount = 0;
    for (var result in results) {
      String emotion = result.emotion.toLowerCase();
      if (emotion == 'happy' || emotion == 'neutral') {
        positiveCount++;
      }
    }
    
    return (positiveCount / results.length) * 100;
  }

  // หาอารมณ์เด่นของชุด
  String _getDominantEmotion() {
    if (results.isEmpty) return 'unknown';
    Map<String, int> emotionCounts = {};
    for (var result in results) {
      final emotion = result.emotion;
      emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;
    }

    if (emotionCounts.isEmpty) return 'unknown';
    return emotionCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  String _translateEmotion(String emotion) {
     const emotionMap = { 'happy': 'มีความสุข', 'sad': 'เศร้า', 'angry': 'โกรธ', 'neutral': 'รู้สึกเฉยๆ', 'fear': 'กังวล', 'disgust': 'ไม่พอใจ' };
    return emotionMap[emotion.toLowerCase()] ?? emotion;
  }

  String _getOverallComfortMessage(String dominantEmotion) {
    const messages = {
      'happy': 'ดูเหมือนว่าวันนี้จะเป็นวันที่ดีของคุณนะคะ ยอดเยี่ยมมากๆ เลย!',
      'sad': 'แม้จะมีเรื่องเศร้าบ้าง แต่คุณก็ผ่านมันมาได้นะคะ จำไว้ว่าทุกอย่างจะดีขึ้นเสมอค่ะ',
      'neutral': 'เป็นวันที่เรียบง่ายและสงบดีนะคะ การได้พักใจก็เป็นสิ่งสำคัญค่ะ',
      // เพิ่มข้อความสรุปอื่นๆ
    };
    return messages[dominantEmotion.toLowerCase()] ?? 'ขอบคุณที่แบ่งปันเรื่องราวให้ฟังนะคะ';
  }

  @override
  Widget build(BuildContext context) {
    final positivePercentage = _calculateOverallPositivePercentage();
    final dominantEmotion = _getDominantEmotion();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('สรุปผลจากชุดคำถาม', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Text('ภาพรวมอารมณ์เชิงบวก'),
                      Text('${positivePercentage.toStringAsFixed(0)}%', style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Color(0xFF1B7070))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'อารมณ์โดยรวมของคุณคือ "${_translateEmotion(dominantEmotion)}"',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              Text(
                _getOverallComfortMessage(dominantEmotion),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: onNextSet,
                child: const Text('ทำชุดคำถามต่อไป'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B7070), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  // กลับไปหน้าแรกสุด
                   Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const WelcomePage()),
                    (Route<dynamic> route) => false,
                  );
                },
                child: const Text('กลับหน้าหลัก'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}