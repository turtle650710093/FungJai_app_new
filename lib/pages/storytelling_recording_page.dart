import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:fungjai_app_new/services/prediction_result.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

// [CHECK] import main.dart ถูกต้องแล้ว
import 'package:fungjai_app_new/main.dart';
import 'package:fungjai_app_new/pages/analysis_page.dart';
import 'package:fungjai_app_new/pages/result_page.dart';

class StoryTellingPage extends StatefulWidget {
  const StoryTellingPage({super.key});

  @override
  State<StoryTellingPage> createState() => _StoryTellingPageState();
}

class _StoryTellingPageState extends State<StoryTellingPage> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecorderReady = false;
  bool _isRecording = false;
  bool _isProcessing = false;
  String? _audioPath;

  Timer? _timer;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  @override
  void dispose() {
    if (_recorder.isOpen()) {
      _recorder.closeRecorder();
    }
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('โปรดอนุญาตการเข้าถึงไมโครโฟนในตั้งค่า')),
      );
      return;
    }

    await _recorder.openRecorder();
    setState(() {
      _isRecorderReady = true;
    });
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
    if (!_isRecorderReady) return;

    final Directory tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${tempDir.path}/story_audio_$timestamp.wav';

    await _recorder.startRecorder(
      toFile: filePath,
      codec: Codec.pcm16WAV,
    );

    _startTimer();
    setState(() {
      _isRecording = true;
      _audioPath = filePath;
    });
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    _timer?.cancel();
    setState(() {
      _isRecording = false;
    });
  }

  Future<void> _analyzeAndNavigate() async {
    if (_audioPath == null) return;

    setState(() {
      _isProcessing = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AnalysisPage(),
    );

    try {
      final PredictionResult result = await classifier.predict(_audioPath!);
      if (!mounted) return;

      Navigator.pop(context); 

      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => ResultPage(
          analysisResult: result,
          isLastQuestion: true,
          onNext: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ));

    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // ปิดหน้า Loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาดในการวิเคราะห์: $e"))
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              Text(
                _formatDuration(_duration),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w300,
                  color: Colors.black54,
                ),
              ),
              const Spacer(),
              if (_isProcessing)
                const Center(child: CircularProgressIndicator())
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: !_isRecorderReady
                          ? null
                          : (_isRecording ? _stopRecording : _startRecording),
                      icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                      label: Text(_isRecording ? 'หยุดบันทึก' : 'เริ่มบันทึก'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRecording
                            ? Colors.red.shade400
                            : const Color(0xFF1B7070),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: (_isRecording || _audioPath == null)
                          ? null
                          : _analyzeAndNavigate,
                      child: const Text('บันทึกและวิเคราะห์ผล'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF1B7070).withOpacity(0.8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}