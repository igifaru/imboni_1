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
  Future<ApiResponse<String>> uploadEvidence(String caseId, String filePath) async {
    final response = await apiClient.uploadFile('/cases/$caseId/evidence', filePath);
    if (response.isSuccess && response.data != null) {
       return ApiResponse.success(response.data['id'] as String? ?? '');
    }
    return ApiResponse.error(response.error ?? 'Failed to upload evidence');
  }

// ... (existing code) ...



  /// Get user's cases
  Future<ApiResponse<List<CaseModel>>> getUserCases({int limit = 20, int offset = 0, String? status}) async {
    String endpoint = '/cases/my-cases?limit=$limit&offset=$offset';
    if (status != null) endpoint += '&status=$status';
    
    final response = await apiClient.get(endpoint);
    debugPrint('CaseService: getUserCases response.data type: ${response.data.runtimeType}');
    if (response.isSuccess && response.data != null) {
      final List<dynamic> casesJson;
      final data = response.data;
      if (data is Map && data['cases'] is List) {
        casesJson = data['cases'];
      } else if (data is Map && data['data'] is List) {
        casesJson = data['data'];
      } else if (data is List) {
        casesJson = data;
      } else {
        casesJson = [];
      }
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
      final List<dynamic> actionsJson;
      final data = response.data;
      if (data is Map && data['actions'] is List) {
        actionsJson = data['actions'];
      } else if (data is Map && data['data'] is List) {
        actionsJson = data['data'];
      } else if (data is List) {
        actionsJson = data;
      } else {
        actionsJson = [];
      }
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
  Future<ApiResponse<CaseModel>> resolveCase(String caseId, String resolution, {String? attachmentId}) async {
    final response = await apiClient.post('/cases/$caseId/resolve', {
      'notes': resolution, 
      'attachmentId': attachmentId,
    });
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(CaseModel.fromJson(response.data));
    }
    return ApiResponse.error(response.error ?? 'Failed to resolve case');
  }

  /// Escalate case (for leaders)
  Future<ApiResponse<CaseModel>> escalateCase(String caseId, String reason) async {
    final response = await apiClient.post('/cases/$caseId/escalate', {
      'reason': reason,
    });
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(CaseModel.fromJson(response.data));
    }
    return ApiResponse.error(response.error ?? 'Failed to escalate case');
  }

  /// Manually assign case to a leader
  Future<ApiResponse<CaseModel>> assignCase(String caseId, String leaderId, DateTime deadline) async {
    final response = await apiClient.post('/cases/$caseId/assign', {
      'leaderId': leaderId,
      'deadline': deadline.toIso8601String(),
    });
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(CaseModel.fromJson(response.data));
    }
    return ApiResponse.error(response.error ?? 'Failed to assign case');
  }

  /// Confirm resolution (for citizens) - marks case as CLOSED
  Future<ApiResponse<CaseModel>> confirmResolution(String caseId) async {
    final response = await apiClient.post('/cases/$caseId/confirm', {});
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(CaseModel.fromJson(response.data));
    }
    return ApiResponse.error(response.error ?? 'Failed to confirm resolution');
  }

  /// Dispute resolution (for citizens) - escalates to next level
  Future<ApiResponse<CaseModel>> disputeResolution(String caseId, String reason) async {
    final response = await apiClient.post('/cases/$caseId/dispute', {
      'reason': reason,
    });
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(CaseModel.fromJson(response.data));
    }
    return ApiResponse.error(response.error ?? 'Failed to dispute resolution');
  }

  /// Get assigned cases (for leaders)
  Future<ApiResponse<List<CaseModel>>> getAssignedCases({int limit = 20, String? status}) async {
    String endpoint = '/cases/assigned?limit=$limit';
    if (status != null) endpoint += '&status=$status';
    
    final response = await apiClient.get(endpoint);
    debugPrint('CaseService: getAssignedCases response.data type: ${response.data.runtimeType}');
    if (response.isSuccess && response.data != null) {
      final List<dynamic> casesJson;
      final data = response.data;
      if (data is Map && data['cases'] is List) {
        casesJson = data['cases'];
      } else if (data is Map && data['data'] is List) {
        casesJson = data['data'];
      } else if (data is List) {
        casesJson = data;
      } else {
        casesJson = [];
      }
      final cases = casesJson.map((json) => CaseModel.fromJson(json)).toList();
      return ApiResponse.success(cases);
    }
    return ApiResponse.success([]);
  }

  /// Get all cases in leader's jurisdiction (includes cases assigned to other leaders)
  /// This matches the dashboard stats count
  Future<ApiResponse<List<CaseModel>>> getJurisdictionCases({int limit = 50, String? status}) async {
    String endpoint = '/cases/jurisdiction?limit=$limit';
    if (status != null && status != 'All') endpoint += '&status=$status';
    
    final response = await apiClient.get(endpoint);
    debugPrint('CaseService: getJurisdictionCases response.data type: ${response.data.runtimeType}');
    if (response.isSuccess && response.data != null) {
      final List<dynamic> casesJson;
      final data = response.data;
      if (data is Map && data['cases'] is List) {
        casesJson = data['cases'];
      } else if (data is Map && data['data'] is List) {
        casesJson = data['data'];
      } else if (data is List) {
        casesJson = data;
      } else {
        casesJson = [];
      }
      final cases = casesJson.map((json) => CaseModel.fromJson(json)).toList();
      return ApiResponse.success(cases);
    }
    return ApiResponse.success([]);
  }

  /// Get ALL cases (for Admin)
  Future<ApiResponse<List<CaseModel>>> getAllCases({int page = 1, int limit = 50, String? query, String? locationId}) async {
    String endpoint = '/cases?page=$page&limit=$limit';
    if (query != null && query.isNotEmpty) endpoint += '&search=$query';
    if (locationId != null && locationId.isNotEmpty) endpoint += '&locationId=$locationId';

    final response = await apiClient.get(endpoint);
    debugPrint('CaseService: getAllCases response.data type: ${response.data.runtimeType}');
    if (response.isSuccess && response.data != null) {
      final List<dynamic> casesJson;
      final data = response.data;
      if (data is Map && data['cases'] is List) {
        casesJson = data['cases'];
      } else if (data is Map && data['data'] is List) {
        casesJson = data['data'];
      } else if (data is List) {
        casesJson = data;
      } else {
        casesJson = [];
      }
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
    debugPrint('CaseService: getEscalationAlerts response.data type: ${response.data.runtimeType}');
    if (response.isSuccess && response.data != null) {
      final List<dynamic> casesJson;
      final data = response.data;
      if (data is Map && data['cases'] is List) {
        casesJson = data['cases'];
      } else if (data is Map && data['data'] is List) {
        casesJson = data['data'];
      } else if (data is List) {
        casesJson = data;
      } else {
        casesJson = [];
      }
      final cases = casesJson.map((json) => CaseModel.fromJson(json)).toList();
      return ApiResponse.success(cases);
    }
    return ApiResponse.success([]);
  }

  /// Get performance metrics (for leaders)
  Future<ApiResponse<PerformanceMetrics>> getPerformanceMetrics({
    DateTimeRange? dateRange,
    String? category,
    String? locationId,
  }) async {
    final queryParams = <String, String>{};
    
    if (dateRange != null) {
      queryParams['startDate'] = dateRange.start.toIso8601String();
      queryParams['endDate'] = dateRange.end.toIso8601String();
    }
    
    if (category != null && category != 'All Categories') {
      queryParams['category'] = category;
    }
    
    if (locationId != null && locationId != 'All Locations') {
      queryParams['locationId'] = locationId;
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


final caseService = CaseService.instance;
