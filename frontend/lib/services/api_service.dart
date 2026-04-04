import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'token_storage.dart';

/// HTTP Client Service
/// Handles all API requests with automatic token injection and error handling
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
  
  final http.Client _client = http.Client();
  
  /// GET Request
  Future<ApiResponse> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    try {
      final url = queryParams != null
          ? ApiConfig.urlWithParams(endpoint, queryParams)
          : ApiConfig.url(endpoint);
      
      final headers = await _buildHeaders(requiresAuth);
      
      final response = await _client
          .get(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.receiveTimeout);
      
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }
  
  /// POST Request
  Future<ApiResponse> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final url = ApiConfig.url(endpoint);
      final headers = await _buildHeaders(requiresAuth);
      
      final response = await _client
          .post(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.receiveTimeout);
      
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }
  
  /// PUT Request
  Future<ApiResponse> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final url = ApiConfig.url(endpoint);
      final headers = await _buildHeaders(requiresAuth);
      
      final response = await _client
          .put(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.receiveTimeout);
      
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }
  
  /// DELETE Request
  Future<ApiResponse> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final url = ApiConfig.url(endpoint);
      final headers = await _buildHeaders(requiresAuth);
      
      final response = await _client
          .delete(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.receiveTimeout);
      
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }
  
  /// Build headers with auth token
  Future<Map<String, String>> _buildHeaders(bool requiresAuth) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (requiresAuth) {
      final token = await TokenStorage.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }
  
  /// Handle HTTP response
  ApiResponse _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    
    try {
      final data = response.body.isNotEmpty 
          ? jsonDecode(response.body) 
          : null;
      
      if (statusCode >= 200 && statusCode < 300) {
        return ApiResponse.success(data, statusCode);
      } else {
        final errorMessage = data?['error'] ?? 
                            data?['message'] ?? 
                            'Request failed with status $statusCode';
        return ApiResponse.error(errorMessage, statusCode);
      }
    } catch (e) {
      return ApiResponse.error(
        'Failed to parse response: ${e.toString()}',
        statusCode,
      );
    }
  }
  
  /// Handle errors
  String _handleError(dynamic error) {
    if (error.toString().contains('SocketException')) {
      return 'No internet connection. Please check your network.';
    } else if (error.toString().contains('TimeoutException')) {
      return 'Request timeout. Please try again.';
    } else {
      return 'An error occurred: ${error.toString()}';
    }
  }
  
  /// Close client
  void dispose() {
    _client.close();
  }
}

/// API Response wrapper
class ApiResponse {
  final bool success;
  final dynamic data;
  final String? error;
  final int? statusCode;
  
  ApiResponse._({
    required this.success,
    this.data,
    this.error,
    this.statusCode,
  });
  
  factory ApiResponse.success(dynamic data, int statusCode) {
    return ApiResponse._(
      success: true,
      data: data,
      statusCode: statusCode,
    );
  }
  
  factory ApiResponse.error(String error, [int? statusCode]) {
    return ApiResponse._(
      success: false,
      error: error,
      statusCode: statusCode,
    );
  }
  
  /// Check if unauthorized (401)
  bool get isUnauthorized => statusCode == 401;
  
  /// Check if forbidden (403)
  bool get isForbidden => statusCode == 403;
  
  /// Check if not found (404)
  bool get isNotFound => statusCode == 404;
  
  /// Check if server error (500+)
  bool get isServerError => statusCode != null && statusCode! >= 500;
}