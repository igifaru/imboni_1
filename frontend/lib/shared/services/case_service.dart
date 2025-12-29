import 'package:flutter/material.dart';
import 'api_client.dart';
import '../models/models.dart';

/// Case Service - Handles all case-related API operations
class CaseService {
  static CaseService? _instance;
  CaseService._();
  static CaseService get instance => _instance ??= CaseService._();

  /// Submit a new case
  Future<ApiResponse<CaseModel>> submitCase(CreateCaseRequest request) async {
    final response = await apiClient.post('/cases', request.toJson());
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(CaseModel.fromJson(response.data));
    }
    return ApiResponse.error(response.error ?? 'Failed to submit case');
  }

  /// Track a case by reference number
  Future<ApiResponse<CaseModel>> trackCase(String reference) async {
    final response = await apiClient.get('/cases/track/$reference');
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(CaseModel.fromJson(response.data));
    }
    return ApiResponse.error(response.error ?? 'Case not found');
  }

  /// Upload evidence file
  Future<ApiResponse<void>> uploadEvidence(String caseId, String filePath) async {
    final response = await apiClient.uploadFile('/cases/$caseId/evidence', filePath);
    if (response.isSuccess) {
      return ApiResponse.success(null);
    }
    return ApiResponse.error(response.error ?? 'Failed to upload evidence');
  }

  /// Get user's cases
  Future<ApiResponse<List<CaseModel>>> getUserCases({int limit = 20, int offset = 0, String? status}) async {
    String endpoint = '/cases/my-cases?limit=$limit&offset=$offset';
    if (status != null) endpoint += '&status=$status';
    
    final response = await apiClient.get(endpoint);
    if (response.isSuccess && response.data != null) {
      final List<dynamic> casesJson = response.data['cases'] ?? response.data ?? [];
      final cases = casesJson.map((json) => CaseModel.fromJson(json)).toList();
      return ApiResponse.success(cases);
    }
    return ApiResponse.success([]);
  }

  /// Get case details by ID
  Future<ApiResponse<CaseModel>> getCaseById(String id) async {
    final response = await apiClient.get('/cases/$id');
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(CaseModel.fromJson(response.data));
    }
    return ApiResponse.error(response.error ?? 'Case not found');
  }

  /// Get case actions/history
  Future<ApiResponse<List<CaseAction>>> getCaseActions(String caseId) async {
    final response = await apiClient.get('/cases/$caseId/actions');
    if (response.isSuccess && response.data != null) {
      final List<dynamic> actionsJson = response.data['actions'] ?? response.data ?? [];
      final actions = actionsJson.map((json) => CaseAction.fromJson(json)).toList();
      return ApiResponse.success(actions);
    }
    return ApiResponse.success([]);
  }

  /// Add action to case (for leaders)
  Future<ApiResponse<CaseAction>> addCaseAction(String caseId, String actionType, String description) async {
    final response = await apiClient.post('/cases/$caseId/actions', {
      'actionType': actionType,
      'description': description,
    });
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(CaseAction.fromJson(response.data));
    }
    return ApiResponse.error(response.error ?? 'Failed to add action');
  }

  /// Review case (Accept/Reject/Info)
  Future<ApiResponse<CaseModel>> reviewCase(String caseId, String action, String? notes) async {
    final response = await apiClient.post('/cases/$caseId/review', {
      'action': action,
      'notes': notes,
    });
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(CaseModel.fromJson(response.data));
    }
    return ApiResponse.error(response.error ?? 'Failed to review case');
  }

  /// Resolve case (for leaders)
  Future<ApiResponse<CaseModel>> resolveCase(String caseId, String resolution) async {
    final response = await apiClient.post('/cases/$caseId/resolve', {
      'resolution': resolution,
    });
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(CaseModel.fromJson(response.data));
    }
    return ApiResponse.error(response.error ?? 'Failed to resolve case');
  }

  /// Get assigned cases (for leaders)
  Future<ApiResponse<List<CaseModel>>> getAssignedCases({int limit = 20, String? status}) async {
    String endpoint = '/cases/assigned?limit=$limit';
    if (status != null) endpoint += '&status=$status';
    
    final response = await apiClient.get(endpoint);
    if (response.isSuccess && response.data != null) {
      final List<dynamic> casesJson = response.data['cases'] ?? response.data ?? [];
      final cases = casesJson.map((json) => CaseModel.fromJson(json)).toList();
      return ApiResponse.success(cases);
    }
    return ApiResponse.success([]);
  }

  /// Get ALL cases (for Admin)
  Future<ApiResponse<List<CaseModel>>> getAllCases({int page = 1, int limit = 50, String? query}) async {
    String endpoint = '/cases?page=$page&limit=$limit';
    if (query != null && query.isNotEmpty) endpoint += '&search=$query';

    final response = await apiClient.get(endpoint);
    if (response.isSuccess && response.data != null) {
      final List<dynamic> casesJson = response.data['data'] ?? response.data ?? [];
      final cases = casesJson.map((json) => CaseModel.fromJson(json)).toList();
      return ApiResponse.success(cases);
    }
    return ApiResponse.success([]);
  }

  /// Get global stats (for Admin)
  Future<ApiResponse<Map<String, dynamic>>> getGlobalStats() async {
    final response = await apiClient.get('/cases/stats/global');
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(Map<String, dynamic>.from(response.data));
    }
    return ApiResponse.error(response.error ?? 'Failed to load stats');
  }

  /// Get escalation alerts (for leaders)
  Future<ApiResponse<List<CaseModel>>> getEscalationAlerts() async {
    final response = await apiClient.get('/cases/escalation-alerts');
    if (response.isSuccess && response.data != null) {
      final List<dynamic> casesJson = response.data['cases'] ?? response.data ?? [];
      final cases = casesJson.map((json) => CaseModel.fromJson(json)).toList();
      return ApiResponse.success(cases);
    }
    return ApiResponse.success([]);
  }

  /// Get performance metrics (for leaders)
  Future<ApiResponse<PerformanceMetrics>> getPerformanceMetrics({
    DateTimeRange? dateRange,
    String? category,
    String? location,
  }) async {
    final queryParams = <String, String>{};
    
    if (dateRange != null) {
      queryParams['startDate'] = dateRange.start.toIso8601String();
      queryParams['endDate'] = dateRange.end.toIso8601String();
    }
    
    if (category != null && category != 'All Categories') {
      queryParams['category'] = category;
    }
    
    if (location != null && location != 'All Locations') {
      queryParams['locationId'] = location;
    }

    final uri = Uri(path: '/cases/metrics', queryParameters: queryParams);
    
    // uri.toString() includes the query string properly encoded
    final response = await apiClient.get(uri.toString());
    
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(PerformanceMetrics.fromJson(response.data!));
    }
    return ApiResponse.error(response.error ?? 'Failed to load metrics');
  }
}

/// Performance Metrics Model

/// Case Action Model
class CaseAction {
  final String id;
  final String caseId;
  final String actionType;
  final String description;
  final String performedBy;
  final DateTime performedAt;

  CaseAction({
    required this.id,
    required this.caseId,
    required this.actionType,
    required this.description,
    required this.performedBy,
    required this.performedAt,
  });

  factory CaseAction.fromJson(Map<String, dynamic> json) {
    return CaseAction(
      id: json['id'] ?? '',
      caseId: json['caseId'] ?? '',
      actionType: json['actionType'] ?? '',
      description: json['description'] ?? '',
      performedBy: json['performedBy'] ?? '',
      performedAt: json['performedAt'] != null ? DateTime.parse(json['performedAt']) : DateTime.now(),
    );
  }
}

final caseService = CaseService.instance;
