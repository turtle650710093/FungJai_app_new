import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fungjai_app_new/pages/question_set_page.dart';
import 'package:fungjai_app_new/pages/storytelling_recording_page.dart';
import 'package:fungjai_app_new/services/daily_check_helper.dart';
import 'package:fungjai_app_new/widgets/app_drawer.dart';
import 'package:just_audio/just_audio.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  late final AudioPlayer _audioPlayer;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _setupAudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _setupAudioPlayer() {
    // ✅ ฟัง state changes
    _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      
      print('🎵 Welcome state: playing=${state.playing}, processing=${state.processingState}');
      
      // ✅ อัปเดต state ตาม processing state
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _isPlaying = false;
        });
        print('✅ Welcome audio completed - button reset');
      } else {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });
  }

  Future<void> _playWelcomeAudio() async {
    if (_isPlaying) return;

    try {
      await _audioPlayer.stop();
      await _audioPlayer.setAsset('assets/audio/welcome.m4a');
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play();
      
      setState(() => _isPlaying = true);
      
    } catch (e) {
      print('❌ Error playing audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถเล่นเสียงได้: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _onStoryTellingSelected() async {
    if (_isPlaying) {
      await _audioPlayer.stop();
      setState(() => _isPlaying = false);
    }

    await DailyCheckHelper.markAsUsedToday();
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const StoryTellingWithQuestionFlow(),
        ),
      );
    }
  }

  Future<void> _onQuestionSetSelected() async {
    if (_isPlaying) {
      await _audioPlayer.stop();
      setState(() => _isPlaying = false);
    }

    await DailyCheckHelper.markAsUsedToday();
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const QuestionSetPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting = 'สวัสดี';
    IconData greetingIcon = Icons.wb_sunny_outlined;

    if (hour >= 5 && hour < 12) {
      greeting = 'สวัสดีตอนเช้า';
      greetingIcon = Icons.wb_sunny_outlined;
    } else if (hour >= 12 && hour < 17) {
      greeting = 'สวัสดีตอนบ่าย';
      greetingIcon = Icons.wb_sunny;
    } else if (hour >= 17 && hour < 21) {
      greeting = 'สวัสดีตอนเย็น';
      greetingIcon = Icons.wb_twilight;
    } else {
      greeting = 'สวัสดีตอนค่ำ';
      greetingIcon = Icons.nightlight_round;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF2D5F5F),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: const AppDrawer(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 1),
              
              Icon(
                greetingIcon,
                size: 80,
                color: const Color(0xFF2D5F5F),
              ),
              const SizedBox(height: 24),
              
              Text(
                greeting,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D5F5F),
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                'วันนี้มีอะไรอยากเล่าให้ฟังไหมคะ?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 24),
              
              ElevatedButton.icon(
                onPressed: _isPlaying ? null : _playWelcomeAudio,
                icon: Icon(
                  _isPlaying ? Icons.volume_up : Icons.play_arrow,
                  size: 28,
                ),
                label: Text(
                  _isPlaying ? 'กำลังเล่นเสียง...' : 'ฟังข้อความ',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D5F5F),
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
              
              if (_isPlaying)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFF2D5F5F),
                      ),
                    ),
                  ),
                ),
              
              const Spacer(flex: 2),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      const Text(
                        'อยากเล่า',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _onStoryTellingSelected,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4CAF50).withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(width: 60),
                  
                  Column(
                    children: [
                      const Text(
                        'ไม่อยากเล่า',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _onQuestionSetSelected,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF44336),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF44336).withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}

class StoryTellingWithQuestionFlow extends StatefulWidget {
  const StoryTellingWithQuestionFlow({super.key});

  @override
  State<StoryTellingWithQuestionFlow> createState() => _StoryTellingWithQuestionFlowState();
}

class _StoryTellingWithQuestionFlowState extends State<StoryTellingWithQuestionFlow> {
  bool _storyTellingDone = false;

  @override
  Widget build(BuildContext context) {
    if (!_storyTellingDone) {
      return StoryTellingPage(
        onComplete: () {
          setState(() {
            _storyTellingDone = true;
          });
        },
      );
    } else {
      return const QuestionSetPage();
    }
  }
}