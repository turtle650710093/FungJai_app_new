import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:wav/wav.dart';


class EmotionClassifierService {
  Interpreter? _interpreter;
  List<String>? _labels;

  Future<void> init() async {
    try {
      final labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData.split('\n').map((label) => label.trim()).toList();
      _labels?.removeWhere((label) => label.isEmpty); 

      _interpreter = await Interpreter.fromAsset('assets/new_model.tflite');

      print('✅ Classifier initialized successfully.');
      print('Labels: $_labels');
    } catch (e) {
      print('❌ Error initializing classifier: $e');
    }
  }


Future<Map<String, double>> predict(String audioPath) async {
  if (_interpreter == null || _labels == null) {
    print('Classifier not initialized.');
    return {};
  }

  try {
    final file = File(audioPath);
    final wav = await Wav.readFile(file.path);
    final audioData = Float32List.fromList(wav.channels[0].map((e) => e.toDouble()).toList());

    print('DEBUG: Audio file loaded. Sample rate: ${wav.samplesPerSecond}, Length: ${audioData.length}');

    final inputShape = _interpreter!.getInputTensor(0).shape; 
    final requiredLength = inputShape[1]; 

    Float32List processedInput;
    if (audioData.length > requiredLength) {
      processedInput = audioData.sublist(0, requiredLength);
      print('DEBUG: Audio truncated from ${audioData.length} to $requiredLength');
    } else {
      processedInput = Float32List(requiredLength)..setRange(0, audioData.length, audioData);
      print('DEBUG: Audio padded from ${audioData.length} to $requiredLength');
    }

    final inputTensor = processedInput.reshape(inputShape);

    final outputShape = _interpreter!.getOutputTensor(0).shape;
    final output = Float32List(outputShape.reduce((a, b) => a * b)).reshape(outputShape);

    
    _interpreter!.run(inputTensor, output);

    final results = <String, double>{};
    final outputList = output[0];

    for (int i = 0; i < _labels!.length; i++) {
      results[_labels![i]] = outputList[i];
    }

    print('Prediction results from REAL audio: $results');
    return results;

  } catch (e) {
    print('❌ Error during prediction: $e');
    return {}; 
  }
}
}