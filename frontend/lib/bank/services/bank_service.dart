import '../../shared/services/api_client.dart';
import '../models/bank_models.dart';

class BankService {
  static final BankService _instance = BankService._();
  BankService._();
  static BankService get instance => _instance;

  /**
   * Admin Management API
   */

  // Get all banks
  Future<ApiResponse<List<BankModel>>> getAllBanks() async {
    final response = await apiClient.get<dynamic>('/banks');
    if (response.isSuccess && response.data != null) {
      final List<dynamic> data = response.data is List ? response.data : response.data['data'] ?? [];
      final banks = data.map((json) => BankModel.fromJson(json)).toList();
      return ApiResponse.success(banks);
    }
    return ApiResponse.error(response.error ?? 'Failed to load banks');
  }

  // Register Bank
  Future<ApiResponse<BankModel>> registerBank(Map<String, dynamic> data) async {
    final response = await apiClient.post('/banks/register', data);
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(BankModel.fromJson(response.data));
    }
    return ApiResponse.error(response.error ?? 'Failed to register bank');
  }

  // Get details (Branches/Services)
  Future<ApiResponse<Map<String, dynamic>>> getBankDetails(String bankId) async {
    final response = await apiClient.get('/banks/$bankId');
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(response.data);
    }
    return ApiResponse.error(response.error ?? 'Failed to load bank details');
  }

  // Add Branch
  Future<ApiResponse<BranchModel>> addBranch(String bankId, Map<String, dynamic> data) async {
    final response = await apiClient.post('/banks/$bankId/branches', data);
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(BranchModel.fromJson(response.data));
    }
    return ApiResponse.error(response.error ?? 'Failed to add branch');
  }

  // Add Service
  Future<ApiResponse<BankServiceModel>> addService(String bankId, Map<String, dynamic> data) async {
    final response = await apiClient.post('/banks/$bankId/services', data);
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(BankServiceModel.fromJson(response.data));
    }
    return ApiResponse.error(response.error ?? 'Failed to add service');
  }

  // Toggle Service
  Future<ApiResponse<bool>> toggleService(String serviceId, bool enabled) async {
    final response = await apiClient.patch('/banks/services/$serviceId', {'enabled': enabled});
    if (response.isSuccess) {
      return ApiResponse.success(true);
    }
    return ApiResponse.error(response.error ?? 'Update failed');
  }

  /**
   * Complaint API (Citizen Side)
   */

  // Submit Complaint
  Future<ApiResponse<BankCaseModel>> submitComplaint(Map<String, dynamic> data) async {
    final response = await apiClient.post('/banks/cases', data);
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(BankCaseModel.fromJson(response.data));
    }
    return ApiResponse.error(response.error ?? 'Complaint submission failed');
  }

  // Get My Complaints
  Future<ApiResponse<List<BankCaseModel>>> getMyComplaints() async {
    final response = await apiClient.get('/banks/cases/my-cases');
    if (response.isSuccess && response.data != null) {
      final List<dynamic> data = response.data is List ? response.data : response.data['data'] ?? [];
      final cases = data.map((json) => BankCaseModel.fromJson(json)).toList();
      return ApiResponse.success(cases);
    }
    return ApiResponse.error(response.error ?? 'Failed to load complaints');
  }

  // Update Status (Staff)
  Future<ApiResponse<bool>> updateCaseStatus(String caseId, String status, {String? notes}) async {
    final response = await apiClient.patch('/banks/cases/$caseId/status', {
      'status': status,
      if (notes != null) 'notes': notes
    });
    if (response.isSuccess) {
      return ApiResponse.success(true);
    }
    return ApiResponse.error(response.error ?? 'Update failed');
  }

  // Get Branch Cases (Staff)
  Future<ApiResponse<List<BankCaseModel>>> getCasesByBranch(String branchId) async {
    final response = await apiClient.get('/banks/branches/$branchId/cases');
    if (response.isSuccess && response.data != null) {
      final List<dynamic> data = response.data is List ? response.data : response.data['data'] ?? [];
      final cases = data.map((json) => BankCaseModel.fromJson(json)).toList();
      return ApiResponse.success(cases);
    }
    return ApiResponse.error(response.error ?? 'Failed to load branch cases');
  }
}
