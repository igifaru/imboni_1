import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'api_client.dart';

/// Auth Service - Handles authentication
class AuthService {
  static const String _tokenKey = 'auth_token';
  final ApiClient _client;
  UserModel? _currentUser;
  bool _isInitialized = false;

  AuthService({ApiClient? client}) : _client = client ?? apiClient;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      if (token != null) {
        _client.setAuthToken(token);
        final response = await _client.get<Map<String, dynamic>>('/auth/me');
        if (response.isSuccess && response.data != null) {
          final userData = response.data!['user'] as Map<String, dynamic>?;
          if (userData != null) _currentUser = UserModel.fromJson(userData);
        } else {
          await logout();
        }
      }
    } catch (e) {
      // Ignore init errors
    }
    _isInitialized = true;
  }

  Future<ApiResponse<UserModel>> login(String identifier, String password) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/auth/login',
      {'identifier': identifier, 'password': password},
    );
    if (response.isSuccess && response.data != null) {
      final token = response.data!['token'] as String?;
      final userData = response.data!['user'] as Map<String, dynamic>?;
      if (token != null && userData != null) {
        _client.setAuthToken(token);
        _currentUser = UserModel.fromJson(userData);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        return ApiResponse.success(_currentUser!);
      }
    }
    return ApiResponse.error(response.error ?? 'Login failed');
  }

  Future<ApiResponse<UserModel>> register({String? phone, String? email, required String password}) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/auth/register',
      {if (phone != null) 'phone': phone, if (email != null) 'email': email, 'password': password, 'role': 'CITIZEN'},
    );
    if (response.isSuccess && response.data != null) {
      final token = response.data!['token'] as String?;
      final userData = response.data!['user'] as Map<String, dynamic>?;
      if (token != null && userData != null) {
        _client.setAuthToken(token);
        _currentUser = UserModel.fromJson(userData);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        return ApiResponse.success(_currentUser!);
      }
    }
    return ApiResponse.error(response.error ?? 'Registration failed');
  }

  Future<void> logout() async {
    _client.setAuthToken(null);
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  /// Update user profile (phone/email)
  Future<ApiResponse<UserModel>> updateProfile({String? phone, String? email}) async {
    final body = <String, dynamic>{};
    if (phone != null) body['phone'] = phone;
    if (email != null) body['email'] = email;
    
    final response = await _client.patch<Map<String, dynamic>>('/user/profile', body);
    if (response.isSuccess && response.data != null) {
      final userData = response.data!['user'] as Map<String, dynamic>?;
      if (userData != null) {
        _currentUser = UserModel.fromJson(userData);
        return ApiResponse.success(_currentUser!);
      }
    }
    return ApiResponse.error(response.error ?? 'Profile update failed');
  }

  /// Change user password
  Future<ApiResponse<bool>> changePassword({required String currentPassword, required String newPassword}) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/user/change-password',
      {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
    if (response.isSuccess) {
      return ApiResponse.success(true);
    }
    return ApiResponse.error(response.error ?? 'Password change failed');
  }
}

final authService = AuthService();
