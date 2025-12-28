import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// API Client for backend communication
class ApiClient {
  static String get _baseUrl {
    // NOTE: For Android, run 'adb reverse tcp:3000 tcp:3000' to allow localhost access.
    // 10.0.2.2 can be flaky. ADB reverse is more reliable.
    if (kIsWeb) return 'http://localhost:3000/api';
    return 'http://localhost:3000/api';
  }
  final http.Client _client;
  String? _authToken;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  void setAuthToken(String? token) => _authToken = token;
  String? get authToken => _authToken;
  bool get isAuthenticated => _authToken != null;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  Future<ApiResponse<T>> get<T>(String endpoint, {Map<String, dynamic>? queryParameters, T Function(dynamic)? fromJson}) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint').replace(queryParameters: queryParameters);
      final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
      return _handleResponse(response, fromJson: fromJson);
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<T>> post<T>(String endpoint, Map<String, dynamic> body, {T Function(dynamic)? fromJson}) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
      return _handleResponse(response, fromJson: fromJson);
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<T>> patch<T>(String endpoint, Map<String, dynamic> body, {T Function(dynamic)? fromJson}) async {
    try {
      final response = await _client.patch(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
      return _handleResponse(response, fromJson: fromJson);
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  ApiResponse<T> _handleResponse<T>(http.Response response, {T Function(dynamic)? fromJson}) {
    try {
      final body = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (body is Map<String, dynamic>) {
          final data = body['data'] ?? body;
          if (fromJson != null) {
            return ApiResponse.success(fromJson(data));
          }
          return ApiResponse.success(body as T);
        }
        return ApiResponse.success(body as T);
      }
      return ApiResponse.error(body is Map ? body['error'] ?? 'Request failed' : 'Request failed');
    } catch (e) {
      return ApiResponse.error('Failed to parse response: $e');
    }
  }

  void dispose() => _client.close();
}

class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  const ApiResponse._({this.data, this.error, required this.isSuccess});
  factory ApiResponse.success(T data) => ApiResponse._(data: data, isSuccess: true);
  factory ApiResponse.error(String error) => ApiResponse._(error: error, isSuccess: false);
}

final apiClient = ApiClient();
