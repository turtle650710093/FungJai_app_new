import 'package:flutter/foundation.dart';

class PredictionResult {
  final String emotion;
  final double confidence;
  final Map<String, double> allPredictions;

  PredictionResult({
    required this.emotion,
    required this.confidence,
    Map<String, double>? allPredictions,
  }) : allPredictions = allPredictions ?? {
    'Angry': 0.0,
    'Frustrated': 0.0,
    'Happy': 0.0,
    'Neutral': 0.0,
    'Sad': 0.0,
  };

  // ✅ เพิ่ม factory constructor สำหรับแปลง JSON
  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    // แปลง predictions จาก JSON
    Map<String, double> predictions = {};
    
    if (json['predictions'] != null) {
      Map<String, dynamic> predMap = json['predictions'] as Map<String, dynamic>;
      predMap.forEach((key, value) {
        predictions[key] = (value as num).toDouble();
      });
    }

    return PredictionResult(
      emotion: json['emotion'] as String? ?? 'Unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      allPredictions: predictions,
    );
  }

  // ✅ เพิ่ม method แปลงเป็น JSON (สำหรับบันทึก)
  Map<String, dynamic> toJson() {
    return {
      'emotion': emotion,
      'confidence': confidence,
      'predictions': allPredictions,
    };
  }

  @override
  String toString() {
    return 'PredictionResult(emotion: $emotion, confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
  }
}