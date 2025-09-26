import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class QuestionPage extends StatefulWidget {
  const QuestionPage({super.key});

  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  final List<List<String>> questionSets = [
    [
      "ในวัยเด็กคุณชอบทำกิจกรรมอะไรกับเพื่อนมากที่สุด?",
      "มีสถานที่ไหนในวัยเด็กที่คุณชอบไปบ่อยๆ เพราะอะไร?",
      "มีของเล่นชิ้นไหนที่คุณผูกพันเป็นพิเศษ?",
      "เคยได้รับของขวัญชิ้นที่ประทับใจที่สุดในวัยเด็กไหม? เล่าให้ฟังหน่อย",
      "หากย้อนเวลากลับไปได้หนึ่งวันในวัยเด็ก คุณอยากกลับไปวันที่ไหน? และทำไมถึงเลือกวันนั้น?"
    ],
    [
      "ใครคือคนที่คุณรู้สึกผูกพันมากที่สุดในชีวิต?",
      "คุณจำได้ไหมว่าเคยมีช่วงเวลาประทับใจอะไรกับเขา?",
      "มีคำพูดไหนจากเขาที่คุณยังจำได้จนถึงวันนี้?",
      "เมื่อคิดถึงเขาตอนนี้ คุณรู้สึกอยางไร?",
      "ถ้าเขาอยู่ตรงหน้าคุณตอนนี้ คุณอยากพูดอะไรกับเขา?"
    ],
    [
      "คุณเคยเจอเหตุการณสำคัญอะไรในชีวิตที่เปลี่ยนคุณไปมากที่สุด?",
      "ตอนนั้นคุณรู้สึกยังไง? กลัว ตื่นเตน หรือมีความหวัง?",
      "คุณจัดการกับความรู้สึกในช่วงเวลานั้นอย่างไร?",
      "คุณได้เรียนรู้อะไรจากเหตุการณนั้นบ้าง?",
      "ถาให้ย้อนกลับไปอีกครั้ง คุณจะเลือกทำแบบเดิมไหม? เพราะอะไร?"
    ],
    [
      "บ้านหลังแรกที่คุณอยูเป็นแบบไหน?",
      "จำรายละเอียดไดไหม?",
      "มื้ออาหารกับครอบครัวที่คุณประทับใจที่สุดคือมื้อไหน?",
      "คุณมีบทบาทหรือหนาที่อะไรในบานตอนนั้น?",
      "มีใครในครอบครัวที่คอยดูแลและเป็นแบบอยางใหคุณบ้าง?",
      "ถ้าพูดถึงคำวา “บ้าน” ตอนนี้ คุณนึกถึงอะไรเป็นอย่างแรก?"
    ],
  ];

  final Map<String, Map<String, dynamic>> emotionDetails = {
    'มีความสุข': {
      'advice': [
        'ดีใจที่วันนี้คุณมีความสุขนะคะ ความสุขของคุณเป็นพลังบวกที่ส่งต่อได้เสมอ',
        'รอยยิ้มของคุณวันนี้ช่างมีค่า อย่าลืมเก็บความสุขนี้ไว้ในใจนาน ๆ นะคะ',
        'วันนี้คุณมีแววตาแห่งความสุขอยู่ ขอให้ความสุขนี้อยู่กับคุณไปอีกนานนะคะ',
        'ขอบคุณที่แบ่งปันความสุขของคุณกับเรา ความสุขของคุณมีค่าเสมอค่ะ'
      ],
      'activity': [
        {
          'title': 'รำไท้เก๊ก',
          'url': 'https://youtu.be/R_5aIeDlxyg?si=QOIToThLV2Kb4yWz'
        },
        {
          'title': 'โยคะ',
          'url': 'https://youtu.be/CnKnvqxaAeU?si=dhR2wz9GkvsIgyJr'
        },
        {
          'title': 'เดิน',
          'url': 'https://youtube.com/shorts/beg2Omcm6xI?si=4RW_MuJz0ZpeZj2l'
        },
        {
          'title': 'breathing exercises 478',
          'url': 'https://youtube.com/shorts/de7miRvSqIc?si=xMQxDnEzXsezX6k0'
        }
      ]
    },
    'เศร้า': {
      'advice': [
        'บางวันอาจไม่สดใส แต่คุณไม่ได้อยู่คนเดียวนะคะ ฉันอยู่ตรงนี้เสมอ',
        'ทุกความเศร้าเป็นเพียงช่วงเวลาหนึ่ง ลองหากิจกรรมที่ชอบและผ่อนคลาย',
        'คุณสามารถร้องไห้หรือพักใจได้เต็มที่นะคะ เพราะคุณมีสิทธิ์ที่จะรูสึกเช่นนั้น',
        'วันไหนที่รู้สึกเศร้า เราแค่อยากให้คุณรู้ว่าคุณยังมีค่ามากในทุกช่วงเวลา'
      ],
      'activity': [
        {
          'title': 'ฟังเพลงที่ชอบ',
          'url': 'https://www.youtube.com/watch?v=oHg5SJYRHA0'
        },
        {
          'title': 'วาดรูประบายอารมณ์',
          'url': 'https://www.youtube.com/watch?v=YMJUMY7_D4g'
        },
        {
          'title': 'ฝึกหายใจคลายเครียด',
          'url': 'https://www.youtube.com/watch?v=nmFUDkj1Aq0'
        },
      ]
    },

    'โกรธ': {
      'advice': [
        'รู้ว่าบางเรื่องอาจทำให้ไม่สบายใจ ลองฝึกลมหายให้ตัวเองได้พักนะคะ',
        'คุณเก่งมากที่กล้าเผชิญกับความรู้สึกนั้น ขอเป็นกำลังใจให้ผ่านมันไปได้คะ',
        'อารมณ์โกรธเป็นสิ่งที่มนุษยทุกคนมี ขอบคุณที่กล้าเผชิญกับความรู้สึกนั้นค่ะ',
        'ขอใหความไม่สบายใจนี้คอย ๆ คลายลงในแบบของคุณเองนะคะ'
      ],
      'activity': [
        {
          'title': 'ออกกำลังกายเบา ๆ',
          'url': 'https://www.youtube.com/watch?v=X655B4ISakg'
        },
        {
          'title': 'ฝึกสมาธิเพื่อสงบใจ',
          'url': 'https://www.youtube.com/watch?v=inpok4MKVLM'
        },
      ]
    },
    'ปกติ': {
      'advice': [
        'ขอบคุณที่มาใช้เวลากับเรา แม้วันนี้จะธรรมดา แต่ทุกวันของคุณมีความหมายเสมอค่ะ',
        'บางวันอาจดูเงียบ ๆ แต่การดูแลใจตนเองก็เป็นสิ่งสำคัญเช่นกันนะคะ',
        'ถึงวันนี้จะดูธรรมดา แต่อย่าลืมว่าคุณได้ทำดีที่สุดในแบบของคุณแล้วนะคะ',
        'ขอใหวันนี้ของคุณเต็มไปดวยความสงบ และพลังใจที่เบาและสบาย'
      ],
      'activity': [
        {
          'title': 'จิบชาเบาๆ',
          'url': 'https://www.youtube.com/watch?v=TY8KLM2d9aQ'
        },
        {
          'title': 'เปิดเพลงสบายใจ',
          'url': 'https://www.youtube.com/watch?v=2Vv-BfVoq4g'
        },
      ],
    },
    'หงุดหงิด': {
      'advice': [
        'ไม่เป็นไรเลยนะคะ คุณทำดีที่สุดแล้ว ไม่ต้องรีบร้อนจนเกินไปค่ะ',
        'แม้ใจจะไม่สงบในบางวัน แต่คุณมีคุณค่าเสมอ พักใจตรงนี้ก่อนนะคะ',
        'ทุกความกังวลคือการแสดงวาคุณใส่ใจ/nขอให้คุณได้หยุดพักและรู้ว่าคุณไม่ได้เดินลำพัง',
        'ลองพักหายใจสักช่วงเวลาหนึ่ง ถ้าดีขึ้นแล้วค่อยก้าวต่อไปค่ะ'
      ],
      'activity': [
        {
          'title': 'ฝึก breathing mindfulness',
          'url': 'https://www.youtube.com/watch?v=v2mYtwbULuI'
        },
        {
          'title': 'โยคะคลายกล้ามเนื้อ',
          'url': 'https://www.youtube.com/watch?v=4pLUleLdwY4'
        },
      ],
    },
  };

  String? _mood;
  String? _advice;
  Map<String, String>? _activity;
  bool _analyzing = false;

  late int setIndex;
  int questionIndex = 0;

  FlutterSoundRecorder? _recorder;
  bool _isRecorderInitialized = false;
  bool _isRecording = false;
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    setIndex = Random().nextInt(questionSets.length);
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
    setState(() {
      _isRecorderInitialized = true;
    });
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (!_isRecorderInitialized) return;
    final dir = await getApplicationDocumentsDirectory();
    _audioPath = '${dir.path}/question_${setIndex}_${questionIndex}_${DateTime.now().millisecondsSinceEpoch}.wav';
    await _recorder!.startRecorder(
      toFile: _audioPath,
      codec: Codec.pcm16WAV,
      sampleRate: 16000,
      numChannels: 1,
    );
    setState(() {
      _isRecording = true;
      _mood = null;
      _advice = null;
      _activity = null;
      _analyzing = false;
    });
  }

  Future<void> _stopRecording() async {
    await _recorder!.stopRecorder();
    setState(() {
      _isRecording = false;
    });
  }

  // วิเคราะห์อารมณ์และสุ่มแนะนำ + กิจกรรม
  Future<void> _analyzeEmotion() async {
    if (_audioPath == null) return;
    setState(() {
      _analyzing = true;
      _mood = null;
      _advice = null;
      _activity = null;
    });
    await Future.delayed(const Duration(seconds: 2));
    // สมมุติสุ่มอารมณ์
    final moods = emotionDetails.keys.toList();
    final mood = moods[Random().nextInt(moods.length)];
    final advices = emotionDetails[mood]!['advice'] as List;
    final activities = emotionDetails[mood]!['activity'] as List;
    final pickAdvice = advices[Random().nextInt(advices.length)];
    final pickActivity = Map<String, String>.from(activities[Random().nextInt(activities.length)]);
    setState(() {
      _mood = mood;
      _advice = pickAdvice;
      _activity = pickActivity;
      _analyzing = false;
    });
  }

  void _nextQuestion() {
    setState(() {
      if (questionIndex < 4) {
        questionIndex++;
        _audioPath = null;
        _mood = null;
        _advice = null;
        _activity = null;
        _analyzing = false;
      } else {
        // จบชุดคำถาม
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("จบชุดคำถามแล้ว!"),
            content: const Text("ขอบคุณที่ตอบคำถาม 💛"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // ปิด dialog
                  Navigator.of(context).pop(); // กลับหน้าหลัก
                },
                child: const Text("กลับหน้าหลัก"),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final questions = questionSets[setIndex];
    final question = questions[questionIndex];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B7070),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF9F1E7),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                question,
                style: const TextStyle(fontSize: 22, fontFamily: 'Kanit'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                label: Text(_isRecording ? 'หยุดบันทึก' : 'บันทึกเสียง'),
                onPressed: !_isRecorderInitialized
                    ? null
                    : (_isRecording ? _stopRecording : _startRecording),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording
                      ? Colors.red
                      : const Color(0xFF1B7070),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  textStyle: const TextStyle(fontSize: 18, fontFamily: 'Kanit'),
                ),
              ),
              const SizedBox(height: 16),

              if (_audioPath != null && !_isRecording && _mood == null)
                ElevatedButton.icon(
                  label: const Text("วิเคราะห์อารมณ์"),
                  onPressed: _analyzing ? null : _analyzeEmotion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16, fontFamily: 'Kanit'),
                  ),
                ),
              if (_analyzing)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(),
                ),
              if (_mood != null && !_analyzing)
                Column(
                  children: [
                    Text(
                      "$_mood",
                      style: const TextStyle(fontSize: 20, color: Colors.teal, fontFamily: 'Kanit', fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _advice ?? '-',
                      style: const TextStyle(fontSize: 18, color: Colors.black87, fontFamily: 'Kanit'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    if (_activity != null) ...[
                      Text(
                        "ลองกิจกรรมนี้ดูสิ",
                        style: const TextStyle(fontSize: 16, color: Colors.indigo, fontFamily: 'Kanit'),
                        textAlign: TextAlign.center,
                      ),
                      InkWell(
                        onTap: () async {
                          final url = Uri.parse(_activity!['url']!);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        },
                        child: Text(
                          _activity!['title']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                            fontFamily: 'Kanit'
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                  ],
                ),

              if (_mood != null && !_analyzing)
                ElevatedButton(
                  onPressed: _nextQuestion,
                  child: Text(questionIndex == 4 ? "จบชุดคำถาม" : "ถัดไป"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B7070),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    textStyle: const TextStyle(fontSize: 18, fontFamily: 'Kanit'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}