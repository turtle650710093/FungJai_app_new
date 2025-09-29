import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:fungjai_app_new/services/prediction_result.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:fungjai_app_new/main.dart';
import 'package:fungjai_app_new/pages/result_page.dart';

class StoryTellingPage extends StatefulWidget {
  const StoryTellingPage({super.key});

  @override
  State<StoryTellingPage> createState() => _StoryTellingPageState();
}

class _StoryTellingPageState extends State<StoryTellingPage> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isProcessing = false;
  String? _audioPath;

  Timer? _timer;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('โปรดอนุญาตการเข้าถึงไมโครโฟนในตั้งค่า'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startTimer() {
    setState(() => _duration = Duration.zero);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _duration = Duration(seconds: _duration.inSeconds + 1);
      });
    });
  }

  Future<void> _startRecording() async {
    // ตรวจสอบ permission อีกครั้ง
    if (!await _audioRecorder.hasPermission()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่มีสิทธิ์เข้าถึงไมโครโฟน'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // สร้างไฟล์ path
      final Directory tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${tempDir.path}/story_audio_$timestamp.wav';

      // เริ่มบันทึก
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          bitRate: 128000,
        ),
        path: filePath,
      );

      _startTimer();
      setState(() {
        _isRecording = true;
        _audioPath = filePath;
      });

      print('✅ เริ่มบันทึกเสียง: $filePath');

    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการบันทึก: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถเริ่มบันทึกได้: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    // ตรวจสอบระยะเวลาการบันทึกขั้นต่ำ
    if (_duration.inMilliseconds < 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาบันทึกเสียงอย่างน้อย 1 วินาที'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final path = await _audioRecorder.stop();
      _timer?.cancel();

      setState(() {
        _isRecording = false;
      });

      if (path != null && File(path).existsSync()) {
        final file = File(path);
        final fileSize = await file.length();
        
        setState(() {
          _audioPath = path;
        });

        print('✅ บันทึกเสียงสำเร็จ: $path (${fileSize} bytes)');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('บันทึกเสียงสำเร็จ! (${_formatDuration(_duration)})'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _audioPath = null;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('การบันทึกเสียงล้มเหลว กรุณาลองใหม่'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการหยุดบันทึก: $e');
      setState(() {
        _isRecording = false;
        _audioPath = null;
      });
      _timer?.cancel();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _analyzeAndNavigate() async {
    if (_audioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาบันทึกเสียงก่อน'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // ตรวจสอบไฟล์อีกครั้ง
    final file = File(_audioPath!);
    if (!await file.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่พบไฟล์เสียง กรุณาบันทึกใหม่'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // แสดง Loading Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF1B7070),
            ),
            SizedBox(height: 16),
            Text(
              'กำลังวิเคราะห์อารมณ์...',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'กรุณารอสักครู่',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );

    try {
      // เรียกใช้ classifier ที่มีอยู่ใน main.dart
      final PredictionResult result = await classifier.predict(_audioPath!);
      
      if (!mounted) return;

      Navigator.pop(context); // ปิด Loading Dialog

      // ไปหน้าแสดงผล
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ResultPage(
            analysisResult: result,
            isLastQuestion: true,
            onNext: () {
              // กลับไปหน้าหลัก
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ),
      );

    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // ปิด Loading Dialog
      
      print('❌ เกิดข้อผิดพลาดในการวิเคราะห์: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("เกิดข้อผิดพลาดในการวิเคราะห์: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B7070),
        foregroundColor: Colors.white,
        title: const Text('บันทึกเสียง'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // หัวข้อ
              const Text(
                'วันนี้มีเรื่องอะไรอยากเล่าไหมคะ?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 48),
              
              // กล่องแสดงสถานะ
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isRecording ? Icons.radio_button_checked : Icons.mic,
                          color: _isRecording ? Colors.red : const Color(0xFF1B7070),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isRecording ? 'กำลังบันทึก...' : 'พร้อมบันทึกเสียง',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: _isRecording ? Colors.red : const Color(0xFF1B7070),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _formatDuration(_duration),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w300,
                        color: Colors.black54,
                      ),
                    ),
                    
                    // แสดงสถานะไฟล์
                    if (!_isRecording && _audioPath != null)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'พร้อมวิเคราะห์',
                              style: TextStyle(color: Colors.green, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // ปุ่มต่างๆ
              if (_isProcessing)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: Color(0xFF1B7070)),
                      SizedBox(height: 16),
                      Text('กำลังประมวลผล...'),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    // ปุ่มบันทึก/หยุด
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isRecording ? _stopRecording : _startRecording,
                        icon: Icon(
                          _isRecording ? Icons.stop : Icons.mic,
                          size: 24,
                        ),
                        label: Text(
                          _isRecording ? 'หยุดบันทึก' : 'เริ่มบันทึก',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isRecording 
                              ? Colors.red.shade400 
                              : const Color(0xFF1B7070),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: _isRecording ? 4 : 2,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // ปุ่มวิเคราะห์
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: (_isRecording || _audioPath == null) 
                            ? null 
                            : _analyzeAndNavigate,
                        icon: const Icon(Icons.psychology, size: 24),
                        label: const Text(
                          'วิเคราะห์อารมณ์',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B7070).withOpacity(0.8),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}