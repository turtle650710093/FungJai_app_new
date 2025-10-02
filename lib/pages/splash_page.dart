import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fungjai_app_new/pages/welcome_page.dart';
import 'package:fungjai_app_new/services/question_database_helper.dart';
import 'package:fungjai_app_new/services/emotion_database_helper.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _loadingText = 'กำลังเตรียมแอป...';
  double _progress = 0.0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      final startTime = DateTime.now();
      
      // Step 1: Question DB
      setState(() {
        _loadingText = 'กำลังโหลดคำถาม...';
        _progress = 0.0;
      });

      await QuestionDatabaseHelper().database;
      
      setState(() {
        _progress = 0.5;
      });

      print('⏱️ Question DB: ${DateTime.now().difference(startTime).inMilliseconds}ms');

      // Step 2: Emotion DB
      setState(() {
        _loadingText = 'กำลังเตรียมระบบบันทึก...';
      });

      await EmotionDatabaseHelper().database;
      
      setState(() {
        _progress = 1.0;
      });

      print('⏱️ Total: ${DateTime.now().difference(startTime).inMilliseconds}ms');

      setState(() {
        _loadingText = 'เสร็จสิ้น!';
        _isLoading = false;
      });

      // รอนิดหน่อยเพื่อให้เห็น animation
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const WelcomePage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _loadingText = 'เกิดข้อผิดพลาด กรุณาลองใหม่';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Hero(
              tag: 'app-logo',
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo.jpg',
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            const SizedBox(height: 40),

            // Progress Indicator
            if (_isLoading) ...[
              SizedBox(
                width: 200,
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1B7070)),
                      minHeight: 6,
                    ),
                    const SizedBox(height: 16),
                    RotationTransition(
                      turns: _animationController,
                      child: const Icon(
                        Icons.refresh,
                        color: Color(0xFF1B7070),
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ] else ...[
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
              const SizedBox(height: 20),
            ],

            // Loading Text
            Text(
              _loadingText,
              style: TextStyle(
                fontSize: 16,
                color: _isLoading ? Colors.black54 : Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),

            if (!_isLoading && _loadingText.contains('ข้อผิดพลาด')) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _loadingText = 'กำลังเตรียมแอป...';
                    _progress = 0.0;
                  });
                  _initializeApp();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B7070),
                  foregroundColor: Colors.white,
                ),
                child: const Text('ลองใหม่'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}