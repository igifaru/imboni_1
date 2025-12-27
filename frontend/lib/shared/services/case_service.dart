import 'api_client.dart';
import '../models/models.dart';

/// Case Service - Handles all case-related API operations
class CaseService {
  static CaseService? _instance;
  CaseService._();
  static CaseService get instance => _instance ??= CaseService._();

  /// Submit a new case
  Future<ApiResponse<CaseModel>> submitCase(CreateCaseRequest request) async {
    final response = await apiClient.post('/api/cases', request.toJson());
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(CaseModel.fromJson(response.data));
    }
    return ApiResponse.error(response.error ?? 'Failed to submit case');
  }

  /// Track a case by reference number
  Future<ApiResponse<CaseModel>> trackCase(String reference) async {
    final response = await apiClient.get('/api/cases/track/$reference');
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(CaseModel.fromJson(response.data));
    }
    return ApiResponse.error(response.error ?? 'Case not found');
  }

  /// Get user's cases
  Future<ApiResponse<List<CaseModel>>> getUserCases({int limit = 20, int offset = 0, String? status}) async {
    String endpoint = '/api/cases/my-cases?limit=$limit&offset=$offset';
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
    final response = await apiClient.get('/api/cases/$id');
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(CaseModel.fromJson(response.data));
    }
    return ApiResponse.error(response.error ?? 'Case not found');
  }

  /// Get case actions/history
  Future<ApiResponse<List<CaseAction>>> getCaseActions(String caseId) async {
    final response = await apiClient.get('/api/cases/$caseId/actions');
    if (response.isSuccess && response.data != null) {
      final List<dynamic> actionsJson = response.data['actions'] ?? response.data ?? [];
      final actions = actionsJson.map((json) => CaseAction.fromJson(json)).toList();
      return ApiResponse.success(actions);
    }
    return ApiResponse.success([]);
  }

  /// Add action to case (for leaders)
  Future<ApiResponse<CaseAction>> addCaseAction(String caseId, String actionType, String description) async {
    final response = await apiClient.post('/api/cases/$caseId/actions', {
      'actionType': actionType,
      'description': description,
    });
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(CaseAction.fromJson(response.data));
    }
    return ApiResponse.error(response.error ?? 'Failed to add action');
  }

  /// Resolve case (for leaders)
  Future<ApiResponse<CaseModel>> resolveCase(String caseId, String resolution) async {
    final response = await apiClient.post('/api/cases/$caseId/resolve', {
      'resolution': resolution,
    });
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(CaseModel.fromJson(response.data));
    }
    return ApiResponse.error(response.error ?? 'Failed to resolve case');
  }

  /// Get assigned cases (for leaders)
  Future<ApiResponse<List<CaseModel>>> getAssignedCases({int limit = 20, String? status}) async {
    String endpoint = '/api/cases/assigned?limit=$limit';
    if (status != null) endpoint += '&status=$status';
    
    final response = await apiClient.get(endpoint);
    if (response.isSuccess && response.data != null) {
      final List<dynamic> casesJson = response.data['cases'] ?? response.data ?? [];
      final cases = casesJson.map((json) => CaseModel.fromJson(json)).toList();
      return ApiResponse.success(cases);
    }
    return ApiResponse.success([]);
  }

  /// Get escalation alerts (for leaders)
  Future<ApiResponse<List<CaseModel>>> getEscalationAlerts() async {
    final response = await apiClient.get('/api/cases/escalation-alerts');
    if (response.isSuccess && response.data != null) {
      final List<dynamic> casesJson = response.data['cases'] ?? response.data ?? [];
      final cases = casesJson.map((json) => CaseModel.fromJson(json)).toList();
      return ApiResponse.success(cases);
    }
    return ApiResponse.success([]);
  }

  /// Get performance metrics (for leaders)
  Future<ApiResponse<PerformanceMetrics>> getPerformanceMetrics() async {
    final response = await apiClient.get('/api/cases/metrics');
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(PerformanceMetrics.fromJson(response.data));
    }
    return ApiResponse.success(PerformanceMetrics.empty());
  }
}

/// Performance Metrics Model
class PerformanceMetrics {
  final int totalCases;
  final int resolvedCases;
  final int pendingCases;
  final int escalatedCases;
  final double resolutionRate;
  final double avgResponseTimeHours;
  final Map<String, int> casesByCategory;

  PerformanceMetrics({
    required this.totalCases,
    required this.resolvedCases,
    required this.pendingCases,
    required this.escalatedCases,
    required this.resolutionRate,
    required this.avgResponseTimeHours,
    required this.casesByCategory,
  });

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return PerformanceMetrics(
      totalCases: json['totalCases'] ?? 0,
      resolvedCases: json['resolvedCases'] ?? 0,
      pendingCases: json['pendingCases'] ?? 0,
      escalatedCases: json['escalatedCases'] ?? 0,
      resolutionRate: (json['resolutionRate'] ?? 0).toDouble(),
      avgResponseTimeHours: (json['avgResponseTimeHours'] ?? 0).toDouble(),
      casesByCategory: Map<String, int>.from(json['casesByCategory'] ?? {}),
    );
  }

  factory PerformanceMetrics.empty() => PerformanceMetrics(
    totalCases: 0, resolvedCases: 0, pendingCases: 0, escalatedCases: 0,
    resolutionRate: 0, avgResponseTimeHours: 0, casesByCategory: {},
  );
}

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
