import 'package:flutter/material.dart';
import 'package:fungjai_app_new/pages/home_page.dart'; // import หน้า Home เพื่อให้ปุ่ม 'กลับหน้าหลัก' ทำงาน

class ResultPage extends StatelessWidget {
  final Map<String, double> analysisResult;

  const ResultPage({
    super.key,
    required this.analysisResult,
  });

  // --- Helper Functions ---
  // ฟังก์ชันหาอารมณ์ที่มีคะแนนสูงสุด
  MapEntry<String, double> _getTopEmotion() {
    if (analysisResult.isEmpty) {
      return const MapEntry('unknown', 0.0);
    }
    var sortedEntries = analysisResult.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.first;
  }

  // ฟังก์ชันคำนวณเปอร์เซ็นต์อารมณ์เชิงบวก
  // (ปรับแก้ 'happy', 'neutral' ให้ตรงกับ Label ของโมเดลคุณ)
  double _calculatePositivePercentage() {
    double positiveScore = (analysisResult['happy'] ?? 0.0) + (analysisResult['neutral'] ?? 0.0);
    double totalScore = analysisResult.values.fold(0.0, (sum, item) => sum + item);
    
    if (totalScore == 0) return 0.0;
    
    return (positiveScore / totalScore) * 100;
  }

  // ฟังก์ชันสำหรับแปลชื่ออารมณ์เป็นภาษาไทย
  String _translateEmotion(String emotion) {
    const emotionMap = {
      'happy': 'มีความสุข',
      'sad': 'เศร้า',
      'angry': 'โกรธ',
      'neutral': 'รู้สึกเฉยๆ',
      'fear': 'กังวล',
      'disgust': 'ไม่พอใจ',
      // เพิ่มอารมณ์อื่นๆ ตามโมเดลของคุณ
    };
    return emotionMap[emotion.toLowerCase()] ?? emotion;
  }

  // ฟังก์ชันให้คำแนะนำ/คำปลอบประโลม
  String _getComfortMessage(String emotion) {
    const messages = {
      'happy': 'เยี่ยมไปเลยค่ะ! การได้ยิ้มและหัวเราะเป็นสิ่งที่ดีที่สุด ลองแบ่งปันความสุขนี้กับคนรอบข้างนะคะ',
      'sad': 'ไม่เป็นไรนะคะ ความรู้สึกเศร้าเกิดขึ้นได้กับทุกคน ลองหาอะไรอุ่นๆ ดื่ม หรือพูดคุยกับคนที่คุณไว้ใจดูนะคะ',
      'angry': 'ใจเย็นๆ ก่อนนะคะ ลองหายใจเข้าลึกๆ ช้าๆ นับ 1 ถึง 10 ในใจ อาจจะช่วยให้รู้สึกดีขึ้นได้ค่ะ',
      'neutral': 'การรู้สึกเฉยๆ ก็เป็นส่วนหนึ่งของวันนะคะ ลองทำกิจกรรมที่ชอบดูไหมคะ อาจจะทำให้รู้สึกสดชื่นขึ้นได้',
      'fear': 'ความกังวลเป็นเรื่องธรรมดาค่ะ ทุกอย่างจะผ่านไปด้วยดี ลองฟังเพลงสบายๆ หรือเดินเล่นในที่ที่มีอากาศบริสุทธิ์ดูนะคะ',
      'disgust': 'ไม่เป็นไรนะคะ หากมีเรื่องไม่สบายใจ ลองปล่อยวางแล้วหาอะไรสนุกๆ ทำเพื่อเปลี่ยนบรรยากาศดูนะคะ',
    };
    return messages[emotion.toLowerCase()] ?? 'ดูแลสุขภาพจิตใจของคุณให้ดีนะคะ';
  }

  // ฟังก์ชันเลือกไอคอนตามอารมณ์
  IconData _getEmotionIcon(String emotion) {
    const icons = {
      'happy': Icons.sentiment_very_satisfied_rounded,
      'sad': Icons.sentiment_very_dissatisfied_rounded,
      'angry': Icons.sentiment_dissatisfied_rounded,
      'neutral': Icons.sentiment_neutral_rounded,
      'fear': Icons.sentiment_neutral_rounded,
      'disgust': Icons.sentiment_dissatisfied_rounded,
    };
    return icons[emotion.toLowerCase()] ?? Icons.self_improvement_rounded;
  }

  @override
  Widget build(BuildContext context) {
    // ดึงข้อมูลหลักออกมาจาก Helper Functions
    final topEmotionEntry = _getTopEmotion();
    final topEmotion = topEmotionEntry.key;
    final positivePercentage = _calculatePositivePercentage();
    final comfortMessage = _getComfortMessage(topEmotion);
    final emotionIcon = _getEmotionIcon(topEmotion);
    final emotionColor = topEmotion == 'happy' || topEmotion == 'neutral' ? Color(0xFF1B7070) : Colors.orange.shade800;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC), // สีพื้นหลังครีม
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch, // ทำให้ Widget ขยายเต็มความกว้าง
            children: [
              // --- การ์ดแสดงผลเปอร์เซ็นต์ ---
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Text(
                        'เปอร์เซ็นต์อารมณ์เชิงบวก',
                        style: TextStyle(fontSize: 18, color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${positivePercentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B7070),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // --- ไอคอนและชื่ออารมณ์ ---
              Icon(emotionIcon, size: 80, color: emotionColor),
              const SizedBox(height: 8),
              Text(
                'วันนี้คุณรู้สึก "${_translateEmotion(topEmotion)}"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 24),

              // --- ข้อความปลอบประโลม ---
              Text(
                comfortMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5, // เพิ่มระยะห่างระหว่างบรรทัด
                  color: Colors.black87,
                ),
              ),
              const Spacer(), // ดัน Widget ที่เหลือลงไปข้างล่าง

              // --- ปุ่มฟังเพลง (ตัวอย่าง) ---
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: ใส่ Logic การเปิดเพลงที่นี่
                  // เช่น ใช้ package 'url_launcher' เพื่อเปิดลิงก์ Youtube/Spotify
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('กำลังเปิดเพลงที่เหมาะสม... (ยังไม่ implement)')),
                  );
                },
                icon: const Icon(Icons.music_note_rounded, color: Colors.white),
                label: const Text('ฟังเพลงผ่อนคลาย', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B7070),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // --- ปุ่มกลับหน้าหลัก ---
              TextButton(
                onPressed: () {
                  // กลับไปหน้า Home และล้างหน้าอื่นๆ ออกทั้งหมด
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const HomePage()),
                    (Route<dynamic> route) => false,
                  );
                },
                child: const Text(
                  'กลับไปหน้าหลัก',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}