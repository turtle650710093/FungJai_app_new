import 'package:flutter/material.dart';
import 'package:fungjai_app_new/pages/question_page.dart';
import 'package:fungjai_app_new/pages/recording_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F1E7),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'วันนี้คุณอยากเล่าเรื่องอะไร\nให้ฉันฟังบ้างไหมคะ ?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.black87,
                  fontFamily: 'Kanit',
                ),
              ),
            ),
            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ปุ่ม "อยากเล่า" (yes)
                Column(
                  children: [
                    const Text('อยากเล่า', style: TextStyle(fontFamily: 'Kanit')),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context, 
                          MaterialPageRoute(builder: (_) => const RecordingPage()),
                        );
                      },
                      child: Image.asset(
                        'assets/images/correct.png',
                        width: 80,
                        height: 80,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 40),
                Column(
                  children: [
                    const Text('ไม่อยากเล่า', style: TextStyle(fontFamily: 'Kanit')),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const QuestionPage()),
                          );
                      },
                      child: Image.asset(
                        'assets/images/incorrect.png',
                        width: 80,
                        height: 80,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}