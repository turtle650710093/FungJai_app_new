import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
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
  
  static const String _question = 'วันนี้มีอะไรอยากเล่าให้ฟังไหมคะ?';

  @override
  void initState() {
    super.initState();
    print('🎤 StoryTellingPage: Initialized');
    _initTts();
    _requestPermission();
  }

  @override
  void dispose() {
    print('🧹 StoryTellingPage: Disposing...');
    _isDisposed = true; // ✅ เซ็ต flag
    
    _timer?.cancel();
    _tts.stop();
    _tts.setStartHandler(() {});
    _tts.setCompletionHandler(() {});
    _tts.setErrorHandler((msg) {});
    _audioRecorder.dispose();
    
    print('✅ StoryTellingPage: Disposed successfully');
    super.dispose();
  }

  Future<void> _initTts() async {
    try {
      print('🔊 StoryTelling TTS: Starting initialization...');

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
      print('🔊 Volume: 1.0');
      
      await _tts.setSpeechRate(0.45);
      print('⏱️ Speech Rate: 0.45');
      
      await _tts.setPitch(1.0);
      print('🎵 Pitch: 1.0');
      
      await _tts.awaitSpeakCompletion(true);
      print('⏳ Await speak completion: true');

      // ✅ Set handlers พร้อมเช็ค mounted และ _isDisposed
      _tts.setStartHandler(() {
        print('🔊 StoryTelling TTS Started');
        if (mounted && !_isDisposed) {
          setState(() => _isSpeaking = true);
        }
      });

      _tts.setCompletionHandler(() {
        print('✅ StoryTelling TTS Completed');
        if (mounted && !_isDisposed) {
          setState(() {
            _isSpeaking = false;
            _hasSpokenOnce = true;
          });
        }
      });

      _tts.setErrorHandler((msg) {
        print('❌ StoryTelling TTS Error: $msg');
        if (mounted && !_isDisposed) {
          setState(() => _isSpeaking = false);
        }
      });

      if (mounted && !_isDisposed) {
        setState(() => _ttsReady = true);
      }
      print('✅ StoryTelling TTS: Ready');

      // รอสั้นๆ แล้วพูดเลย
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Auto speak คำถาม
      if (mounted && !_isDisposed && !_hasSpokenOnce && _thaiAvailable) {
        print('🎤 Auto speaking question...');
        await _speakQuestion();
      }
      
    } catch (e) {
      print('❌ StoryTelling TTS Init Error: $e');
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
      print('🔊 Speaking: $_question');
      
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
      
      final result = await _tts.speak(_question);
      
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

  void _startTimer() {
    if (mounted && !_isDisposed) {
      setState(() => _duration = Duration.zero);
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isDisposed) {
        setState(() {
          _duration = Duration(seconds: _duration.inSeconds + 1);
        });
      }
    });
  }

  Future<void> _startRecording() async {
    if (_isSpeaking) {
      print('🛑 Stopping TTS before recording...');
      await _tts.stop();
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (!await _audioRecorder.hasPermission()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่มีสิทธิ์เข้าถึงไมโครโฟน'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final Directory tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${tempDir.path}/story_audio_$timestamp.wav';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          bitRate: 128000,
        ),
        path: filePath,
      );

      _startTimer();
      
      if (mounted && !_isDisposed) {
        setState(() {
          _isRecording = true;
          _audioPath = filePath;
        });
      }

      print('🎙️ เริ่มบันทึกเสียง: $filePath');

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

    if (_duration.inMilliseconds < 1000) {
      if (!mounted) return;
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

      if (mounted && !_isDisposed) {
        setState(() {
          _isRecording = false;
        });
      }

      if (path != null && File(path).existsSync()) {
        final file = File(path);
        final fileSize = await file.length();
        
        if (mounted && !_isDisposed) {
          setState(() {
            _audioPath = path;
          });
        }

        print('✅ บันทึกเสียงสำเร็จ: $path (${fileSize} bytes)');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('บันทึกเสียงเรียบร้อย (${_formatDuration(_duration)})'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted && !_isDisposed) {
          setState(() {
            _audioPath = null;
          });
        }
        
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
      if (mounted && !_isDisposed) {
        setState(() {
          _isRecording = false;
          _audioPath = null;
        });
      }
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

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        print('⬅️ StoryTelling: Back button pressed');
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
                              _question,
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