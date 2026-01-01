import 'package:flutter/foundation.dart';
import '../../shared/services/api_client.dart';
import '../../shared/models/models.dart';

class PaginatedResponse<T> {
  final List<T> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  PaginatedResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PaginatedResponse.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJson) {
    return PaginatedResponse(
      data: (json['data'] as List).map(fromJson).toList(),
      total: json['meta']?['total'] ?? 0,
      page: json['meta']?['page'] ?? 1,
      limit: json['meta']?['limit'] ?? 50,
      totalPages: json['meta']?['pages'] ?? 1,
    );
  }
}

class AdminService extends ChangeNotifier {
  ApiClient get _apiClient => apiClient;
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get users with optional filters
  Future<PaginatedResponse<UserModel>> getUsers({
    String? role,
    String? status,
    String? query,
    String? unitId,
    int page = 1,
    int limit = 10,
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
      if (unitId != null) queryParams['unitId'] = unitId;
      if (query != null && query.isNotEmpty) queryParams['search'] = query;

      final response = await _apiClient.get('/admin/users', queryParameters: queryParams);

      if (response.isSuccess && response.data != null) {
        final paginated = PaginatedResponse<UserModel>.fromJson(
          response.data, 
          (json) => UserModel.fromJson(json),
        );
        
        _isLoading = false;
        notifyListeners();
        return paginated;
      } else {
        _error = response.error ?? 'Failed to load users';
        _isLoading = false;
        notifyListeners();
        return PaginatedResponse(data: [], total: 0, page: 1, limit: limit, totalPages: 0);
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return PaginatedResponse(data: [], total: 0, page: 1, limit: limit, totalPages: 0);
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
      debugPrint('Error loading stats: $e');
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
    String? positionTitle, // Optional title for staff
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
        'positionTitle': positionTitle,
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

  /// Get the logged-in leader's jurisdiction data
  /// Returns province assignment and filtered districts from backend
  Future<Map<String, dynamic>?> getMyJurisdiction() async {
    try {
      final response = await _apiClient.get('/admin/my-jurisdiction');
      if (response.isSuccess && response.data != null) {
        return response.data;
      }
      _error = response.error ?? 'Failed to fetch jurisdiction';
      return null;
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }
}

final adminService = AdminService();
