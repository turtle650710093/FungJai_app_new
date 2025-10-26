import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:fungjai_app_new/services/prediction_result.dart';
import 'package:fungjai_app_new/services/emotion_api_service.dart';
import 'package:fungjai_app_new/pages/result_page.dart';
import 'package:fungjai_app_new/widgets/voice_recorder_widget.dart';

class StoryTellingPage extends StatefulWidget {
  final VoidCallback? onComplete;
  const StoryTellingPage({super.key, this.onComplete});

  @override
  State<StoryTellingPage> createState() => _StoryTellingPageState();
}

class _StoryTellingPageState extends State<StoryTellingPage> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final EmotionApiService _apiService = EmotionApiService();
  late final AudioPlayer _audioPlayer;
  
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isPlayingAudio = false;
  bool _hasPlayedOnce = false; // ✅ เพิ่ม flag เช็คว่าเคยเล่นแล้ว
  bool _isDisposed = false;
  String? _audioPath;

  Timer? _timer;
  Duration _duration = Duration.zero;
  
  static const String _question = 'วันนี้มีอะไรอยากเล่าให้ฟังไหมคะ?';

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    print('🎤 StoryTellingPage: Initialized');
    _requestPermission();
    _setupAudioPlayer();
  }

  @override
  void dispose() {
    print('🧹 StoryTellingPage: Disposing...');
    _isDisposed = true;
    
    _timer?.cancel();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    
    print('✅ StoryTellingPage: Disposed successfully');
    super.dispose();
  }

  void _setupAudioPlayer() {
    // ✅ ฟัง state changes และจัดการ completed state
    _audioPlayer.playerStateStream.listen((state) {
      if (!mounted || _isDisposed) return;
      
      print('🎵 StoryTelling: playing=${state.playing}, processing=${state.processingState}');
      
      // ✅ เช็ค completed ก่อน - เมื่อเล่นจบให้เปลี่ยนเป็น replay
      if (state.processingState == ProcessingState.completed) {
        if (mounted && !_isDisposed) {
          setState(() {
            _isPlayingAudio = false;
            _hasPlayedOnce = true; // ✅ บันทึกว่าเคยเล่นแล้ว
          });
        }
        print('✅ StoryTelling audio completed - button reset to replay');
      } else {
        if (mounted && !_isDisposed) {
          setState(() {
            _isPlayingAudio = state.playing;
          });
        }
      }
    });

    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        print('⏱️ Audio duration: ${duration.inSeconds} seconds');
      }
    });
  }

  Future<void> _playQuestionAudio() async {
    if (_isDisposed) return;

    try {
      print('🔊 Playing storytelling audio...');
      
      await _audioPlayer.stop();
      await _audioPlayer.setAsset('assets/audio/welcome1.m4a');
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play();
      
      if (mounted && !_isDisposed) {
        setState(() {
          _isPlayingAudio = true;
          _hasPlayedOnce = true;
        });
      }
      
      print('✅ StoryTelling audio started');
      
    } catch (e, stackTrace) {
      print('❌ Audio play error: $e');
      print('   Stack: $stackTrace');
      
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถเล่นเสียงได้: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _stopQuestionAudio() async {
    try {
      await _audioPlayer.stop();
      if (mounted && !_isDisposed) {
        setState(() => _isPlayingAudio = false);
      }
    } catch (e) {
      print('❌ Audio stop error: $e');
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาอนุญาตการเข้าถึงไมโครโฟนในการตั้งค่า'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _analyzeAndNavigate() async {
    if (_audioPath == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาบันทึกเสียงก่อน'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final file = File(_audioPath!);
    if (!await file.exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่พบไฟล์เสียง กรุณาบันทึกใหม่'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (mounted && !_isDisposed) {
      setState(() {
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
      final result = await _apiService.predictEmotion(_audioPath!);
      
      if (!mounted) return;
      Navigator.pop(context);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ResultPage(
            analysisResult: result,
            isLastQuestion: false,
            isFromStoryTelling: true,
            onNext: () {
              widget.onComplete?.call();
              Navigator.of(context).pop();
            },
          ),
        ),
      );

    } on SocketException {
      if (!mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      
      print('❌ เกิดข้อผิดพลาดในการวิเคราะห์: $e');
      
      String errorMessage = 'เกิดข้อผิดพลาดในการวิเคราะห์';
      if (e.toString().contains('API ตอบกลับด้วย status')) {
        errorMessage = 'เซิร์ฟเวอร์ไม่สามารถประมวลผลได้ กรุณาลองใหม่';
      } else if (e.toString().contains('รูปแบบข้อมูล')) {
        errorMessage = 'ข้อมูลจากเซิร์ฟเวอร์ไม่ถูกต้อง';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted && !_isDisposed) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        print('⬅️ StoryTelling: Back button pressed');
        if (_isPlayingAudio) {
          await _audioPlayer.stop();
          await Future.delayed(const Duration(milliseconds: 200));
        }
        return true;
      },
      child: Scaffold(
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
            child: _isProcessing
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      const SizedBox(height: 24),
                      
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
                              _question,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // ✅ ปุ่มเล่น/หยุดเสียง - เปลี่ยนเป็น "ฟังอีกครั้ง" เมื่อเล่นจบ
                      ElevatedButton.icon(
                        onPressed: _isPlayingAudio ? _stopQuestionAudio : _playQuestionAudio,
                        icon: Icon(
                          _isPlayingAudio ? Icons.stop : (_hasPlayedOnce ? Icons.replay : Icons.play_arrow),
                          size: 28,
                        ),
                        label: Text(
                          _isPlayingAudio ? 'หยุดเสียง' : (_hasPlayedOnce ? 'ฟังอีกครั้ง' : 'ฟังคำถาม'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isPlayingAudio 
                              ? Colors.red.shade600 
                              : const Color(0xFF1B7070),
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
                      
                      // ✅ แสดงสถานะเมื่อกำลังเล่น (ไม่บัง UI)
                      if (_isPlayingAudio)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    const Color(0xFF1B7070),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'กำลังเล่นเสียง...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1B7070),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      const Spacer(),
                      
                      VoiceRecorderWidget(
                        onRecordingComplete: (path) async {
                          if (mounted && !_isDisposed) {
                            setState(() {
                              _audioPath = path;
                            });
                          }
                          await _analyzeAndNavigate();
                        },
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