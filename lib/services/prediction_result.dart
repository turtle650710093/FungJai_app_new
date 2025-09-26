import 'package:flutter/foundation.dart';

class PredictionResult {
  final String emotion;
  final double confidence;

  PredictionResult({required this.emotion, required this.confidence});

  factory PredictionResult.fromJson(Map<String, dynamic>json) {
    return PredictionResult(
      emotion: json['emotion'] ?? 'unknow',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
 }