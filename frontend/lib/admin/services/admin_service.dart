import 'package:flutter/foundation.dart';
import '../../shared/services/api_client.dart';

class AdminService extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

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
