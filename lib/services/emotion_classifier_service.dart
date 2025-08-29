import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';


class EmotionClassifierService {
  late Interpreter _interpreter;
  late List<String> _labels;

  EmotionClassifierService() {
    _loadModel();
  }

  Future<void> _loadModel() async {
    // โหลด labels จาก assets
    final labelsData = await rootBundle.loadString('assets/models/labels.txt');
    _labels = labelsData.split('\n').where((label) => label.isNotEmpty).toList();

    // โหลดโมเดล TFLite
    _interpreter = await Interpreter.fromAsset('assets/models/emotion_model.tflite'); 
    print('✅ Model and labels loaded successfully');
  }

  Future<List<List<List<double>>>> _preprocessAudio(String audioPath) async {
    // 1. อ่านไฟล์เสียง (เช่น .wav)
    // ใช้ package อย่าง 'wav' หรือ 'sound' เพื่ออ่านข้อมูลเสียงเป็น Float32List
    // final audioBytes = await File(audioPath).readAsBytes();
    // final wav = Wav.read(audioBytes);
    // final audioSamples = wav.toMono(); // แปลงเป็น Mono

    // 2. สกัด MFCCs
    // นี่คือส่วนที่ต้องใช้ library เฉพาะทาง เช่น `fftea` หรือเทียบเท่า
    // คุณต้องตั้งค่า n_mfcc, n_fft, hop_length ให้เหมือนตอนเทรนเป๊ะๆ
    // final mfccs = calculateMfccs(audioSamples, n_mfcc: 40, ...);

    // 3. Reshape ข้อมูลให้ตรงกับ Input ของโมเดล
    // โมเดลส่วนใหญ่มักจะรับ input shape [1, n_mfcc, time_steps, 1]
    // final reshapedMfccs = reshape(mfccs, [1, 40, 173, 1]); // << ตัวเลขเป็นแค่ตัวอย่าง
    
    // *** เนื่องจากส่วนนี้ซับซ้อนมาก เราจะจำลองผลลัพธ์ไปก่อนเพื่อให้เห็นภาพรวม ***
    // ในโปรเจคจริง คุณต้อง implement ส่วนนี้ให้สมบูรณ์
    // ตัวอย่างการสร้างข้อมูลจำลอง
    // ในที่นี้สมมติว่า input shape คือ [1, 40, 173, 1]
    final inputShape = _interpreter.getInputTensor(0).shape; // [1, 40, 173, 1]
    final dummyInput = List.generate(
      inputShape[0],
      (_) => List.generate(
        inputShape[1],
        (_) => List.generate(inputShape[2], (_) => [0.5]), // [0.5] for the channel
      ),
    );
    // แปลงเป็นชนิดข้อมูลที่ถูกต้อง (มักจะเป็น Float32)
    var processedInput = dummyInput.map((plane) => plane.map((row) => List<double>.from(row)).toList()).toList();
    // เมื่อคุณทำส่วนสกัด MFCCs จริงๆ คุณจะต้องแทนที่ dummy data นี้ด้วยข้อมูลจริง
    // return reshapedMfccs;
    
    // ขออภัยที่ต้องใช้ข้อมูลจำลอง แต่การสกัด MFCC ใน Dart เป็นเรื่องขั้นสูง
    // ที่ต้องใช้เวลาศึกษาเพิ่มเติมครับ
    print("⚠️  Warning: Using dummy data for preprocessing.");
    // สำหรับตอนนี้เราจะคืนค่าข้อมูลจำลองที่แปลงเป็น dynamic list เพื่อให้ TFLite รับได้
    return dummyInput.cast<List<List<double>>>();
  }

  Future<Map<String, double>> predict(String audioPath) async {
    // 1. Preprocess the audio file to get MFCCs
    // var input = await _preprocessAudio(audioPath); 
    // เนื่องจาก _preprocessAudio ยังเป็น dummy เราจะสร้าง input ตาม shape ที่โมเดลต้องการ
    final inputShape = _interpreter.getInputTensor(0).shape; // [1, 40, 173, 1]
    var input = List.filled(inputShape[0] * inputShape[1] * inputShape[2] * inputShape[3], 0.0)
        .reshape(inputShape);


    // 2. Prepare the output buffer
    final outputShape = _interpreter.getOutputTensor(0).shape; // e.g., [1, 5] for 5 emotions
    var output = List.filled(outputShape[0] * outputShape[1], 0.0).reshape(outputShape);

    // 3. Run inference
    _interpreter.run(input, output);

    // 4. Post-process the output
    final result = <String, double>{};
    final probabilities = output[0] as List<double>; // Get the list of probabilities

    for (int i = 0; i < _labels.length; i++) {
      result[_labels[i]] = probabilities[i];
    }
    
    print('📊 Prediction Results: $result');
    return result;
  }
}