import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class RecordingPage extends StatefulWidget {
  const RecordingPage({super.key});

  @override
  State<RecordingPage> createState() => _RecordingPageState();
}

class _RecordingPageState extends State<RecordingPage> {
  FlutterSoundRecorder? _recorder;
  bool _isRecorderInitialized = false;
  bool _isRecording = false;
  String? _filePath;
  late DateTime _recordingStartTime;

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('โปรดอนุญาตการเข้าถึงไมโครโฟนในตั้งค่า')),
      );
      return;
    }
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
    setState(() {
      _isRecorderInitialized = true;
    });
    print('✅ Recorder initialized!');
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (!_isRecorderInitialized) return;

    final dir = await getApplicationDocumentsDirectory();
    _filePath = '${dir.path}/record_${DateTime.now().millisecondsSinceEpoch}.wav';
    _recordingStartTime = DateTime.now();
    await _recorder!.startRecorder(
      toFile: _filePath,
      codec: Codec.pcm16WAV,
      sampleRate: 16000,
      numChannels: 1,
    );

    setState(() {
      _isRecording = true;
    });
    print('✅ Recording started... Path: $_filePath');
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    final elapsed = DateTime.now().difference(_recordingStartTime);
    if (elapsed.inMilliseconds < 900) { // < 0.9 วินาที
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาบันทึกเสียงอย่างน้อย 1 วินาที')),
      );
      return;
    }
    await _recorder!.stopRecorder();

    setState(() {
      _isRecording = false;
    });

    if (_filePath != null) {
      final file = File(_filePath!);
      final length = await file.length();
      print('🟩 File length: $length bytes');
      if (length <= 44) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('การบันทึกเสียงล้มเหลว กรุณาลองใหม่อีกครั้ง'), backgroundColor: Colors.red),
        );
      } else {
        // TODO: ส่งไฟล์ต่อไปวิเคราะห์ หรือทำอย่างอื่น
        print('🎉 ได้ไฟล์เสียงพร้อมใช้งาน!');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('บันทึกเสียง'),
      ),
      backgroundColor: const Color(0xFFF5F5DC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_isRecording ? 'กำลังบันทึก...' : 'พร้อมบันทึกเสียง',
                style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              onPressed: !_isRecorderInitialized
                  ? null
                  : (_isRecording ? _stopRecording : _startRecording),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isRecording ? Colors.red : const Color(0xFF1B7070),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
                textStyle: const TextStyle(fontSize: 20),
              ),
              label:
                  Text(_isRecording ? 'หยุด' : 'เริ่มบันทึก', style: const TextStyle(fontFamily: 'Kanit')),
            ),
            const SizedBox(height: 40),
            if (!_isRecording && _filePath != null)
              Text(
                'ไฟล์: $_filePath',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}