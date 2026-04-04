import 'dart:convert';
import '../config/api_config.dart';
import 'api_service.dart';
import 'token_storage.dart';

/// Authentication Service
/// Handles user registration, login, and logout
class AuthService {
  final ApiService _api = ApiService();
  
  /// Register new user
  Future<AuthResult> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    String? phone,
    String? dateOfBirth,
    String? gender,
  }) async {
    try {
      final response = await _api.post(
        ApiConfig.register,
        body: {
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          'role': role,
          if (phone != null) 'phone': phone,
          if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
          if (gender != null) 'gender': gender,
        },
        requiresAuth: false,
      );
      
      if (response.success) {
        return AuthResult.success(
          message: response.data['message'] ?? 'Registration successful',
          userId: response.data['user_id'],
        );
      } else {
        return AuthResult.error(response.error ?? 'Registration failed');
      }
    } catch (e) {
      return AuthResult.error('Registration failed: ${e.toString()}');
    }
  }
  
  /// Login user
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.post(
        ApiConfig.login,
        body: {
          'email': email,
          'password': password,
        },
        requiresAuth: false,
      );
      
      if (response.success) {
        final token = response.data['token'];
        final user = response.data['user'];
        
        // Save token and user data
        await TokenStorage.saveToken(token);
        await TokenStorage.saveUserData(user);
        
        return AuthResult.success(
          message: 'Login successful',
          user: UserData.fromJson(user),
          token: token,
        );
      } else {
        return AuthResult.error(response.error ?? 'Invalid credentials');
      }
    } catch (e) {
      return AuthResult.error('Login failed: ${e.toString()}');
    }
  }
  
  /// Logout user
  Future<void> logout() async {
    try {
      // Call logout endpoint (optional, since JWT is stateless)
      await _api.post(ApiConfig.logout);
    } catch (e) {
      // Continue with logout even if API call fails
    }
    
    // Clear local storage
    await TokenStorage.clearAuth();
  }
  
  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await TokenStorage.isLoggedIn();
  }
  
  /// Get current user role
  Future<String?> getUserRole() async {
    return await TokenStorage.getUserRole();
  }
  
  /// Get current user info
  Future<AuthResult> getCurrentUser() async {
    try {
      final response = await _api.get(ApiConfig.me);
      
      if (response.success) {
        return AuthResult.success(
          user: UserData.fromJson(response.data['user']),
        );
      } else {
        return AuthResult.error('Failed to get user info');
      }
    } catch (e) {
      return AuthResult.error('Error: ${e.toString()}');
    }
  }
}

/// Auth Result wrapper
class AuthResult {
  final bool success;
  final String? message;
  final String? error;
  final UserData? user;
  final String? token;
  final int? userId;
  
  AuthResult._({
    required this.success,
    this.message,
    this.error,
    this.user,
    this.token,
    this.userId,
  });
  
  factory AuthResult.success({
    String? message,
    UserData? user,
    String? token,
    int? userId,
  }) {
    return AuthResult._(
      success: true,
      message: message,
      user: user,
      token: token,
      userId: userId,
    );
  }
  
  factory AuthResult.error(String error) {
    return AuthResult._(
      success: false,
      error: error,
    );
  }
}

/// User Data model
class UserData {
  final int userId;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String? phone;
  final String? dateOfBirth;
  final String? gender;
  
  UserData({
    required this.userId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.phone,
    this.dateOfBirth,
    this.gender,
  });
  
  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      userId: json['user_id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      role: json['role'],
      phone: json['phone'],
      dateOfBirth: json['date_of_birth'],
      gender: json['gender'],
    );
  }
  
  String get fullName => '$firstName $lastName';
}