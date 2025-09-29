import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'prediction_result.dart'; 

class EmotionApiService {
  static const String _apiUrl = "http://192.168.96.1:5000/predict";

  Future<PredictionResult> predict(String audioPath) async {
    print("ApiService: Predicting for audio at $audioPath");
    final file = File(audioPath);
    if (!await file.exists()) {
      print("ApiService: File does not exist at path $audioPath");
      throw Exception("File not found for prediction.");
    }

    try {
      final requestUri = Uri.parse(_apiUrl);
  
      final request = http.MultipartRequest('POST', requestUri);
      request.files.add(
        await http.MultipartFile.fromPath(
          'audio',
          audioPath,
        ),
      );

      print("ApiService: Sending request to $_apiUrl...");
      final streamedResponse = await request.send();

      if (streamedResponse.statusCode == 200) {
        final responseBody = await streamedResponse.stream.bytesToString();
        print("ApiService: Received successful response: $responseBody");
        
        final Map<String, dynamic> decodedJson = json.decode(responseBody);
        return PredictionResult.fromJson(decodedJson);

      } else {
        final errorBody = await streamedResponse.stream.bytesToString();
        print("ApiService: Error from server (${streamedResponse.statusCode}): $errorBody");
        throw Exception("Failed to get prediction from API. Status: ${streamedResponse.statusCode}");
      }
    } catch (e) {
      print("ApiService: An error occurred during prediction: $e");
      rethrow;
    }
  }
}