import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fungjai_app_new/main.dart';
import 'package:fungjai_app_new/services/prediction_result.dart';

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
    await Permission.microphone.request();
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

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.wav),
        path: filePath,
      );

      _startTimer();
      setState(() {
        _isRecording = true;
        _audioPath = filePath;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถเริ่มบันทึกได้: $e')),
      );
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
      final path = await _audioRecorder.stop();
      _timer?.cancel();
      setState(() {
        _isRecording = false;
        _audioPath = path;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  Future<void> _analyzeAndSubmit() async {
    if (_audioPath == null) return;

    setState(() => _isProcessing = true);

    try {
      final result = await classifier.predict(_audioPath!);
      widget.onAnswered(result);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการวิเคราะห์: $e')),
      );
    } finally {
      setState(() => _isProcessing = false);
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              widget.question,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    _isRecording ? 'กำลังบันทึก...' : 'พร้อมบันทึกเสียง',
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    _formatDuration(_duration),
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w300),
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            if (_isProcessing)
              const CircularProgressIndicator()
            else
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isRecording ? _stopRecording : _startRecording,
                      icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                      label: Text(_isRecording ? 'หยุดบันทึก' : 'เริ่มบันทึก'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRecording ? Colors.red : const Color(0xFF1B7070),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isRecording || _audioPath == null) ? null : _analyzeAndSubmit,
                      child: const Text('ส่งคำตอบ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B7070).withOpacity(0.8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}