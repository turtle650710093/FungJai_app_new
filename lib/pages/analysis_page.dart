import 'package:flutter/material.dart';

class AnalysisPage extends StatelessWidget {
  const AnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      // ใช้สีพื้นหลังเดียวกับ RecordingPage เพื่อความต่อเนื่อง
      backgroundColor: Color(0xFFF5F5DC), 
      body: Center(
        child: Column(
          // จัดให้อยู่กลางหน้าจอ
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            // วงกลมหมุนๆ แสดงสถานะ Loading
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                // ใช้สีหลักของแอป
                color: Color(0xFF1B7070), 
                strokeWidth: 6, // ทำให้เส้นหนาขึ้นเล็กน้อย
              ),
            ),
            
            SizedBox(height: 32), // ระยะห่างระหว่างวงกลมกับข้อความ

            // ข้อความบอกสถานะ
            Text(
              'กำลังวิเคราะห์อารมณ์...',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333), // สีเดียวกับข้อความในหน้า Recording
              ),
            ),
            
            SizedBox(height: 12),

            Text(
              'กรุณารอสักครู่นะคะ',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF555555),
              ),
            ),
          ],
        ),
      ),
    );
  }
}