import 'package:flutter/material.dart';
import 'package:fungjai_app_new/pages/question_set_page.dart';
import 'package:fungjai_app_new/pages/storytelling_recording_page.dart';
import 'package:fungjai_app_new/widgets/app_drawer.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F1E7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B7070),
        foregroundColor: Colors.white,
        title: const Text('FungJai'),
      ),
      endDrawer: const AppDrawer(),  
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
                Column(
                  children: [
                    const Text('อยากเล่า', style: TextStyle(fontFamily: 'Kanit')),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const StoryTellingPage()),
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
                          MaterialPageRoute(builder: (_) => const QuestionSetPage()),
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