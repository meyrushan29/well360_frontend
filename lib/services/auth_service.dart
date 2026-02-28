import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// For DebugPrints
import 'dart:io'; // For SocketException
import 'dart:async'; // For Timeout

class AuthService {
  static String? _customBaseUrl;
  static const String _baseUrlKey = 'custom_base_url';

  static const String _productionUrl = "https://well360-backend.onrender.com";

  // Load configured URL at startup; fix platform-mismatched URLs (web vs emulator)
  static Future<void> loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    String? url = prefs.getString(_baseUrlKey);
    _customBaseUrl = url;
    debugPrint("AuthService: Loaded Base URL: $baseUrl");
  }

  // Set and persist new URL
  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    if (url.isEmpty) {
      await prefs.remove(_baseUrlKey);
      _customBaseUrl = null;
    } else {
      await prefs.setString(_baseUrlKey, url);
      _customBaseUrl = url;
    }
  }

  // Unified Deployment URL (platform-aware defaults)
  static String get baseUrl {
    // FORCE Production URL in Release Mode (App Store / APK)
    if (kReleaseMode) {
      return _productionUrl;
    }

    String url = (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) 
        ? _customBaseUrl!.trim() 
        : _productionUrl;

    // 1. Remove trailing slashes (to avoid double slashes like //predict)
    while (url.endsWith("/")) {
      url = url.substring(0, url.length - 1);
    }

    // 2. Auto-upgrade Render URLs to HTTPS (Redirects can break POST requests)
    if (url.contains("onrender.com") && url.startsWith("http://")) {
       url = url.replaceFirst("http://", "https://");
    }
    
    return url;
  }

  /// Hint for connection errors: which URL to use for current platform
  static String get connectionHint {
    return "Using Production Backend: $_productionUrl. Check if server is waking up (can take 60s).";
  }

  // Login
  static Future<String?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/login-json"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      ).timeout(const Duration(seconds: 60)); // Increased for Cold Start

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String token = data["access_token"];
        
        // Save Token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('user_email', email);
        return null; // Success (no error)
      } else {
        // Try to parse error detail
        try {
          final body = jsonDecode(response.body);
          return body["detail"] ?? "Login Failed: ${response.statusCode}";
        } catch (_) {
          return "Login Failed: ${response.statusCode} ${response.reasonPhrase}";
        }
      }
    } on SocketException catch (_) {
      return "Connection Refused.\n\nCheck: \n1. Internet Connection\n2. Backend Status (Render waking up?)";
    } on TimeoutException catch (_) {
      return "Connection Timed Out.\n\nBackend might be waking up (Cold Start). Please try again in a minute.";
    } catch (e) {
      debugPrint("Login Error: $e");
      return "Error: $e";
    }
  }

  // Register
  static Future<String?> register(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      ).timeout(const Duration(seconds: 60)); // Increased for Cold Start

      if (response.statusCode == 200) {
        return null; // Success
      } else {
        final body = jsonDecode(response.body);
        return body["detail"] ?? "Registration Failed: ${response.statusCode}";
      }
    } on SocketException catch (_) {
      return "Connection Refused. Check Internet/Server.";
    } catch (e) {
      return "Error: $e";
    }
  }

  // Get Token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_email');
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }


  // Diagnostic: Test Connection
  static Future<String> testConnection() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/api-status")).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return "SUCCESS: Connected to Backend!";
      } else {
        return "FAILED: Server returned ${response.statusCode}";
      }
    } catch (e) {
      return "FAILED: $e";
    }
  }
}
