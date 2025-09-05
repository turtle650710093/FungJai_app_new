import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'recording_page.dart';
import '../services/database_helper.dart';

void _requestPermissions() async {
  var microphoneStatus = await Permission.microphone.status;
  if (!microphoneStatus.isGranted) {
    await Permission.microphone.request();
  }

  // ขออนุญาตส่งการแจ้งเตือน
  var notificationStatus = await Permission.notification.status;
  if (!notificationStatus.isGranted) {
    await Permission.notification.request();
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _checkFirstLogin();
  }

  void _checkFirstLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLoginDate = prefs.getString('lastLoginDate');
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // ถ้าเคยเข้าแอปวันนี้แล้ว ให้ไปหน้า RecordingPage 
    if (lastLoginDate == today) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => RecordingPage()),
        );
      });
    }
  }

  //ถูกเรียกเมื่อกดปุ่มและจะบันทึกวันที่ลงใน SharedPreferences
  void _onPressButton() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await prefs.setString('lastLoginDate', today);

    //หน้าบันทึกเสียง
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => RecordingPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5DC),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'วันนี้มีอะไรที่คุณอยากเล่าให้ฉันฟังบ้างไหมคะ', 
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 50),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 18),
                ),
                onPressed: _onPressButton, 
                child: Text('อยากเล่าให้ฟัง'),
              ),
              SizedBox(height: 20),
              //ElevatedButton(
                // onPressed: () {
                //   // TODO: ไปหน้าประวัติ
                // },
                // child: Text('ดูประวัติที่เคยเล่า'),
                // style: ElevatedButton.styleFrom(
                //   padding: EdgeInsets.symmetric(vertical: 16),
                //   textStyle: TextStyle(fontSize: 18),
                //   backgroundColor: Colors.grey,
                // ),
              //),
            ],
          ),
        ),
      ),
    );
  }
}