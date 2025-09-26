import 'package:flutter/material.dart';
import 'package:fungjai_app_new/pages/splash_page.dart';
import 'package:fungjai_app_new/services/emotion_api_service.dart'; 

final EmotionApiService classifier = EmotionApiService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ฟังใจ',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Sarabun',
      ),
      home: const SplashPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}