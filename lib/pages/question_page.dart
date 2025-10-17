import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:fungjai_app_new/services/prediction_result.dart';
import 'package:fungjai_app_new/services/emotion_api_service.dart';
import 'package:fungjai_app_new/widgets/voice_recorder_widget.dart';

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
  bool _ttsReady = false;
  bool _hasSpokenOnce = false;
  bool _thaiAvailable = false;
  bool _isDisposed = false; // ✅ เพิ่ม flag ป้องกัน setState after dispose
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
    print('🧹 QuestionPage: Disposing...');
    _isDisposed = true; // ✅ เซ็ต flag
    
    _timer?.cancel();
    _tts.stop();
    _tts.setStartHandler(() {});
    _tts.setCompletionHandler(() {});
    _tts.setErrorHandler((msg) {});
    _audioRecorder.dispose();
    
    print('✅ QuestionPage: Disposed successfully');
    super.dispose();
  }

  Future<void> _initTts() async {
    try {
      print('🔊 Question TTS: Starting initialization...');

      // รอให้ TTS Engine พร้อม
      await Future.delayed(const Duration(milliseconds: 500));

      // Android Settings
      print('🤖 Configuring TTS...');
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);

      // เช็คภาษาที่มี
      final languages = await _tts.getLanguages;
      print('📢 Available languages: $languages');

      // ลองตั้งภาษาไทย
      bool thaiSet = false;
      for (String lang in ['th-TH', 'th']) {
        try {
          final result = await _tts.setLanguage(lang);
          print('🌐 Trying language: $lang, result: $result');
          if (result == 1) {
            print('✅ Thai language set: $lang');
            thaiSet = true;
            _thaiAvailable = true;
            break;
          }
        } catch (e) {
          print('⚠️ Failed to set $lang: $e');
        }
      }

      if (!thaiSet) {
        print('❌ Thai language not available!');
        _thaiAvailable = false;
        if (mounted && !_isDisposed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ เสียงภาษาไทยไม่พร้อมใช้งาน\nกรุณาติดตั้ง Thai TTS'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
          setState(() => _ttsReady = false);
        }
        return;
      }

      // ตั้งค่าเสียง
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);

      // ✅ Set handlers พร้อมเช็ค mounted และ _isDisposed
      _tts.setStartHandler(() {
        print('🔊 Question TTS Started');
        if (mounted && !_isDisposed) {
          setState(() => _isSpeaking = true);
        }
      });

      _tts.setCompletionHandler(() {
        print('✅ Question TTS Completed');
        if (mounted && !_isDisposed) {
          setState(() {
            _isSpeaking = false;
            _hasSpokenOnce = true;
          });
        }
      });

      _tts.setErrorHandler((msg) {
        print('❌ Question TTS Error: $msg');
        if (mounted && !_isDisposed) {
          setState(() => _isSpeaking = false);
        }
      });

      if (mounted && !_isDisposed) {
        setState(() => _ttsReady = true);
      }
      print('✅ Question TTS: Ready');

      // รอสั้นๆ แล้วพูดเลย
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Auto speak คำถาม
      if (mounted && !_isDisposed && !_hasSpokenOnce && _thaiAvailable) {
        print('🎤 Auto speaking question...');
        await _speakQuestion();
      }
      
    } catch (e) {
      print('❌ Question TTS Init Error: $e');
      if (mounted && !_isDisposed) {
        setState(() => _ttsReady = false);
      }
    }
  }

  Future<void> _speakQuestion() async {
    if (!_ttsReady || !_thaiAvailable || _isDisposed) {
      print('⚠️ TTS not ready or Thai not available or disposed');
      return;
    }

    if (_isSpeaking || _hasSpokenOnce) {
      return;
    }

    try {
      print('🔊 Speaking: ${widget.question}');
      
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
      
      final result = await _tts.speak(widget.question);
      
      print('📢 Speak result: $result');
      
      if (result != 1 && mounted && !_isDisposed) {
        setState(() => _hasSpokenOnce = true);
      }
    } catch (e) {
      print('❌ Speak Error: $e');
      if (mounted && !_isDisposed) {
        setState(() => _hasSpokenOnce = true);
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

  Future<void> _handleRecordingComplete(String path) async {
    print('📁 Recording completed: $path');
    
    if (mounted && !_isDisposed) {
      setState(() {
        _audioPath = path;
        _isProcessing = true;
      });
    }

    if (!mounted) return;

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
            Text('กำลังวิเคราะห์อารมณ์...'),
          ],
        ),
      ),
    );

    try {
      final result = await _apiService.predictEmotion(path);
      
      if (!mounted) return;
      Navigator.pop(context);
      
      widget.onAnswered(result);
      
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      
      print('❌ Analysis error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isSpeaking) {
          await _tts.stop();
          await Future.delayed(const Duration(milliseconds: 200));
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5DC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B7070),
          foregroundColor: Colors.white,
          title: Text('คำถามที่ ${widget.questionNumber}/${widget.totalQuestions}'),
          elevation: 0,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _isProcessing
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      // Progress indicator
                      LinearProgressIndicator(
                        value: widget.questionNumber / widget.totalQuestions,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF1B7070),
                        ),
                        minHeight: 6,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Question Card
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
                        child: Column(
                          children: [
                            Text(
                              widget.question,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            // Status indicator
                            if (_isSpeaking)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF1B7070),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'กำลังอ่านคำถาม...',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF1B7070),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // ปุ่มอ่านอีกครั้ง (แสดงเฉพาะเมื่ออ่านเสร็จแล้ว)
                      if (_ttsReady && _thaiAvailable && _hasSpokenOnce && !_isSpeaking)
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (mounted && !_isDisposed) {
                              setState(() => _hasSpokenOnce = false);
                            }
                            await _speakQuestion();
                          },
                          icon: const Icon(Icons.replay, size: 24),
                          label: const Text(
                            'อ่านคำถามอีกครั้ง',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B7070),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      
                      const Spacer(),
                      
                      // Voice Recorder Widget
                      VoiceRecorderWidget(
                        onRecordingComplete: _handleRecordingComplete,
                      ),
                      
                      const Spacer(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}