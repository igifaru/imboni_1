import 'package:flutter/foundation.dart';
import '../../shared/services/api_client.dart';
import '../../shared/models/models.dart';

class AdminService extends ChangeNotifier {
  ApiClient get _apiClient => apiClient;
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get users with optional filters
  Future<List<UserModel>> getUsers({
    String? role,
    String? status,
    String? query,
    int page = 1,
    int limit = 50,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (role != null) queryParams['role'] = role;
      if (status != null) queryParams['status'] = status;
      if (query != null && query.isNotEmpty) queryParams['search'] = query;

      final response = await _apiClient.get('/admin/users', queryParameters: queryParams);

      if (response.isSuccess && response.data != null) {
        final List data = response.data['data'];
        final users = data.map((e) => UserModel.fromJson(e)).toList();
        _isLoading = false;
        notifyListeners();
        return users;
      } else {
        _error = response.error ?? 'Failed to load users';
        _isLoading = false;
        notifyListeners();
        return [];
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  /// Update user status (ACTIVE/INACTIVE)
  Future<bool> updateUserStatus(String userId, String status) async {
    try {
      final response = await _apiClient.patch('/admin/users/$userId/status', {'status': status});
      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  /// Get user statistics by province
  Future<List<Map<String, dynamic>>> getUserStatsByProvince() async {
    try {
      final response = await _apiClient.get('/admin/stats/users-by-province');
      if (response.isSuccess && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      print('Error fetching stats: $e');
      return [];
    }
  }

  /// Registers a subordinate leader
  Future<bool> registerSubordinate({
    required String name,
    required String email,
    required String password,
    required String level, // 'PROVINCE', 'DISTRICT', etc.
    required String jurisdictionName, // Name of the unit (e.g. 'Kigali')
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/admin/register-subordinate', {
        'name': name,
        'email': email,
        'password': password,
        'level': level,
        'jurisdictionName': jurisdictionName,
        'role': 'LEADER', // Always LEADER for subordinates in this flow
      });

      if (response.isSuccess) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Failed to register leader';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}

final adminService = AdminService();
