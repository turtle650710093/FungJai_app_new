import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:fungjai_app_new/services/prediction_result.dart';
import 'package:fungjai_app_new/services/emotion_api_service.dart';
import 'package:fungjai_app_new/widgets/voice_recorder_widget.dart';

class QuestionPage extends StatefulWidget {
  final String question;
  final String? audioPath;
  final int questionNumber;
  final int totalQuestions;
  final Function(PredictionResult) onAnswered;

  const QuestionPage({
    super.key,
    required this.question,
    this.audioPath,
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
  late final AudioPlayer _audioPlayer;
  
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isPlayingAudio = false;
  bool _hasPlayedOnce = false;
  bool _isDisposed = false;
  String? _audioPath;
  Timer? _timer;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    print('🎤 QuestionPage: Initialized for question: ${widget.question}');
    print('🔊 Audio path: ${widget.audioPath}');
    _requestPermission();
    _setupAudioPlayer();
  }

  @override
  void dispose() {
    print('🧹 QuestionPage: Disposing...');
    _isDisposed = true;
    
    _timer?.cancel();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    
    print('✅ QuestionPage: Disposed successfully');
    super.dispose();
  }

  void _setupAudioPlayer() {
    // ✅ ฟัง state changes
    _audioPlayer.playerStateStream.listen((state) {
      if (!mounted || _isDisposed) return;
      
      print('🎵 Question audio: playing=${state.playing}, processing=${state.processingState}');
      
      // ✅ เช็ค completed ก่อน
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _isPlayingAudio = false;
          _hasPlayedOnce = true;
        });
        print('✅ Question audio completed - button changed to replay');
      } else {
        setState(() {
          _isPlayingAudio = state.playing;
        });
      }
    });

    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        print('⏱️ Audio duration: ${duration.inSeconds} seconds');
      }
    });

    _audioPlayer.positionStream.listen((position) {
      if (position.inSeconds > 0 && position.inSeconds % 5 == 0) {
        print('📍 Audio position: ${position.inSeconds}s');
      }
    });
  }

  Future<void> _playQuestionAudio() async {
    if (widget.audioPath == null || _isDisposed) {
      print('❌ No audio path or disposed');
      return;
    }

    try {
      print('🔊 Starting audio playback...');
      print('   Path: ${widget.audioPath}');
      
      await _audioPlayer.stop();
      
      await _audioPlayer.setAsset(widget.audioPath!);
      
      await _audioPlayer.setVolume(1.0);
      
      print('   Volume set to MAX');
      
      await _audioPlayer.play();
      
      if (mounted && !_isDisposed) {
        setState(() {
          _isPlayingAudio = true;
          _hasPlayedOnce = true;
        });
      }
      
      print('✅ Audio playback started successfully');
      
    } catch (e, stackTrace) {
      print('❌ Audio play error: $e');
      print('   Stack trace: $stackTrace');
      
      if (mounted && !_isDisposed) {
        setState(() {
          _isPlayingAudio = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถเล่นเสียงได้: ${e.toString()}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _stopQuestionAudio() async {
    try {
      print('🛑 Stopping audio...');
      await _audioPlayer.stop();
      if (mounted && !_isDisposed) {
        setState(() {
          _isPlayingAudio = false;
        });
      }
      print('✅ Audio stopped');
    } catch (e) {
      print('❌ Audio stop error: $e');
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
        await _audioPlayer.stop();
        await Future.delayed(const Duration(milliseconds: 200));
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
                      LinearProgressIndicator(
                        value: widget.questionNumber / widget.totalQuestions,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF1B7070),
                        ),
                        minHeight: 6,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      Container(
                        padding: const EdgeInsets.all(24),
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
                            if (widget.audioPath != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B7070).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _isPlayingAudio ? Icons.volume_up : Icons.headphones,
                                  size: 32,
                                  color: const Color(0xFF1B7070),
                                ),
                              ),
                            
                            if (widget.audioPath != null)
                              const SizedBox(height: 16),
                            
                            Text(
                              widget.question,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                height: 1.5,
                                color: Color(0xFF2C2C2C),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // ✅ ปุ่มเล่น/หยุดเสียง
                      if (widget.audioPath != null)
                        ElevatedButton.icon(
                          onPressed: _isPlayingAudio ? _stopQuestionAudio : _playQuestionAudio,
                          icon: Icon(
                            _isPlayingAudio ? Icons.stop : (_hasPlayedOnce ? Icons.replay : Icons.play_arrow),
                            size: 28,
                          ),
                          label: Text(
                            _isPlayingAudio ? 'หยุดเสียง' : (_hasPlayedOnce ? 'ฟังอีกครั้ง' : 'ฟังคำถาม'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isPlayingAudio 
                                ? Colors.red.shade600 
                                : const Color(0xFF1B7070),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                        ),
                      
                      // ✅ แสดงสถานะเมื่อกำลังเล่น (ไม่บัง UI)
                      if (_isPlayingAudio && widget.audioPath != null)
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
                      
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B7070).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF1B7070).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Color(0xFF1B7070),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.audioPath != null
                                    ? 'กดปุ่มด้านบนเพื่อฟังคำถาม\nแล้วกดไมค์เพื่อตอบคำถาม'
                                    : 'กดไมค์เพื่อบันทึกเสียงตอบคำถาม',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: const Color(0xFF1B7070),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
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