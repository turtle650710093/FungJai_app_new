import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fungjai_app_new/services/prediction_result.dart';
import 'package:fungjai_app_new/services/emotion_api_service.dart';  // ✅ เพิ่มบรรทัดนี้

class QuestionPage extends StatefulWidget {
  final String question;
  final int questionNumber;
  final int totalQuestions;
  final Function(PredictionResult) onAnswered;

  const QuestionPage({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
    required this.onAnswered,
  });

  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final EmotionApiService _apiService = EmotionApiService();  // ✅ เพิ่มบรรทัดนี้
  
  bool _isRecording = false;
  bool _isProcessing = false;
  String? _audioPath;
  Timer? _timer;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    print('🎤 QuestionPage: Initialized for question: ${widget.question}');
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
    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('กรุณาอนุญาตการเข้าถึงไมโครโฟนในการตั้งค่า'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
    print('🎤 Microphone permission: $status');
  }

  void _startTimer() {
    setState(() => _duration = Duration.zero);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _duration = Duration(seconds: _duration.inSeconds + 1);
        });
      }
    });
  }

  Future<void> _startRecording() async {
    if (!await _audioRecorder.hasPermission()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่มีสิทธิ์เข้าถึงไมโครโฟน')),
      );
      return;
    }

    try {
      final Directory tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${tempDir.path}/question_audio_$timestamp.wav';

      print('🎙️ Starting recording: $filePath');

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.wav),
        path: filePath,
      );

      _startTimer();
      setState(() {
        _isRecording = true;
        _audioPath = filePath;
      });

      print('✅ Recording started');
    } catch (e) {
      print('❌ Recording error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถเริ่มบันทึกได้: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    
    if (_duration.inMilliseconds < 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาบันทึกเสียงอย่างน้อย 1 วินาที')),
      );
      return;
    }

    try {
      print('🛑 Stopping recording...');
      final path = await _audioRecorder.stop();
      _timer?.cancel();
      
      print('✅ Recording stopped: $path');
      
      setState(() {
        _isRecording = false;
        _audioPath = path;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกเสียงเรียบร้อย กดส่งคำตอบเพื่อวิเคราะห์'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Stop recording error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  Future<void> _analyzeAndSubmit() async {
    if (_audioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาบันทึกเสียงก่อน')),
      );
      return;
    }

    // เช็คว่าไฟล์มีอยู่จริง
    final file = File(_audioPath!);
    if (!await file.exists()) {
      print('❌ Audio file not found: $_audioPath');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบไฟล์เสียงที่บันทึก')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    print('🔄 Analyzing audio: $_audioPath');

    try {
      // ✅ เปลี่ยนจาก classifier.predict() เป็น _apiService.predictEmotion()
      final result = await _apiService.predictEmotion(_audioPath!);
      
      print('✅ Analysis complete: ${result.emotion} (${result.confidence})');
      
      if (mounted) {
        widget.onAnswered(result);
      }
    } catch (e) {
      print('❌ Analysis error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการวิเคราะห์: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() => _isProcessing = false);
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
        title: Text('คำถามที่ ${widget.questionNumber}/${widget.totalQuestions}'),
        backgroundColor: const Color(0xFF1B7070),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // คำถาม
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  widget.question,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // แสดงสถานะการบันทึก
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _isRecording 
                      ? Colors.red.withOpacity(0.1) 
                      : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isRecording ? Colors.red : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _isRecording ? Icons.mic : Icons.mic_none,
                      size: 48,
                      color: _isRecording ? Colors.red : const Color(0xFF1B7070),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isRecording ? 'กำลังบันทึก...' : 
                      _audioPath != null ? 'บันทึกเรียบร้อย' : 'พร้อมบันทึกเสียง',
                      style: TextStyle(
                        fontSize: 18,
                        color: _isRecording ? Colors.red : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDuration(_duration),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w300,
                        color: _isRecording ? Colors.red : const Color(0xFF1B7070),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // ปุ่มควบคุม
              if (_isProcessing)
                Column(
                  children: const [
                    CircularProgressIndicator(
                      color: Color(0xFF1B7070),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'กำลังวิเคราะห์เสียง...',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isRecording ? _stopRecording : _startRecording,
                        icon: Icon(_isRecording ? Icons.stop : Icons.mic, size: 24),
                        label: Text(
                          _isRecording ? 'หยุดบันทึก' : 'เริ่มบันทึก',
                          style: const TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isRecording ? Colors.red : const Color(0xFF1B7070),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: (_isRecording || _audioPath == null) 
                            ? null 
                            : _analyzeAndSubmit,
                        icon: const Icon(Icons.send, size: 24),
                        label: const Text(
                          'ส่งคำตอบ',
                          style: TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B7070),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}