import 'package:flutter/material.dart';
import 'package:fungjai_app_new/services/prediction_result.dart';

class ResultPage extends StatelessWidget {
  final PredictionResult analysisResult;
  final bool isLastQuestion; // พารามิเตอร์สำหรับบอกว่าเป็นข้อสุดท้าย/หน้าสรุปหรือไม่
  final VoidCallback onNext; // Callback ที่จะถูกเรียกเมื่อกดปุ่ม

  const ResultPage({
    super.key,
    required this.analysisResult,
    required this.isLastQuestion,
    required this.onNext,
  });

  String _translateEmotion(String emotion) {
    const emotionMap = {
      'happy': 'มีความสุข', 'sad': 'เศร้า', 'angry': 'โกรธ',
      'neutral': 'รู้สึกเฉยๆ', 'frustrated': 'หงุดหงิด',
    };
    return emotionMap[emotion.toLowerCase()] ?? emotion;
  }

  String _getComfortMessage(String emotion) {
    const messages = {
      'happy': 'เยี่ยมไปเลยค่ะ! การได้ยิ้มและหัวเราะเป็นสิ่งที่ดีที่สุด ลองแบ่งปันความสุขนี้กับคนรอบข้างนะคะ',
      'sad': 'ไม่เป็นไรนะคะ ความรู้สึกเศร้าเกิดขึ้นได้กับทุกคน ลองหาอะไรอุ่นๆ ดื่ม หรือพูดคุยกับคนที่คุณไว้ใจดูนะคะ',
      'angry': 'ใจเย็นๆ ก่อนนะคะ ลองหายใจเข้าลึกๆ ช้าๆ นับ 1 ถึง 10 ในใจ อาจจะช่วยให้รู้สึกดีขึ้นได้ค่ะ',
      'neutral': 'การรู้สึกเฉยๆ ก็เป็นส่วนหนึ่งของวันนะคะ ลองทำกิจกรรมที่ชอบดูไหมคะ อาจจะทำให้รู้สึกสดชื่นขึ้นได้',
      'frustrated': 'รู้สึกหงุดหงิดไม่สบายใจใช่ไหมคะ ลองพักสักครู่ หากิจกรรมที่ช่วยให้ผ่อนคลายทำดูนะคะ',
    };
    return messages[emotion.toLowerCase()] ?? 'ดูแลสุขภาพจิตใจของคุณให้ดีนะคะ';
  }

  IconData _getEmotionIcon(String emotion) {
    const icons = {
      'happy': Icons.sentiment_very_satisfied_rounded, 'sad': Icons.sentiment_very_dissatisfied_rounded,
      'angry': Icons.sentiment_dissatisfied_rounded, 'neutral': Icons.sentiment_neutral_rounded,
      'frustrated': Icons.sentiment_dissatisfied_rounded,
    };
    return icons[emotion.toLowerCase()] ?? Icons.self_improvement_rounded;
  }

  Color _getEmotionColor(String emotion) {
     const colors = {
      'happy': Color(0xFF1B7070), 'sad': Colors.blueGrey,
      'angry': Colors.red, 'neutral': Colors.teal, 'frustrated': Colors.orange,
    };
    return colors[emotion.toLowerCase()] ?? Colors.teal;
  }


  @override
  Widget build(BuildContext context) {
    final topEmotion = analysisResult.emotion;
    final confidence = analysisResult.confidence;

    final comfortMessage = _getComfortMessage(topEmotion);
    final emotionIcon = _getEmotionIcon(topEmotion);
    final emotionColor = _getEmotionColor(topEmotion);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Text('ความมั่นใจของผลลัพธ์', style: TextStyle(fontSize: 18, color: Colors.black54)),
                      const SizedBox(height: 8),
                      Text(
                        '${(confidence * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 56, fontWeight: FontWeight.bold, color: Color(0xFF1B7070),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Icon(emotionIcon, size: 80, color: emotionColor),
              const SizedBox(height: 8),
              Text(
                'วันนี้คุณรู้สึก "${_translateEmotion(topEmotion)}"',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
              ),
              const SizedBox(height: 24),

              Text(
                comfortMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
              ),
              const Spacer(),

              // [ADD THIS] ปุ่มแบบ Dynamic
              ElevatedButton(
                onPressed: onNext, // เรียกใช้ callback ที่ส่งเข้ามา
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B7070),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  // เปลี่ยนข้อความตามสถานะ
                  isLastQuestion ? 'เสร็จสิ้น' : 'คำถามถัดไป',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}