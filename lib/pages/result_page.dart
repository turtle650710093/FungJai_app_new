import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:fungjai_app_new/services/prediction_result.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

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
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  bool _ttsReady = false;
  bool _hasSpokenOnce = false;
  bool _thaiAvailable = false;
  String _comfortMessage = '';

  @override
  void initState() {
    super.initState();
    _comfortMessage = _getRandomComfortMessage(widget.analysisResult.emotion);
    _initTts();
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    print('ResultPage: Disposing...');
    _isDisposed = true;

    _tts.stop();
    _tts.setStartHandler(() {});
    _tts.setCompletionHandler(() {});
    _tts.setErrorHandler((msg) {});
    print('ResultPage: Disposed successfully');
    super.dispose();
  }

  Future<void> _initTts() async {
    try {
      print('ResultPage TTS: Starting initialization...');

      // รอให้ TTS Engine พร้อม (ลดเวลาลง)
      await Future.delayed(const Duration(milliseconds: 500));

      // Android Settings
      print('🤖 Configuring TTS...');
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);

      // เช็คภาษาที่มี
      final languages = await _tts.getLanguages;
      print('Available languages: $languages');

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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ เสียงภาษาไทยไม่พร้อมใช้งาน\nกรุณาติดตั้ง Thai TTS'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        setState(() => _ttsReady = false);
        return;
      }

      // ตั้งค่าเสียง
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);

      print('🔊 TTS Settings: Volume=1.0, Rate=0.45, Pitch=1.0');

      // Set handlers
      _tts.setStartHandler(() {
        print('ResultPage TTS: Started');
        if (mounted && !_isDisposed) {
        setState(() => _isSpeaking = true);
        }
      });

      _tts.setCompletionHandler(() {
        print('ResultPage TTS: Completed');
        if (mounted && !_isDisposed) {
          setState(() {
            _isSpeaking = false;
            _hasSpokenOnce = true; // เซ็ตว่าพูดแล้ว
          });
        }
      });

      _tts.setErrorHandler((msg) {
        print('ResultPage TTS Error: $msg');
        if (mounted && !_isDisposed) {
          setState(() => _isSpeaking = false);
          }
        });

        if (mounted && !_isDisposed) {
          setState(() => _ttsReady = true);
        }

      setState(() => _ttsReady = true);
      print('✅ ResultPage TTS: Ready');

      // รอสั้นๆ แล้วพูดเลย (ไม่ต้องรอนาน)
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Auto speak ครั้งเดียว
      if (!_hasSpokenOnce && _thaiAvailable) {
        print('🎤 Auto speaking message...');
        await _speakMessage();
      }

      if (mounted && !_isDisposed && !_hasSpokenOnce && _thaiAvailable) {
      await _speakMessage();
      }
      
    } catch (e) {
      print('ResultPage TTS Init Error: $e');
      setState(() => _ttsReady = false);
    }
  }

  Future<void> _speakMessage() async {
  if (!_ttsReady || !_thaiAvailable || _isDisposed) {
    return;
  }

  if (_isSpeaking || _hasSpokenOnce) {
    return;
  }

  try {
    final emotionText = _translateEmotion(widget.analysisResult.emotion);
    final fullMessage = 'วันนี้คุณรู้สึก$emotionText $_comfortMessage';
    
    print('Speaking: $fullMessage');
    
    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.45);
    
    final result = await _tts.speak(fullMessage);
    
    print('Speak result: $result');
    
    if (result != 1 && mounted && !_isDisposed) {
      setState(() => _hasSpokenOnce = true);
    }
  } catch (e) {
    print('Speak Error: $e');
    if (mounted && !_isDisposed) {
      setState(() => _hasSpokenOnce = true);
    }
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

  String _getRandomComfortMessage(String emotion) {
    final random = Random();

    final messages = {
      'happy': [
        'ดีใจที่วันนี้คุณมีความสุขนะคะ ความสุขของคุณเป็นพลังบวกที่ส่งต่อได้เสมอ',
        'รอยยิ้มของคุณวันนี้ช่างมีค่า อย่าลืมเก็บความสุขนี้ไว้ในใจนาน ๆ นะคะ',
        'วันนี้คุณมีแววตาแห่งความสุขอยู่ ขอให้ความสุขนี้อยู่กับคุณไปอีกนานนะคะ',
        'ขอบคุณที่แบ่งปันความสุขของคุณกับเรา ความสุขของคุณมีคุณค่าเสมอค่ะ',
      ],
      'sad': [
        'บางวันอาจไม่สดใส แต่คุณไม่ได้อยู่คนเดียวนะคะ ฉันอยู่ตรงนี้เสมอ',
        'ทุกความเศร้าเป็นเพียงช่วงเวลาหนึ่ง ลองหากิจกรรมที่ชอบและผ่อนคลาย',
        'คุณสามารถร้องไห้หรือพักใจได้เต็มที่นะคะ เพราะคุณมีสิทธิ์ที่จะรู้สึกเช่นนั้น',
        'วันไหนที่รู้สึกเศร้า เราแค่อยากให้คุณรู้ว่าคุณยังมีค่ามากในทุกช่วงเวลา',
      ],
      'angry': [
        'รู้ว่าบางเรื่องอาจทำให้ไม่สบายใจ ลองฝึกลมหายใจและให้ตัวเองได้พักนะคะ',
        'คุณเก่งมากที่กล้าเผชิญกับความรู้สึกนั้น ขอเป็นกำลังใจให้ผ่านมันไปได้ค่ะ',
        'อารมณ์โกรธเป็นสิ่งที่มนุษย์ทุกคนมี ขอบคุณที่กล้าเผชิญกับความรู้สึกนั้นค่ะ',
        'ขอให้ความไม่สบายใจนี้ค่อย ๆ คลายลงในแบบของคุณเองนะคะ',
      ],
      'neutral': [
        'ขอบคุณที่มาใช้เวลากับเรา แม้วันนี้จะธรรมดา แต่ทุกวันของคุณมีความหมายเสมอค่ะ',
        'บางวันอาจดูเงียบ ๆ แต่การดูแลใจตนเองก็เป็นสิ่งสำคัญเช่นกันนะคะ',
        'ถึงวันนี้จะดูธรรมดา แต่อย่าลืมว่าคุณได้ทำดีที่สุดในแบบของคุณแล้วนะคะ',
        'ขอให้วันนี้ของคุณเต็มไปด้วยความสงบ และพลังใจที่เบาและสบาย',
      ],
      'frustrated': [
        'ไม่เป็นไรเลยนะคะ คุณทำดีที่สุดแล้ว ไม่ต้องรีบร้อนจนเกินไปค่ะ',
        'แม้ใจจะไม่สงบในบางวัน แต่คุณมีคุณค่าเสมอ พักใจตรงนี้ก่อนนะคะ',
        'ทุกความกังวลคือการแสดงว่าคุณใส่ใจ ขอให้คุณได้หยุดพักและรู้ว่าคุณไม่ได้เดินลำพัง',
        'ลองพักหายใจสักช่วงเวลาหนึ่ง ถ้าดีขึ้นแล้วค่อยก้าวต่อไปค่ะ',
      ],
    };

    final messageList =
        messages[emotion.toLowerCase()] ?? ['ดูแลสุขภาพจิตใจให้ดีนะคะ'];
    return messageList[random.nextInt(messageList.length)];
  }

  List<Map<String, String>> _getActivities(String emotion) {
    final activities = {
      'happy': [
        {
          'name': 'เต้นแอโรบิคสนุกๆ',
          'url': 'https://www.youtube.com/watch?v=gCzgc_RelEg',
          'icon': '💃',
        },
        {
          'name': 'ทำอาหารเมนูโปรด',
          'url': 'https://www.youtube.com/watch?v=h-nRx6O4Bis',
          'icon': '🍳',
        },
        {
          'name': 'ฟังเพลงสนุกๆ',
          'url': 'https://www.youtube.com/watch?v=Zi_XLOBDo_Y',
          'icon': '🎵',
        },
      ],
      'sad': [
        {
          'name': 'สมาธิบำบัด ผ่อนคลายจิตใจ',
          'url': 'https://www.youtube.com/watch?v=inpok4MKVLM',
          'icon': '🧘',
        },
        {
          'name': 'ฟังเพลงเบาๆ ผ่อนคลาย',
          'url': 'https://www.youtube.com/watch?v=lTRiuFIWV54',
          'icon': '🎶',
        },
        {
          'name': 'ดูหนังตลก',
          'url': 'https://www.youtube.com/watch?v=f3OWi1huY0k',
          'icon': '😂',
        },
      ],
      'angry': [
        {
          'name': 'หายใจลึกๆ คลายความโกรธ',
          'url': 'https://www.youtube.com/watch?v=DbDoBzGY3vo',
          'icon': '😮‍💨',
        },
        {
          'name': 'โยคะผ่อนคลาย',
          'url': 'https://www.youtube.com/watch?v=v7AYKMP6rOE',
          'icon': '🧘‍♀️',
        },
        {
          'name': 'เดินเล่นในธรรมชาติ',
          'url': 'https://www.youtube.com/watch?v=d5gUsc4M7I8',
          'icon': '🌳',
        },
      ],
      'neutral': [
        {
          'name': 'ยืดเส้นยืดสายเบาๆ',
          'url': 'https://www.youtube.com/watch?v=qULTwquOuT4',
          'icon': '🤸',
        },
        {
          'name': 'ฟังธรรมะ ปลอบประโลมจิตใจ',
          'url': 'https://www.youtube.com/watch?v=XqkLeT6Z7mQ',
          'icon': '🙏',
        },
        {
          'name': 'งานฝีมือง่ายๆ',
          'url': 'https://www.youtube.com/watch?v=0pVhrLXUU4k',
          'icon': '✂️',
        },
      ],
      'frustrated': [
        {
          'name': 'ผ่อนคลายความเครียด',
          'url': 'https://www.youtube.com/watch?v=86HUcX8ZtAk',
          'icon': '😌',
        },
        {
          'name': 'นวดตัวเองง่ายๆ',
          'url': 'https://www.youtube.com/watch?v=3LTvOLmhZNQ',
          'icon': '💆',
        },
        {
          'name': 'ดูทิวทัศน์สวยงาม',
          'url': 'https://www.youtube.com/watch?v=1ZYbU82GVz4',
          'icon': '🏞️',
        },
      ],
    };

    return activities[emotion.toLowerCase()] ?? [];
  }

  Map<String, String>? _getRandomActivity(String emotion) {
    final allActivities = _getActivities(emotion);
    if (allActivities.isEmpty) return null;

    final random = Random();
    return allActivities[random.nextInt(allActivities.length)];
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

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('ไม่สามารถเปิดลิงก์ได้: $url');
    }
  }

  Future<void> _handleNext() async {
    print('➡️ ResultPage: Navigating to next page...');
    
    if (_isSpeaking) {
      await _tts.stop();
      await Future.delayed(const Duration(milliseconds: 200));
    }
    
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final topEmotion = widget.analysisResult.emotion;
    final activity = _getRandomActivity(topEmotion);
    final emotionIcon = _getEmotionIcon(topEmotion);
    final emotionColor = _getEmotionColor(topEmotion);

    return WillPopScope(
      onWillPop: () async {
        print('⬅️ ResultPage: Back button pressed');
        if (_isSpeaking) {
          await _tts.stop();
          await Future.delayed(const Duration(milliseconds: 200));
        }
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

                // Comfort Message
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
                      if (_isSpeaking)
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
                                'กำลังอ่าน...',
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

                // ปุ่มฟังอีกครั้ง (แสดงเฉพาะเมื่ออ่านเสร็จแล้ว)
                if (_ttsReady && _thaiAvailable && _hasSpokenOnce && !_isSpeaking)
                  ElevatedButton.icon(
                    onPressed: () async {
                      setState(() => _hasSpokenOnce = false);
                      await _speakMessage();
                    },
                    icon: const Icon(Icons.replay, size: 22),
                    label: const Text(
                      'ฟังอีกครั้ง',
                      style: TextStyle(
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

                const SizedBox(height: 32),

                // Activities Section
                if (activity != null) ...[
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
                    activity['name']!,
                    activity['icon']!,
                    activity['url']!,
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
          if (_isSpeaking) {
            await _tts.stop();
            await Future.delayed(const Duration(milliseconds: 200));
          }
          
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
}