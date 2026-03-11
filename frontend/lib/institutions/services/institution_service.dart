import '../../shared/services/api_client.dart';
import '../models/institution_models.dart';

class InstitutionService {
  static final InstitutionService _instance = InstitutionService._();
  InstitutionService._();
  static InstitutionService get instance => _instance;

  // ─── Institution Types ─────────────────────────────────────

  Future<ApiResponse<List<InstitutionTypeModel>>> getTypes() async {
    final response = await apiClient.get<dynamic>('/institutions/types');
    if (response.isSuccess && response.data != null) {
      final List<dynamic> data = response.data is List ? response.data : response.data['data'] ?? [];
      return ApiResponse.success(data.map((json) => InstitutionTypeModel.fromJson(json)).toList());
    }
    return ApiResponse.error(response.error ?? 'Failed to load institution types');
  }

  Future<ApiResponse<InstitutionTypeModel>> createType(Map<String, dynamic> data) async {
    final response = await apiClient.post('/institutions/types', data);
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(InstitutionTypeModel.fromJson(response.data));
    }
    return ApiResponse.error(response.error ?? 'Failed to create type');
  }

  // ─── Institutions ──────────────────────────────────────────

  Future<ApiResponse<List<InstitutionModel>>> getInstitutions({String? typeId}) async {
    final endpoint = typeId != null ? '/institutions?typeId=$typeId' : '/institutions';
    final response = await apiClient.get<dynamic>(endpoint);
    if (response.isSuccess && response.data != null) {
      final List<dynamic> data = response.data is List ? response.data : response.data['data'] ?? [];
      return ApiResponse.success(data.map((json) => InstitutionModel.fromJson(json)).toList());
    }
    return ApiResponse.error(response.error ?? 'Failed to load institutions');
  }

  Future<ApiResponse<InstitutionModel>> registerInstitution(Map<String, dynamic> data) async {
    final response = await apiClient.post('/institutions', data);
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(InstitutionModel.fromJson(response.data));
    }
    return ApiResponse.error(response.error ?? 'Failed to register institution');
  }

  Future<ApiResponse<Map<String, dynamic>>> getInstitutionDetails(String id) async {
    final response = await apiClient.get('/institutions/$id');
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(response.data);
    }
    return ApiResponse.error(response.error ?? 'Failed to load details');
  }

  // ─── Branches ──────────────────────────────────────────────

  Future<ApiResponse<List<InstitutionBranchModel>>> getBranches(String institutionId) async {
    final response = await apiClient.get<dynamic>('/institutions/$institutionId/branches');
    if (response.isSuccess && response.data != null) {
      final List<dynamic> data = response.data is List ? response.data : response.data['data'] ?? [];
      return ApiResponse.success(data.map((json) => InstitutionBranchModel.fromJson(json)).toList());
    }
    return ApiResponse.error(response.error ?? 'Failed to load branches');
  }

  Future<ApiResponse<InstitutionBranchModel>> addBranch(Map<String, dynamic> data) async {
    final response = await apiClient.post('/institutions/branches', data);
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(InstitutionBranchModel.fromJson(response.data));
    }
    return ApiResponse.error(response.error ?? 'Failed to add branch');
  }

  // ─── Services ──────────────────────────────────────────────

  Future<ApiResponse<List<InstitutionServiceModel>>> getServices(String institutionId) async {
    final response = await apiClient.get<dynamic>('/institutions/$institutionId/services');
    if (response.isSuccess && response.data != null) {
      final List<dynamic> data = response.data is List ? response.data : response.data['data'] ?? [];
      return ApiResponse.success(data.map((json) => InstitutionServiceModel.fromJson(json)).toList());
    }
    return ApiResponse.error(response.error ?? 'Failed to load services');
  }

  Future<ApiResponse<InstitutionServiceModel>> addService(Map<String, dynamic> data) async {
    final response = await apiClient.post('/institutions/services', data);
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(InstitutionServiceModel.fromJson(response.data));
    }
    return ApiResponse.error(response.error ?? 'Failed to add service');
  }

  // ─── Requests (Citizen) ────────────────────────────────────

  Future<ApiResponse<InstitutionRequestModel>> submitRequest(Map<String, dynamic> data) async {
    final response = await apiClient.post('/institutions/requests', data);
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(InstitutionRequestModel.fromJson(response.data));
    }
    return ApiResponse.error(response.error ?? 'Failed to submit request');
  }

  Future<ApiResponse<List<InstitutionRequestModel>>> getMyRequests() async {
    final response = await apiClient.get<dynamic>('/institutions/my-requests');
    if (response.isSuccess && response.data != null) {
      final List<dynamic> data = response.data is List ? response.data : response.data['data'] ?? [];
      return ApiResponse.success(data.map((json) => InstitutionRequestModel.fromJson(json)).toList());
    }
    return ApiResponse.error(response.error ?? 'Failed to load requests');
  }

  // ─── Requests (Staff) ──────────────────────────────────────

  Future<ApiResponse<bool>> updateRequestStatus(String requestId, String status, {String? notes}) async {
    final response = await apiClient.patch('/institutions/requests/$requestId/status', {
      'status': status,
      if (notes != null) 'notes': notes,
    });
    if (response.isSuccess) return ApiResponse.success(true);
    return ApiResponse.error(response.error ?? 'Update failed');
  }

  Future<ApiResponse<bool>> escalateRequest(String requestId, {
    required String fromRole,
    required String toRole,
    required String reason,
  }) async {
    final response = await apiClient.post('/institutions/requests/$requestId/escalate', {
      'fromRole': fromRole,
      'toRole': toRole,
      'reason': reason,
    });
    if (response.isSuccess) return ApiResponse.success(true);
    return ApiResponse.error(response.error ?? 'Escalation failed');
  }
}

final institutionService = InstitutionService.instance;
