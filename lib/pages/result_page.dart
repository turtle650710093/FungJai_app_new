import 'dart:io';
import 'dart:async';
import 'dart:math'; // ✅ เพิ่มบรรทัดนี้
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:fungjai_app_new/services/prediction_result.dart';
import 'package:url_launcher/url_launcher.dart';

class ResultPage extends StatefulWidget {
  final PredictionResult analysisResult;
  final bool isLastQuestion;
  final VoidCallback onNext;
  final bool isFromStoryTelling;

  const ResultPage({
    super.key,
    required this.analysisResult,
    required this.isLastQuestion,
    required this.onNext,
    this.isFromStoryTelling = false,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isPlayingAudio = false;
  bool _hasPlayedOnce = false; // ✅ เพิ่ม flag เช็คว่าเคยเล่นแล้ว
  bool _isDisposed = false;
  
  String _comfortMessage = '';
  String? _audioFilePath;
  int _selectedMessageIndex = 0;
  
  // ✅ เพิ่มตัวแปรเก็บกิจกรรมที่สุ่มแล้ว
  Map<String, String>? _selectedActivity;

  @override
  void initState() {
    super.initState();
    _selectRandomMessage();
    _selectRandomActivity(); // ✅ สุ่มกิจกรรมครั้งเดียว
    _initAudio();
  }

  @override
  void dispose() {
    print('ResultPage: Disposing...');
    _isDisposed = true;
    _audioPlayer.dispose();
    print('ResultPage: Disposed successfully');
    super.dispose();
  }

  // สุ่มข้อความและกำหนดไฟล์เสียงคู่กัน
  void _selectRandomMessage() {
    final random = Random();
    final emotion = widget.analysisResult.emotion.toLowerCase();

    final messageList = _getComfortMessageList(emotion);
    _selectedMessageIndex = random.nextInt(messageList.length);
    _comfortMessage = messageList[_selectedMessageIndex]['text']!;
    _audioFilePath = messageList[_selectedMessageIndex]['audio']!;
    
    print('📝 Emotion: $emotion');
    print('📝 Selected message index: $_selectedMessageIndex');
    print('📝 Message: $_comfortMessage');
    print('🔊 Audio file: $_audioFilePath');
  }

  // ✅ สุ่มกิจกรรมครั้งเดียว
  void _selectRandomActivity() {
    final emotion = widget.analysisResult.emotion.toLowerCase();
    final allActivities = _getActivities(emotion);
    
    if (allActivities.isEmpty) {
      _selectedActivity = null;
      print('❌ No activities for emotion: $emotion');
    } else {
      final random = Random();
      _selectedActivity = allActivities[random.nextInt(allActivities.length)];
      print('🎯 Selected activity: ${_selectedActivity!['name']}');
    }
  }

  // รายการข้อความและไฟล์เสียงคู่กัน
  List<Map<String, String>> _getComfortMessageList(String emotion) {
    final messages = {
      'happy': [
        {
          'text': 'ดีใจที่วันนี้ท่านมีความสุขนะคะ ความสุขของท่านเป็นพลังบวกที่ส่งต่อได้เสมอ',
          'audio': 'assets/audio/comfort/happy1.m4a',
        },
        {
          'text': 'รอยยิ้มของท่านวันนี้ช่างมีค่า อย่าลืมเก็บความสุขนี้ไว้ในใจนาน ๆ นะคะ',
          'audio': 'assets/audio/comfort/happy2.m4a',
        },
        {
          'text': 'วันนี้ท่านมีแววตาแห่งความสุขอยู่ ขอให้ความสุขนี้อยู่กับท่านไปอีกนานนะคะ',
          'audio': 'assets/audio/comfort/happy3.m4a',
        },
        {
          'text': 'ขอบคุณที่แบ่งปันความสุขของท่านกับเรา ความสุขของท่านมีคุณค่าเสมอค่ะ',
          'audio': 'assets/audio/comfort/happy4.m4a',
        },
      ],
      'sad': [
        {
          'text': 'บางวันอาจไม่สดใส แต่ท่านไม่ได้อยู่คนเดียวนะคะ ฟังใจอยู่ตรงนี้เสมอ',
          'audio': 'assets/audio/comfort/sad1.m4a',
        },
        {
          'text': 'ทุกความเศร้าเป็นเพียงช่วงเวลาหนึ่ง ลองหากิจกรรมที่ชอบและผ่อนคลาย',
          'audio': 'assets/audio/comfort/sad2.m4a',
        },
        {
          'text': 'ท่านสามารถร้องไห้หรือพักใจได้เต็มที่นะคะ เพราะเราทุกคนมีสิทธิ์ที่จะรู้สึกเช่นนั้น',
          'audio': 'assets/audio/comfort/sad3.m4a',
        },
        {
          'text': 'วันไหนที่รู้สึกเศร้า เราแค่อยากให้ท่านรู้ว่าท่านยังมีค่าในทุกช่วงเวลา',
          'audio': 'assets/audio/comfort/sad4.m4a',
        },
      ],
      'angry': [
        {
          'text': 'รู้ว่าบางเรื่องอาจทำให้ไม่สบายใจ ลองฝึกลมหายใจและให้ตัวเองได้พักนะคะ',
          'audio': 'assets/audio/comfort/angry1.m4a',
        },
        {
          'text': 'ท่านเก่งมากที่กล้าเผชิญกับความรู้สึกนั้น ขอเป็นกำลังใจให้ผ่านมันไปได้ค่ะ',
          'audio': 'assets/audio/comfort/angry2.m4a',
        },
        {
          'text': 'อารมณ์โกรธเป็นสิ่งที่มนุษย์ทุกคนมี ขอบคุณที่กล้าเผชิญกับความรู้สึกนั้นค่ะ',
          'audio': 'assets/audio/comfort/angry3.m4a',
        },
        {
          'text': 'ขอให้ความไม่สบายใจนี้ค่อย ๆ คลายลงในแบบของท่านเองนะคะ',
          'audio': 'assets/audio/comfort/angry4.m4a',
        },
      ],
      'neutral': [
        {
          'text': 'ขอบคุณที่มาใช้เวลากับฟังใจ แม้วันนี้จะธรรมดา แต่ทุกวันของท่านมีความหมายเสมอค่ะ',
          'audio': 'assets/audio/comfort/neutral1.m4a',
        },
        {
          'text': 'บางวันอาจดูเงียบ ๆ แต่การดูแลใจตนเองก็เป็นสิ่งสำคัญเช่นกันนะคะ',
          'audio': 'assets/audio/comfort/neutral2.m4a',
        },
        {
          'text': 'ถึงวันนี้จะดูธรรมดา แต่อย่าลืมว่าคุณได้ทำดีที่สุดในแบบของคุณแล้วนะคะ',
          'audio': 'assets/audio/comfort/neutral3.m4a',
        },
        {
          'text': 'ขอให้วันนี้ของท่านเต็มไปด้วยความสงบ และพลังใจที่เบาและสบาย',
          'audio': 'assets/audio/comfort/neutral4.m4a',
        },
      ],
      'frustrated': [
        {
          'text': 'ไม่เป็นไรเลยนะคะ คุณทำดีที่สุดแล้ว ไม่ต้องรีบร้อนจนเกินไปค่ะ',
          'audio': 'assets/audio/comfort/frustrated1.m4a',
        },
        {
          'text': 'แม้ใจจะไม่สงบในบางวัน แต่คุณมีคุณค่าเสมอ พักใจตรงนี้ก่อนนะคะ',
          'audio': 'assets/audio/comfort/frustrated2.m4a',
        },
        {
          'text': 'ทุกความกังวลคือการแสดงว่าคุณใส่ใจ ขอให้คุณได้หยุดพักและรู้ว่าคุณไม่ได้เดินลำพัง',
          'audio': 'assets/audio/comfort/frustrated3.m4a',
        },
        {
          'text': 'ลองพักหายใจสักช่วงเวลาหนึ่ง ถ้าดีขึ้นแล้วค่อยก้าวต่อไปค่ะ',
          'audio': 'assets/audio/comfort/frustrated4.m4a',
        },
      ],
    };

    return messages[emotion] ?? [
      {
        'text': 'ดูแลสุขภาพจิตใจให้ดีนะคะ',
        'audio': 'assets/audio/comfort/default.m4a',
      }
    ];
  }

  // ตั้งค่า AudioPlayer
  Future<void> _initAudio() async {
    // ✅ ฟัง state changes และจัดการ completed state
    _audioPlayer.playerStateStream.listen((state) {
      if (!mounted || _isDisposed) return;
      
      // ✅ เช็ค completed ก่อน - เมื่อเล่นจบให้เปลี่ยนเป็น replay
      if (state.processingState == ProcessingState.completed) {
        print('✅ Audio playback completed');
        if (mounted && !_isDisposed) {
          setState(() {
            _isPlayingAudio = false;
            _hasPlayedOnce = true; // ✅ บันทึกว่าเคยเล่นแล้ว
          });
        }
      } else {
        if (mounted && !_isDisposed) {
          setState(() {
            _isPlayingAudio = state.playing;
          });
        }
      }
    });

    // ✅ ลบ auto-play ออก - ให้ผู้ใช้กดเอง
  }

  // เล่นไฟล์เสียงปลอบประโลม
  Future<void> _playComfortAudio() async {
    if (_audioFilePath == null || _isDisposed) {
      print('❌ No audio file path or disposed');
      return;
    }

    try {
      print('🔊 Playing comfort audio: $_audioFilePath');
      
      await _audioPlayer.stop();
      await _audioPlayer.setAsset(_audioFilePath!);
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play();
      
      if (mounted && !_isDisposed) {
        setState(() {
          _isPlayingAudio = true;
          _hasPlayedOnce = true;
        });
      }
      
      print('✅ Audio playback started');
      
    } catch (e, stackTrace) {
      print('❌ Error playing audio: $e');
      print('   Stack trace: $stackTrace');
      
      if (mounted && !_isDisposed) {
        setState(() {
          _isPlayingAudio = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถเล่นไฟล์เสียงได้\nไฟล์: $_audioFilePath'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // หยุดเสียง
  Future<void> _stopComfortAudio() async {
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
      print('❌ Error stopping audio: $e');
    }
  }

  String _translateEmotion(String emotion) {
    const emotionMap = {
      'happy': 'มีความสุข',
      'sad': 'เศร้า',
      'angry': 'โกรธ',
      'neutral': 'รู้สึกเฉยๆ',
      'frustrated': 'หงุดหงิด',
    };
    return emotionMap[emotion.toLowerCase()] ?? emotion;
  }

  @override
  Widget build(BuildContext context) {
    final topEmotion = widget.analysisResult.emotion;
    final emotionIcon = _getEmotionIcon(topEmotion);
    final emotionColor = _getEmotionColor(topEmotion);

    return WillPopScope(
      onWillPop: () async {
        print('⬅️ ResultPage: Back button pressed');
        await _stopComfortAudio();
        await Future.delayed(const Duration(milliseconds: 200));
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFBF5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: const Color(0xFF2D5F5F),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),

                // Emotion Result
                Icon(emotionIcon, size: 80, color: emotionColor),
                const SizedBox(height: 16),
                Text(
                  'วันนี้คุณรู้สึก',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  _translateEmotion(topEmotion),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),

                const SizedBox(height: 24),

                // Comfort Message Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: emotionColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: emotionColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Icon เสียง
                      if (_isPlayingAudio)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Icon(
                            Icons.volume_up,
                            color: emotionColor,
                            size: 32,
                          ),
                        ),
                      
                      // Message Text
                      Text(
                        _comfortMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                      
                      // Status indicator
                      if (_isPlayingAudio)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: emotionColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'กำลังเล่นเสียง...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: emotionColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ✅ ปุ่มควบคุมเสียง - เปลี่ยนเป็น "ฟังอีกครั้ง" เมื่อเล่นจบ
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ปุ่มเล่น/ฟังอีกครั้ง
                    if (!_isPlayingAudio)
                      ElevatedButton.icon(
                        onPressed: _playComfortAudio,
                        icon: Icon(
                          _hasPlayedOnce ? Icons.replay : Icons.play_arrow,
                          size: 22,
                        ),
                        label: Text(
                          _hasPlayedOnce ? 'ฟังอีกครั้ง' : 'ฟังข้อความ',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: emotionColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                      ),

                    // ปุ่มหยุด
                    if (_isPlayingAudio)
                      ElevatedButton.icon(
                        onPressed: _stopComfortAudio,
                        icon: const Icon(Icons.stop, size: 22),
                        label: const Text(
                          'หยุดเสียง',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 32),

                // Activities Section
                if (_selectedActivity != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: emotionColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'กิจกรรมแนะนำ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D5F5F),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildActivityCard(
                    _selectedActivity!['name']!,
                    _selectedActivity!['icon']!,
                    _selectedActivity!['url']!,
                    emotionColor,
                    context,
                  ),
                ],

                const SizedBox(height: 32),

                // Next Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _handleNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D5F5F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      widget.isLastQuestion ? 'ดูสรุปผล' : 'คำถามถัดไป',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleNext() async {
    print('➡️ ResultPage: Navigating to next page...');
    
    await _stopComfortAudio();
    await Future.delayed(const Duration(milliseconds: 200));
    
    widget.onNext();
  }

  Widget _buildActivityCard(
    String name,
    String icon,
    String url,
    Color color,
    BuildContext context,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          await _stopComfortAudio();
          await Future.delayed(const Duration(milliseconds: 200));
          
          try {
            await _launchURL(url);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('ไม่สามารถเปิดลิงก์ได้: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.play_circle_outline, color: color, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('ไม่สามารถเปิดลิงก์ได้: $url');
    }
  }

  IconData _getEmotionIcon(String emotion) {
    const icons = {
      'happy': Icons.sentiment_very_satisfied_rounded,
      'sad': Icons.sentiment_very_dissatisfied_rounded,
      'angry': Icons.sentiment_dissatisfied_rounded,
      'neutral': Icons.sentiment_neutral_rounded,
      'frustrated': Icons.sentiment_dissatisfied_rounded,
    };
    return icons[emotion.toLowerCase()] ?? Icons.self_improvement_rounded;
  }

  Color _getEmotionColor(String emotion) {
    const colors = {
      'happy': Color(0xFF4CAF50),
      'sad': Colors.blueGrey,
      'angry': Colors.red,
      'neutral': Colors.teal,
      'frustrated': Colors.orange,
    };
    return colors[emotion.toLowerCase()] ?? Colors.teal;
  }

  // ✅ ลบฟังก์ชัน _getRandomActivity ออก เพราะเราสุ่มใน initState แล้ว

  List<Map<String, String>> _getActivities(String emotion) {
    final activities = {
      'happy': [
        {'name': 'เต้นแอโรบิคสนุกๆ', 'url': 'https://www.youtube.com/watch?v=gCzgc_RelEg', 'icon': '💃'},
        {'name': 'ทำอาหารเมนูโปรด', 'url': 'https://www.youtube.com/watch?v=h-nRx6O4Bis', 'icon': '🍳'},
        {'name': 'ฟังเพลงสนุกๆ', 'url': 'https://www.youtube.com/watch?v=Zi_XLOBDo_Y', 'icon': '🎵'},
      ],
      'sad': [
        {'name': 'สมาธิบำบัด ผ่อนคลายจิตใจ', 'url': 'https://www.youtube.com/watch?v=inpok4MKVLM', 'icon': '🧘'},
        {'name': 'ฟังเพลงเบาๆ ผ่อนคลาย', 'url': 'https://www.youtube.com/watch?v=lTRiuFIWV54', 'icon': '🎶'},
        {'name': 'ดูหนังตลก', 'url': 'https://www.youtube.com/watch?v=f3OWi1huY0k', 'icon': '😂'},
      ],
      'angry': [
        {'name': 'หายใจลึกๆ คลายความโกรธ', 'url': 'https://www.youtube.com/watch?v=DbDoBzGY3vo', 'icon': '😮‍💨'},
        {'name': 'โยคะผ่อนคลาย', 'url': 'https://www.youtube.com/watch?v=v7AYKMP6rOE', 'icon': '🧘‍♀️'},
        {'name': 'เดินเล่นในธรรมชาติ', 'url': 'https://www.youtube.com/watch?v=d5gUsc4M7I8', 'icon': '🌳'},
      ],
      'neutral': [
        {'name': 'ยืดเส้นยืดสายเบาๆ', 'url': 'https://www.youtube.com/watch?v=qULTwquOuT4', 'icon': '🤸'},
        {'name': 'ฟังธรรมะ ปลอบประโลมจิตใจ', 'url': 'https://www.youtube.com/watch?v=XqkLeT6Z7mQ', 'icon': '🙏'},
        {'name': 'งานฝีมือง่ายๆ', 'url': 'https://www.youtube.com/watch?v=0pVhrLXUU4k', 'icon': '✂️'},
      ],
      'frustrated': [
        {'name': 'ผ่อนคลายความเครียด', 'url': 'https://www.youtube.com/watch?v=86HUcX8ZtAk', 'icon': '😌'},
        {'name': 'นวดตัวเองง่ายๆ', 'url': 'https://www.youtube.com/watch?v=3LTvOLmhZNQ', 'icon': '💆'},
        {'name': 'ดูทิวทัศน์สวยงาม', 'url': 'https://www.youtube.com/watch?v=1ZYbU82GVz4', 'icon': '🏞️'},
      ],
    };

    return activities[emotion.toLowerCase()] ?? [];
  }
}