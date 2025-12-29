import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// API Client for backend communication
class ApiClient {
  static String get _baseUrl {
    // For Web: use localhost
    // For Mobile (Android/iOS): use the computer's local IP address
    // Make sure your phone is on the same WiFi network as your computer
    if (kIsWeb) return 'http://localhost:3000/api';
    // Your computer's local IP address (run 'hostname -I' to find it)
    return 'http://10.24.143.221:3000/api';
  }
  
  static String get baseUrl => _baseUrl;
  static String get storageUrl => _baseUrl.replaceAll('/api', '');
  
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
      print('ApiClient: GET request to $uri');
      final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
      print('ApiClient: GET response from $endpoint: ${response.statusCode}');
      return _handleResponse(response, fromJson: fromJson);
    } catch (e) {
      print('ApiClient: GET error: $e');
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

  Future<ApiResponse<T>> uploadFile<T>(String endpoint, String filePath, {String fieldName = 'file', T Function(dynamic)? fromJson}) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final request = http.MultipartRequest('POST', uri);
      
      // Add headers
      request.headers.addAll(_headers);
      request.headers.remove('Content-Type'); // Let http client set boundary
      
      // Add file
      if (kIsWeb) {
        // Web handling would come here (using bytes)
        // For now focusing on Linux/Mobile
      } else {
        request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse(response, fromJson: fromJson);
    } catch (e) {
      return ApiResponse.error('Upload error: $e');
    }
  }

  ApiResponse<T> _handleResponse<T>(http.Response response, {T Function(dynamic)? fromJson}) {
    try {
      final body = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (body is Map<String, dynamic>) {
          // If the response contains pagination metadata, return the whole body
          if (body.containsKey('meta')) {
            return ApiResponse.success(body as T);
          }
          final data = body['data'] ?? body;
          if (fromJson != null) {
            return ApiResponse.success(fromJson(data));
          }
          // Always return the 'data' payload if it exists, otherwise the whole body
          // This ensures callers who handle their own fromJson receive the correct object
          return ApiResponse.success(data as T);
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
