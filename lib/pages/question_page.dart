import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:fungjai_app_new/services/prediction_result.dart';
import 'package:fungjai_app_new/services/emotion_api_service.dart';

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
  final EmotionApiService _apiService = EmotionApiService();
  final FlutterTts _tts = FlutterTts();
  
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;
  String? _audioPath;
  Timer? _timer;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    print('🎤 QuestionPage: Initialized for question: ${widget.question}');
    _initTts();
    _requestPermission();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _initTts() async {
    try {
      final languages = await _tts.getLanguages;
      print('📢 Available languages: $languages');
      
      bool langSet = false;
      for (String lang in ['th-TH', 'th', 'tha']) {
        try {
          await _tts.setLanguage(lang);
          print('✅ Language set to: $lang');
          langSet = true;
          break;
        } catch (e) {
          print('⚠️ Failed to set $lang: $e');
        }
      }
      
      if (!langSet) {
        print('⚠️ Using default language');
      }

      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);

      print('🔊 TTS Settings: Volume=100%, Rate=0.45, Pitch=1.0');

      _tts.setStartHandler(() {
        print('🔊 TTS Started');
        if (mounted) setState(() => _isSpeaking = true);
      });

      _tts.setCompletionHandler(() {
        print('✅ TTS Completed');
        if (mounted) setState(() => _isSpeaking = false);
      });

      _tts.setErrorHandler((msg) {
        print('❌ TTS Error: $msg');
        if (mounted) setState(() => _isSpeaking = false);
      });

      await Future.delayed(const Duration(milliseconds: 500));
      await _speakQuestion();
      
    } catch (e) {
      print('❌ TTS Init Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถเริ่มระบบอ่านเสียงได้: $e')),
        );
      }
    }
  }

  Future<void> _speakQuestion() async {
    try {
      if (_isSpeaking) {
        await _tts.stop();
      }
      
      print('🔊 Speaking: ${widget.question}');
      
      final result = await _tts.speak(widget.question);
      
      if (result == 1) {
        print('✅ TTS speak success');
      } else {
        print('⚠️ TTS speak returned: $result');
      }
    } catch (e) {
      print('❌ Speak Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถอ่านคำถามได้: $e')),
        );
      }
    }
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
    if (_isSpeaking) {
      await _tts.stop();
    }

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

  Future<void> _stopRecordingAndAnalyze() async {
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

      // ส่งไปวิเคราะห์ทันที
      if (path != null) {
        await _analyzeAudio(path);
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

  Future<void> _analyzeAudio(String audioPath) async {
    final file = File(audioPath);
    if (!await file.exists()) {
      print('❌ Audio file not found: $audioPath');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบไฟล์เสียงที่บันทึก')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    print('🔄 Analyzing audio: $audioPath');

    try {
      final result = await _apiService.predictEmotion(audioPath);
      
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

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecordingAndAnalyze();
    } else {
      await _startRecording();
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // คำถาม (อ่านซ้ำ)
              GestureDetector(
                onTap: () {
                  print('📱 Question box tapped');
                  _speakQuestion();
                },
                child: Container(
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
                    border: _isSpeaking 
                        ? Border.all(color: const Color(0xFF1B7070), width: 2)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
                        color: const Color(0xFF1B7070),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
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
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Status Display
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
                      _isRecording ? 'กำลังบันทึก...' : 'พร้อมบันทึกเสียง',
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
              
              // Processing Indicator หรือ Record Button
              if (_isProcessing)
                Column(
                  children: const [
                    CircularProgressIndicator(
                      color: Color(0xFF1B7070),
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'กำลังวิเคราะห์เสียง...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                )
              else
                // ปุ่มไมโครโฟนวงกลมใหญ่
                GestureDetector(
                  onTap: _toggleRecording,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording 
                          ? Colors.red 
                          : const Color(0xFF1B7070),
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? Colors.red : const Color(0xFF1B7070))
                              .withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}