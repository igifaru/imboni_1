import 'package:flutter/foundation.dart';

/// Institution Type Model
class InstitutionTypeModel {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;

  InstitutionTypeModel({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });

  factory InstitutionTypeModel.fromJson(Map<String, dynamic> json) {
    try {
      return InstitutionTypeModel(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Unknown',
        description: json['description']?.toString(),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '') ?? DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error parsing InstitutionTypeModel: $e');
      return InstitutionTypeModel(id: 'error', name: 'Error', createdAt: DateTime.now());
    }
  }

  String get displayName {
    switch (name.toUpperCase()) {
      case 'BANK': return 'Bank';
      case 'INSURANCE': return 'Insurance';
      case 'TELECOM': return 'Telecom';
      case 'GOVERNMENT': return 'Government';
      case 'HEALTHCARE': return 'Healthcare';
      default: return name;
    }
  }
}

/// Institution Model
class InstitutionModel {
  final String id;
  final String name;
  final String typeId;
  final String? description;
  final String? email;
  final String? phone;
  final String? website;
  final String? hqLocation;
  final String status;
  final DateTime createdAt;
  final InstitutionTypeModel? type;
  final int branchCount;

  InstitutionModel({
    required this.id,
    required this.name,
    required this.typeId,
    this.description,
    this.email,
    this.phone,
    this.website,
    this.hqLocation,
    required this.status,
    required this.createdAt,
    this.type,
    this.branchCount = 0,
  });

  factory InstitutionModel.fromJson(Map<String, dynamic> json) {
    try {
      return InstitutionModel(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Unnamed Institution',
        typeId: json['typeId']?.toString() ?? json['type_id']?.toString() ?? '',
        description: json['description']?.toString(),
        email: json['email']?.toString(),
        phone: json['phone']?.toString(),
        website: json['website']?.toString(),
        hqLocation: json['hqLocation']?.toString() ?? json['hq_location']?.toString(),
        status: json['status']?.toString() ?? 'ACTIVE',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '') ?? DateTime.now(),
        type: json['type'] != null ? InstitutionTypeModel.fromJson(json['type']) : null,
        branchCount: int.tryParse(json['_count']?['branches']?.toString() ?? '0') ?? 0,
      );
    } catch (e) {
      debugPrint('Error parsing InstitutionModel: $e');
      return InstitutionModel(id: 'error', name: 'Error', typeId: '', status: 'INACTIVE', createdAt: DateTime.now());
    }
  }

  bool get isActive => status.toUpperCase() == 'ACTIVE';
}

/// Branch Model
class InstitutionBranchModel {
  final String id;
  final String institutionId;
  final String branchName;
  final String province;
  final String district;
  final String sector;
  final String address;
  final String? managerId;
  final String status;

  InstitutionBranchModel({
    required this.id,
    required this.institutionId,
    required this.branchName,
    required this.province,
    required this.district,
    required this.sector,
    required this.address,
    this.managerId,
    required this.status,
  });

  factory InstitutionBranchModel.fromJson(Map<String, dynamic> json) {
    try {
      return InstitutionBranchModel(
        id: json['id']?.toString() ?? '',
        institutionId: json['institutionId']?.toString() ?? json['institution_id']?.toString() ?? '',
        branchName: json['branchName']?.toString() ?? json['branch_name']?.toString() ?? 'Unnamed Branch',
        province: json['province']?.toString() ?? 'N/A',
        district: json['district']?.toString() ?? 'N/A',
        sector: json['sector']?.toString() ?? 'N/A',
        address: json['address']?.toString() ?? 'N/A',
        managerId: json['managerId']?.toString() ?? json['manager_id']?.toString(),
        status: json['status']?.toString() ?? 'ACTIVE',
      );
    } catch (e) {
      debugPrint('Error parsing InstitutionBranchModel: $e');
      return InstitutionBranchModel(id: 'error', institutionId: '', branchName: 'Error', province: '', district: '', sector: '', address: '', status: 'INACTIVE');
    }
  }
}

/// Service Model
class InstitutionServiceModel {
  final String id;
  final String institutionId;
  final String serviceName;
  final String? description;
  final int? processingDays;
  final String status;

  InstitutionServiceModel({
    required this.id,
    required this.institutionId,
    required this.serviceName,
    this.description,
    this.processingDays,
    required this.status,
  });

  factory InstitutionServiceModel.fromJson(Map<String, dynamic> json) {
    try {
      return InstitutionServiceModel(
        id: json['id']?.toString() ?? '',
        institutionId: json['institutionId']?.toString() ?? json['institution_id']?.toString() ?? '',
        serviceName: json['serviceName']?.toString() ?? json['service_name']?.toString() ?? 'Unnamed Service',
        description: json['description']?.toString(),
        processingDays: int.tryParse(json['processingDays']?.toString() ?? json['processing_days']?.toString() ?? ''),
        status: json['status']?.toString() ?? 'ACTIVE',
      );
    } catch (e) {
      debugPrint('Error parsing InstitutionServiceModel: $e');
      return InstitutionServiceModel(id: 'error', institutionId: '', serviceName: 'Error', status: 'INACTIVE');
    }
  }
}

/// Request Status
enum RequestStatus { submitted, received, underReview, investigation, resolved, escalated, rejected }

/// Request Priority
enum RequestPriority { low, normal, high, urgent }

/// Request Model
class InstitutionRequestModel {
  final String id;
  final String citizenId;
  final String institutionId;
  final String branchId;
  final String serviceId;
  final String title;
  final String description;
  final RequestStatus status;
  final RequestPriority priority;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  // Relations (populated from includes)
  final String? citizenName;
  final String? citizenPhone;
  final String? institutionName;
  final String? branchName;
  final String? serviceName;

  InstitutionRequestModel({
    required this.id,
    required this.citizenId,
    required this.institutionId,
    required this.branchId,
    required this.serviceId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.resolvedAt,
    this.citizenName,
    this.citizenPhone,
    this.institutionName,
    this.branchName,
    this.serviceName,
  });

  factory InstitutionRequestModel.fromJson(Map<String, dynamic> json) {
    try {
      return InstitutionRequestModel(
        id: json['id']?.toString() ?? '',
        citizenId: json['citizenId']?.toString() ?? json['citizen_id']?.toString() ?? '',
        institutionId: json['institutionId']?.toString() ?? json['institution_id']?.toString() ?? '',
        branchId: json['branchId']?.toString() ?? json['branch_id']?.toString() ?? '',
        serviceId: json['serviceId']?.toString() ?? json['service_id']?.toString() ?? '',
        title: json['title']?.toString() ?? 'No Title',
        description: json['description']?.toString() ?? '',
        status: _parseStatus(json['status']?.toString()),
        priority: _parsePriority(json['priority']?.toString()),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '') ?? DateTime.now(),
        resolvedAt: DateTime.tryParse(json['resolvedAt']?.toString() ?? json['resolved_at']?.toString() ?? ''),
        citizenName: json['citizen']?['name']?.toString(),
        citizenPhone: json['citizen']?['phone']?.toString(),
        institutionName: json['institution']?['name']?.toString(),
        branchName: json['branch']?['branchName']?.toString() ?? json['branch']?['branch_name']?.toString(),
        serviceName: json['service']?['serviceName']?.toString() ?? json['service']?['service_name']?.toString(),
      );
    } catch (e) {
      debugPrint('Error parsing InstitutionRequestModel: $e');
      return InstitutionRequestModel(
        id: 'error', citizenId: '', institutionId: '', branchId: '', serviceId: '',
        title: 'Error', description: '', status: RequestStatus.submitted,
        priority: RequestPriority.normal, createdAt: DateTime.now(),
      );
    }
  }

  static RequestStatus _parseStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'SUBMITTED': return RequestStatus.submitted;
      case 'RECEIVED': return RequestStatus.received;
      case 'UNDER_REVIEW': return RequestStatus.underReview;
      case 'INVESTIGATION': return RequestStatus.investigation;
      case 'RESOLVED': return RequestStatus.resolved;
      case 'ESCALATED': return RequestStatus.escalated;
      case 'REJECTED': return RequestStatus.rejected;
      default: return RequestStatus.submitted;
    }
  }

  static RequestPriority _parsePriority(String? priority) {
    switch (priority?.toUpperCase()) {
      case 'LOW': return RequestPriority.low;
      case 'NORMAL': return RequestPriority.normal;
      case 'HIGH': return RequestPriority.high;
      case 'URGENT': return RequestPriority.urgent;
      default: return RequestPriority.normal;
    }
  }

  String get statusLabel {
    switch (status) {
      case RequestStatus.submitted: return 'Submitted';
      case RequestStatus.received: return 'Received';
      case RequestStatus.underReview: return 'Under Review';
      case RequestStatus.investigation: return 'Investigation';
      case RequestStatus.resolved: return 'Resolved';
      case RequestStatus.escalated: return 'Escalated';
      case RequestStatus.rejected: return 'Rejected';
    }
  }

  String get priorityLabel {
    switch (priority) {
      case RequestPriority.low: return 'Low';
      case RequestPriority.normal: return 'Normal';
      case RequestPriority.high: return 'High';
      case RequestPriority.urgent: return 'Urgent';
    }
  }
}
