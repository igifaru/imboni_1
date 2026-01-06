// PFTCV Service - API communication for Public Fund Transparency
import 'package:flutter/foundation.dart';
import '../../../shared/services/api_client.dart';
import '../models/pftcv_models.dart';

class PftcvService {
  final ApiClient _apiClient;

  PftcvService({ApiClient? client}) : _apiClient = client ?? apiClient;

  // Get list of projects with optional filters
  Future<List<Project>> getProjects({
    int page = 1,
    int limit = 20,
    String? sector,
    String? status,
    String? riskLevel,
    String? locationId,
    String? locationName,
    String? locationLevel,
    String? search,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (sector != null) 'sector': sector,
      if (status != null) 'status': status,
      if (riskLevel != null) 'riskLevel': riskLevel,
      if (locationId != null) 'locationId': locationId,
      if (locationName != null) 'locationName': locationName,
      if (locationLevel != null) 'locationLevel': locationLevel,
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final response = await _apiClient.get<dynamic>('/projects', queryParameters: queryParams);
    if (response.isSuccess && response.data != null) {
      final List<dynamic> list = response.data is List ? response.data : (response.data['data'] ?? []);
      return list.map((e) => Project.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  // Get single project details
  Future<Project?> getProjectById(String id) async {
    final response = await _apiClient.get<dynamic>('/projects/$id');
    if (response.isSuccess && response.data != null) {
      return Project.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  }

  // Submit citizen verification
  Future<CitizenVerification?> submitVerification({
    required String projectId,
    required String deliveryStatus,
    required int completionPercent,
    int? qualityRating,
    String? comment,
    bool isAnonymous = false,
    double? gpsLatitude,
    double? gpsLongitude,
    List<Map<String, dynamic>>? evidence,
  }) async {
    final body = {
      'deliveryStatus': deliveryStatus,
      'completionPercent': completionPercent,
      if (qualityRating != null) 'qualityRating': qualityRating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
      'isAnonymous': isAnonymous,
      if (gpsLatitude != null) 'gpsLatitude': gpsLatitude,
      if (gpsLongitude != null) 'gpsLongitude': gpsLongitude,
      if (evidence != null) 'evidence': evidence,
    };

    final response = await _apiClient.post<dynamic>('/projects/$projectId/verify', body);
    if (response.isSuccess && response.data != null) {
      return CitizenVerification.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  }

  // Get verifications for a project
  Future<List<CitizenVerification>> getProjectVerifications(String projectId) async {
    final response = await _apiClient.get<dynamic>('/projects/$projectId/verifications');
    if (response.isSuccess && response.data != null) {
      final List<dynamic> list = response.data is List ? response.data : [];
      return list.map((e) => CitizenVerification.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  // Get dashboard statistics
  Future<PftcvStats?> getStats({
    String? locationId,
    String? locationName,
    String? locationLevel,
  }) async {
    final queryParams = <String, String>{
      if (locationId != null) 'locationId': locationId,
      if (locationName != null) 'locationName': locationName,
      if (locationLevel != null) 'locationLevel': locationLevel,
    };

    final response = await _apiClient.get<dynamic>('/projects/stats', queryParameters: queryParams);
    if (response.isSuccess && response.data != null) {
      return PftcvStats.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  }

  // Update citizen verification
  Future<CitizenVerification?> updateVerification({
    required String projectId,
    required String deliveryStatus,
    required int completionPercent,
    int? qualityRating,
    String? comment,
    bool isAnonymous = false,
    double? gpsLatitude,
    double? gpsLongitude,
    List<Map<String, dynamic>>? evidence,
  }) async {
    final body = {
      'deliveryStatus': deliveryStatus,
      'completionPercent': completionPercent,
      if (qualityRating != null) 'qualityRating': qualityRating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
      'isAnonymous': isAnonymous,
      if (gpsLatitude != null) 'gpsLatitude': gpsLatitude,
      if (gpsLongitude != null) 'gpsLongitude': gpsLongitude,
      if (evidence != null) 'evidence': evidence,
    };

    final response = await _apiClient.patch<dynamic>('/projects/$projectId/verify', body);
    if (response.isSuccess && response.data != null) {
      return CitizenVerification.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  }

  // Upload evidence file
  Future<Map<String, dynamic>?> uploadEvidence(String filePath) async {
    final response = await _apiClient.uploadFile<Map<String, dynamic>>('/projects/upload', filePath);
    if (response.isSuccess && response.data != null) {
      return response.data;
    }
    debugPrint('PftcvService: Upload failed. Status: ${response.isSuccess}, Error: ${response.error}, Data: ${response.data}');
    return null;
  }
}

final pftcvService = PftcvService();
