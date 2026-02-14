import 'package:flutter/foundation.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class HydrationResultsService {
  // Singleton instance
  static final HydrationResultsService _instance = HydrationResultsService._internal();

  factory HydrationResultsService() {
    return _instance;
  }

  HydrationResultsService._internal();

  // Storage
  Map<String, dynamic>? _latestFormResult;
  Map<String, dynamic>? _latestLipResult;
  String _userName = "User";

  // Getters
  Map<String, dynamic> get formResult => _latestFormResult ?? {};
  Map<String, dynamic>? get lipResult => _latestLipResult;
  String get userName => _userName;

  bool get hasFormResult => _latestFormResult != null && _latestFormResult!.isNotEmpty;
  bool get hasLipResult => _latestLipResult != null && _latestLipResult!.isNotEmpty;

  // Methods
  void saveFormResult(Map<String, dynamic> result) {
    _latestFormResult = {
      ...result,
      'timestamp': DateTime.now().toIso8601String(),
    };
    debugPrint("HydrationResultsService: Saved Form Result at ${_latestFormResult!['timestamp']}");
  }

  void saveLipResult(Map<String, dynamic> result) {
    _latestLipResult = {
      ...result,
      'timestamp': DateTime.now().toIso8601String(),
    };
    debugPrint("HydrationResultsService: Saved Lip Result at ${_latestLipResult!['timestamp']}");
  }

  Future<void> fetchUserName() async {
    try {
      // 1. Try to fetch from Backend Profile
      try {
        final profile = await ApiService.getProfile();
        // The backend returns 'email' but not 'name' currently
        final String? email = profile['email'] ?? profile['name']; 
        
        if (email != null && email.isNotEmpty) {
           final namePart = email.split('@')[0];
           _userName = namePart.isNotEmpty 
              ? namePart[0].toUpperCase() + namePart.substring(1) 
              : "User";
           debugPrint("HydrationResultsService: API Name/Email -> $_userName");
           return;
        }
      } catch (_) {}

      // 2. Fallback to Local Email (if API failed)

      // 2. Fallback to Local Email
      final email = await AuthService.getUserEmail();
      if (email != null && email.isNotEmpty) {
        // Extract name from "merus@gmail.com" -> "Merus"
        final namePart = email.split('@')[0];
        _userName = namePart.isNotEmpty 
            ? namePart[0].toUpperCase() + namePart.substring(1) 
            : "User";
         debugPrint("HydrationResultsService: Derived User Name from Email: $_userName");
      }
    } catch (e) {
      debugPrint("HydrationResultsService: Error fetching user name: $e");
    }
  }

  void clearResults() {
    _latestFormResult = null;
    _latestLipResult = null;
  }
}
