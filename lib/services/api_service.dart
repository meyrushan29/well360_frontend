import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:image_picker/image_picker.dart'; // Use XFile

class ApiService {
  // Unified Deployment URL
  static String get baseUrl => AuthService.baseUrl;

  // =====================================================
  // PRIVATE HELPERS
  // =====================================================
  
  static Future<Map<String, String>> _getHeaders({bool auth = true}) async {
    final headers = {
      "Content-Type": "application/json",
    };
    if (auth) {
      final token = await AuthService.getToken();
      if (token == null) throw Exception("Please login first");
      headers["Authorization"] = "Bearer ${token.trim()}";
    }
    return headers;
  }

  static Future<dynamic> _post(String endpoint, Map<String, dynamic> data, {int timeoutSec = 60, bool auth = true}) async {
    try {
      final uri = Uri.parse("$baseUrl$endpoint");
      final headers = await _getHeaders(auth: auth);
      
      debugPrint("API Request: POST $uri (Body: ${data.length} keys)");
      
      final res = await http.post(
        uri, 
        headers: headers,
        body: jsonEncode(data)
      ).timeout(Duration(seconds: timeoutSec));
      
      return _processResponse(res);
    } catch (e) {
      debugPrint("API Error on $endpoint: $e");
      _handleError(e);
    }
  }

  static Future<dynamic> _get(String endpoint, {int timeoutSec = 20, bool auth = true}) async {
    try {
      final uri = Uri.parse("$baseUrl$endpoint");
      final headers = await _getHeaders(auth: auth);
      
      final res = await http.get(
        uri,
        headers: headers
      ).timeout(Duration(seconds: timeoutSec));
      
      return _processResponse(res);
    } catch (e) {
      _handleError(e);
    }
  }

  static dynamic _processResponse(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body);
    } else if (res.statusCode == 401) {
      throw Exception("Session expired or invalid. Please log in again.");
    } else if (res.statusCode == 503) {
      throw Exception("Service unavailable (503). The AI model might not be loaded.");
    } else {
      // Try to extract logical error from body
      try {
        final body = jsonDecode(res.body);
        if (body is Map && body.containsKey('detail')) {
          throw Exception(body['detail']);
        }
      } catch (_) {}
      throw Exception("Request failed (${res.statusCode}): ${res.body}");
    }
  }

  static void _handleError(Object e) {
    if (e is http.ClientException || e is SocketException) {
      throw Exception(
        "Cannot reach backend at $baseUrl. "
        "Server might be sleeping (Cold Start). "
        "Please wait a moment and try again. "
        "${AuthService.connectionHint}"
      );
    } else if (e is TimeoutException || e.toString().contains('timeout')) {
      throw Exception("Request timed out. Backend at $baseUrl is slow/waking up.");
    } else {
      throw e;
    }
  }

  // =====================================================
  // PUBLIC ENDPOINTS
  // =====================================================

  // --- HYDRATION ---

  static Future<Map<String, dynamic>> predictHydration(Map<String, dynamic> data) async {
    return await _post("/predict/form", data);
  }

  static Future<bool> checkBackendReachable() async {
    try {
      final res = await http
          .get(Uri.parse("$baseUrl/hydration/health"))
          .timeout(const Duration(seconds: 30)); // Increased for Cold Start
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['status'] == 'ok';
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> checkHydrationBackend() async {
    try {
      debugPrint("API: Checking Hydration Health at $baseUrl...");
      final res = await http
          .get(Uri.parse("$baseUrl/hydration/health"))
          .timeout(const Duration(seconds: 60)); // Increased for Render Cold Start
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final ok = data['status'] == 'ok' && (data['lip_model_available'] == true);
        debugPrint("API: Health check ${ok ? 'PASSED' : 'FAILED (Model not available)'}");
        return ok;
      }
      debugPrint("API: Health check FAILED with status ${res.statusCode}");
      return false;
    } catch (e) {
      debugPrint("API: Health check ERROR: $e");
      return false;
    }
  }

  // --- USER DATA ---

  static Future<Map<String, dynamic>> getProfile() async {
    return await _get("/auth/profile");
  }

  static Future<Map<String, dynamic>> getDailyDashboard() async {
    return await _get("/tracker/dashboard");
  }

  static Future<Map<String, dynamic>> getTrends() async {
    return await _get("/history/trends");
  }
  
  static Future<Map<String, dynamic>> getWeather(double lat, double lon) async {
    return await _get("/weather/current?lat=$lat&lon=$lon");
  }

  // --- LIP ANALYSIS ---

  static Future<Map<String, dynamic>> predictLip({
    XFile? imageFile, 
    Uint8List? webImage,
  }) async {
    String base64Image;
    if (kIsWeb) {
      if (webImage == null) throw Exception("Web image bytes missing");
      base64Image = base64Encode(webImage);
    } else {
      if (imageFile == null) throw Exception("Image file missing");
      final bytes = await imageFile.readAsBytes();
      base64Image = base64Encode(bytes);
    }
    
    // Extra long timeout for ML (3 minutes) as free-tier servers can be slow with image processing
    return await _post("/predict/lip", {"image_base64": base64Image}, timeoutSec: 180);
  }

  static Future<Map<String, dynamic>> getLipTrends() async {
    return await _get("/history/lip-trends");
  }

  // --- FITNESS ---

  static Future<Map<String, dynamic>> predictFitnessVideo(
    String videoIdentifier, {
    Uint8List? webBytes,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception("Please login first");

    final uri = Uri.parse("$baseUrl/predict/fitness/video");
    final request = http.MultipartRequest("POST", uri);
    
    request.headers["Authorization"] = "Bearer $token";
    
    if (kIsWeb && webBytes != null) {
       request.files.add(http.MultipartFile.fromBytes(
         'video',
         webBytes,
         filename: videoIdentifier, 
       ));
    } else {
       request.files.add(await http.MultipartFile.fromPath(
        'video',
        videoIdentifier,
       ));
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);
    } catch (e) {
      _handleError(e);
      rethrow; // _handleError might throw different exception
    }
  }

  // --- MENTAL HEALTH ---

  static Future<Map<String, dynamic>> checkMentalHealthStatus() async {
    try {
      final res = await http
          .get(Uri.parse("$baseUrl/mental-health/status"))
          .timeout(const Duration(seconds: 30)); // Increased for Cold Start
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return {"status": "unavailable"};
    } catch (_) {
      return {"status": "unreachable"};
    }
  }

  static Future<Map<String, dynamic>> predictFaceEmotion(String base64Image) async {
    return await _post("/mental-health/predict/face", {"image_base64": base64Image}, timeoutSec: 30);
  }

  static Future<Map<String, dynamic>> predictAudioEmotion(
    String filePath, {
    Uint8List? webBytes,
    String? fileName,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception("Please login first");

    final uri = Uri.parse("$baseUrl/mental-health/predict/audio");
    final request = http.MultipartRequest("POST", uri);
    request.headers["Authorization"] = "Bearer $token";

    if (kIsWeb && webBytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'audio',
        webBytes,
        filename: fileName ?? 'upload.wav',
      ));
    } else {
      request.files.add(await http.MultipartFile.fromPath(
        'audio',
        filePath,
      ));
    }

    try {
      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> predictVideoEmotion(
    String filePath, {
    Uint8List? webBytes,
    String? fileName,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception("Please login first");

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/mental-health/predict/video"),
      );
      request.headers['Authorization'] = 'Bearer $token';

      if (kIsWeb && webBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'video',
          webBytes,
          filename: fileName ?? 'video.mp4',
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'video',
          filePath,
          filename: fileName,
        ));
      }

      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 5), // Video processing is slow
      );
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);

    } on TimeoutException {
      throw Exception("Video analysis timed out. Try a shorter video.");
    } catch (e) {
      if (e is Exception) rethrow; // If _processResponse threw it
      _handleError(e);
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getLastEmotion({String source = "video"}) async {
    return await _get("/mental-health/last-emotion?source=$source", timeoutSec: 10);
  }

  static Future<Map<String, dynamic>> getStressAnalysis() async {
    return await _get("/mental-health/stress", timeoutSec: 15);
  }

  static Future<Map<String, dynamic>> getEmotionHistory({
    String source = "video",
    int limit = 50,
  }) async {
    return await _get("/mental-health/history?source=$source&limit=$limit", timeoutSec: 10);
  }
}
