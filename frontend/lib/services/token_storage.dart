import 'package:shared_preferences/shared_preferences.dart';

/// Token Storage Service
/// Handles JWT token persistence using SharedPreferences
class TokenStorage {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _roleKey = 'user_role';
  
  /// Save auth token
  static Future<bool> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_tokenKey, token);
    } catch (e) {
      return false;
    }
  }
  
  /// Get auth token
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      return null;
    }
  }
  
  /// Save user data
  static Future<bool> saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save role separately for quick access
      if (userData.containsKey('role')) {
        await prefs.setString(_roleKey, userData['role']);
      }
      
      // Save full user data as JSON string
      final userJson = userData.toString();
      return await prefs.setString(_userKey, userJson);
    } catch (e) {
      return false;
    }
  }
  
  /// Get user role
  static Future<String?> getUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_roleKey);
    } catch (e) {
      return null;
    }
  }
  
  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
  
  /// Clear all auth data (logout)
  static Future<bool> clearAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
      await prefs.remove(_roleKey);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Clear all app data
  static Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.clear();
    } catch (e) {
      return false;
    }
  }
}