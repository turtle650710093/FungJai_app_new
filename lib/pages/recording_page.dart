import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:fungjai_app_new/pages/analysis_page.dart'; // เพิ่ม import หน้า Analysis
import 'package:fungjai_app_new/pages/result_page.dart';
import 'package:fungjai_app_new/globals.dart'; // import classifier จาก globals

class RecordingPage extends StatefulWidget {
  const RecordingPage({super.key});

  @override
  State<RecordingPage> createState() => _RecordingPageState();
}

class _RecordingPageState extends State<RecordingPage> {
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  bool _isRecorderReady = false;
  bool _isRecording = false;
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาอนุญาตการเข้าถึงไมโครโฟนในตั้งค่า')),
        );
      }
      return;
    }

    await _audioRecorder.openRecorder();
    
    if (mounted) {
      setState(() {
        _isRecorderReady = true;
      });
    }
  }

  @override
  void dispose() {
    // แก้ไขให้ปลอดภัยขึ้น ตรวจสอบว่า recorder เปิดอยู่ก่อนปิด
    if (_audioRecorder.isRecording || _audioRecorder.isStopped) {
        _audioRecorder.closeRecorder();
    }
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (!_isRecorderReady) return;

    if (_isRecording) {
      // ถ้ากำลังบันทึกอยู่ ให้หยุด
      await _stopRecording();
      // เมื่อหยุดแล้ว ให้เรียกการวิเคราะห์
      if (_audioPath != null) {
        // [จุดสำคัญ] เรียกใช้ฟังก์ชันวิเคราะห์หลังจากหยุดบันทึก
        await _analyzeAndNavigate(); 
      }
    } else {
      // ถ้ายังไม่เริ่ม ให้เริ่มบันทึก
      await _startRecording();
    }

    // อัปเดตสถานะ UI หลังจากเริ่ม/หยุดเสร็จสิ้น
    if(mounted){
      setState(() {
        _isRecording = !_isRecording;
      });
    }
  }

  Future<void> _startRecording() async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      // แก้ไขนามสกุลไฟล์ให้ตรงกับ Codec
      final String filePath = '${tempDir.path}/fungjai_rec_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _audioRecorder.startRecorder(
        toFile: filePath,
        codec: Codec.pcm16WAV, // ใช้ WAV เพื่อความเข้ากันได้
      );
      _audioPath = filePath;
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stopRecorder();
      print('Recording stopped, file saved at: $path');
      _audioPath = path; // อัปเดต path อีกครั้งเพื่อให้แน่ใจว่าได้ค่าล่าสุด
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  // --- [ส่วนที่แก้ไขและเติมเต็ม] ---
  Future<void> _analyzeAndNavigate() async {
    if (_audioPath == null || !mounted) {
      print("ไม่พบไฟล์เสียง หรือ context ไม่พร้อมใช้งาน");
      return;
    }

    // 1. นำทางไปยังหน้า "กำลังวิเคราะห์..." ทันที
    //    เพื่อให้ผู้ใช้เห็นว่าแอปกำลังทำงาน
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AnalysisPage()), // ใช้ AnalysisPage ที่คุณสร้างไว้
    );

    try {
      // 2. เรียกใช้โมเดลเพื่อวิเคราะห์เสียง (ทำงานเบื้องหลัง)
      print("กำลังเริ่มวิเคราะห์ไฟล์: $_audioPath");
      final Map<String, dynamic> rawResults = await classifier.predict(_audioPath!);
      print("วิเคราะห์เสร็จสิ้น, ผลลัพธ์ดิบ: $rawResults");

      // แปลงผลลัพธ์จาก Map<String, dynamic> เป็น Map<String, double>
      final Map<String, double> results = rawResults.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );

      // 3. เมื่อได้ผลลัพธ์แล้ว, ให้ "แทนที่" หน้า AnalysisPage ด้วย ResultPage
      //    พร้อมกับส่งผลลัพธ์ (results) ไปด้วย
      if (mounted) {
        Navigator.pushReplacement( // ใช้ pushReplacement สำคัญมาก!
          context,
          MaterialPageRoute(
            // ส่ง results ที่แปลงแล้วไปยัง ResultPage
            builder: (context) => ResultPage(analysisResult: results),
          ),
        );
      }
    } catch (e) {
      // 4. จัดการ Error ที่อาจเกิดขึ้นระหว่างการวิเคราะห์
      print("เกิดข้อผิดพลาดรุนแรงระหว่างการวิเคราะห์: $e");
      if (mounted) {
        // นำหน้า Loading ออกจากหน้าจอ
        Navigator.pop(context); 
        // แสดงข้อความแจ้งเตือน Error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("เกิดข้อผิดพลาด: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('บันทึกความรู้สึก'),
        backgroundColor: const Color(0xFF1B7070),
      ),
      backgroundColor: const Color(0xFFF5F5DC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "วันนี้มีเรื่องอะไรอยากเล่าให้ฉันฟังคะ?",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 50),
            GestureDetector(
              onTap: _isRecorderReady ? _toggleRecording : null,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: _isRecording ? Colors.red.shade400 : const Color(0xFF1B7070),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: !_isRecorderReady
                    ? const Padding(
                        padding: EdgeInsets.all(30.0),
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 5),
                      )
                    : Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        color: Colors.white,
                        size: 70,
                      ),
              ),
            ),
            const SizedBox(height: 25),
            Text(
              _isRecording ? 'กำลังบันทึก...' : (_isRecorderReady ? 'แตะอีกครั้งเพื่อหยุดและวิเคราะห์' : 'กำลังเตรียมระบบ...'),
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}