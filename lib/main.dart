import 'package:flutter/material.dart';
import 'package:fungjai_app_new/pages/splash_page.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Thai locale
  await initializeDateFormatting('th', null);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FungJai',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B7070)),
        useMaterial3: true,
        fontFamily: 'Kanit',
      ),
      home: const SplashPage(),
    );
  }
}