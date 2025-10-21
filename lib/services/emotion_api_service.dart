import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'prediction_result.dart';

class EmotionApiService {
  static const String _apiUrl = "http://192.168.1.123:5000/predict";

  Future<PredictionResult> predictEmotion(String audioPath) async {
    return await predict(audioPath);
  }

  Future<PredictionResult> predict(String audioPath) async {
    print("🌐 ApiService: Starting prediction for $audioPath");
    
    final file = File(audioPath);
    if (!await file.exists()) {
      print("❌ ApiService: File not found");
      throw Exception("ไม่พบไฟล์เสียง");
    }

    try {
      final request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      request.files.add(
        await http.MultipartFile.fromPath('audio', audioPath),
      );

      print("📤 ApiService: Sending request...");
      final streamedResponse = await request.send();

      if (streamedResponse.statusCode == 200) {
        final responseBody = await streamedResponse.stream.bytesToString();
        print("✅ ApiService: Success");
        
        final decodedJson = json.decode(responseBody);
        return PredictionResult.fromJson(decodedJson);
      } else {
        print("❌ ApiService: Error ${streamedResponse.statusCode}");
        throw Exception("API ตอบกลับด้วย status ${streamedResponse.statusCode}");
      }
    } on SocketException {
      print("❌ ApiService: Connection failed");
      throw SocketException("ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์");
    } catch (e) {
      print("❌ ApiService: Error - $e");
      rethrow;
    }
  }
}