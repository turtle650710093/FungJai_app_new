import 'package:flutter/material.dart';
import 'package:fungjai_app_new/pages/home_page.dart'; 
import 'package:fungjai_app_new/services/emotion_classifier_service.dart'; // แก้ไข path ตามโปรเจคของคุณ
import 'package:fungjai_app_new/globals.dart';
final EmotionClassifierService classifier = EmotionClassifierService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print("Main: Initializing classifier...");
  await classifier.init(); 
  print("Main: Classifier initialized!");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'ฟังใจ',
      theme: ThemeData(
        primarySwatch: Colors.green,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1B7070),
          foregroundColor: Colors.white,
        )
      ),
      home: const HomePage(),
    );
  }
}