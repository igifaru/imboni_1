import 'package:flutter/foundation.dart';

enum BankStatus { active, inactive }

enum BankCaseStatus { received, underReview, investigation, resolved, escalated }

class BankModel {
  final String id;
  final String bankName;
  final String bankCode;
  final String headOfficeLocation;
  final String? contactEmail;
  final String? contactPhone;
  final BankStatus status;
  final DateTime createdAt;
  final int branchCount;

  BankModel({
    required this.id,
    required this.bankName,
    required this.bankCode,
    required this.headOfficeLocation,
    this.contactEmail,
    this.contactPhone,
    required this.status,
    required this.createdAt,
    this.branchCount = 0,
  });

  factory BankModel.fromJson(Map<String, dynamic> json) {
    try {
      return BankModel(
        id: json['id']?.toString() ?? '',
        bankName: json['bankName']?.toString() ?? json['bank_name']?.toString() ?? 'Unnamed Bank',
        bankCode: json['bankCode']?.toString() ?? json['bank_code']?.toString() ?? 'N/A',
        headOfficeLocation: json['headOfficeLocation']?.toString() ?? json['head_office_location']?.toString() ?? 'Remote',
        contactEmail: json['contactEmail']?.toString() ?? json['contact_email']?.toString(),
        contactPhone: json['contactPhone']?.toString() ?? json['contact_phone']?.toString(),
        status: (json['status']?.toString().toUpperCase() == 'ACTIVE') ? BankStatus.active : BankStatus.inactive,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '') ?? DateTime.now(),
        branchCount: int.tryParse(json['_count']?['branches']?.toString() ?? '0') ?? 0,
      );
    } catch (e) {
      debugPrint('Error parsing BankModel: $e');
      return BankModel(
        id: 'error',
        bankName: 'Error Loading Data',
        bankCode: 'ERR',
        headOfficeLocation: 'ERR',
        status: BankStatus.inactive,
        createdAt: DateTime.now(),
      );
    }
  }
}

class BranchModel {
  final String id;
  final String bankId;
  final String branchName;
  final String district;
  final String sector;
  final String address;
  final String? contactPhone;
  final BankStatus status;

  BranchModel({
    required this.id,
    required this.bankId,
    required this.branchName,
    required this.district,
    required this.sector,
    required this.address,
    this.contactPhone,
    required this.status,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    try {
      return BranchModel(
        id: json['id']?.toString() ?? '',
        bankId: json['bankId']?.toString() ?? json['bank_id']?.toString() ?? '',
        branchName: json['branchName']?.toString() ?? json['branch_name']?.toString() ?? 'Unnamed Branch',
        district: json['district']?.toString() ?? 'N/A',
        sector: json['sector']?.toString() ?? 'N/A',
        address: json['address']?.toString() ?? 'N/A',
        contactPhone: json['contactPhone']?.toString() ?? json['contact_phone']?.toString(),
        status: (json['status']?.toString().toUpperCase() == 'ACTIVE') ? BankStatus.active : BankStatus.inactive,
      );
    } catch (e) {
      debugPrint('Error parsing BranchModel: $e');
      return BranchModel(
        id: 'error',
        bankId: '',
        branchName: 'Error Loading Branch',
        district: 'ERR',
        sector: 'ERR',
        address: 'ERR',
        status: BankStatus.inactive,
      );
    }
  }
}

class BankServiceModel {
  final String id;
  final String bankId;
  final String serviceName;
  final String? description;
  final bool enabled;

  BankServiceModel({
    required this.id,
    required this.bankId,
    required this.serviceName,
    this.description,
    this.enabled = true,
  });

  factory BankServiceModel.fromJson(Map<String, dynamic> json) {
    try {
      return BankServiceModel(
        id: json['id']?.toString() ?? '',
        bankId: json['bankId']?.toString() ?? json['bank_id']?.toString() ?? '',
        serviceName: json['serviceName']?.toString() ?? json['service_name']?.toString() ?? 'Unnamed Service',
        description: json['description']?.toString(),
        enabled: json['enabled'] == true || json['enabled'] == 'true',
      );
    } catch (e) {
      debugPrint('Error parsing BankServiceModel: $e');
      return BankServiceModel(
        id: 'error',
        bankId: '',
        serviceName: 'Error Loading Service',
        enabled: false,
      );
    }
  }
}

class BankCaseModel {
  final String id;
  final String caseReference;
  final String bankId;
  final String branchId;
  final String serviceId;
  final String submitterId;
  final String description;
  final String? evidenceUrl;
  final BankCaseStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relations (optional)
  final String? bankName;
  final String? branchName;
  final String? serviceName;

  BankCaseModel({
    required this.id,
    required this.caseReference,
    required this.bankId,
    required this.branchId,
    required this.serviceId,
    required this.submitterId,
    required this.description,
    this.evidenceUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.bankName,
    this.branchName,
    this.serviceName,
  });

  factory BankCaseModel.fromJson(Map<String, dynamic> json) {
    try {
      return BankCaseModel(
        id: json['id']?.toString() ?? '',
        caseReference: json['caseReference']?.toString() ?? json['case_reference']?.toString() ?? 'REF-N/A',
        bankId: json['bankId']?.toString() ?? json['bank_id']?.toString() ?? '',
        branchId: json['branchId']?.toString() ?? json['branch_id']?.toString() ?? '',
        serviceId: json['serviceId']?.toString() ?? json['service_id']?.toString() ?? '',
        submitterId: json['submitterId']?.toString() ?? json['submitter_id']?.toString() ?? '',
        description: json['description']?.toString() ?? 'No description provided.',
        evidenceUrl: json['evidenceUrl']?.toString() ?? json['evidence_url']?.toString(),
        status: _parseStatus(json['status']?.toString()),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? json['updated_at']?.toString() ?? '') ?? DateTime.now(),
        bankName: json['bank']?['bankName']?.toString() ?? json['bank']?['bank_name']?.toString(),
        branchName: json['branch']?['branchName']?.toString() ?? json['branch']?['branch_name']?.toString(),
        serviceName: json['service']?['serviceName']?.toString() ?? json['service']?['service_name']?.toString(),
      );
    } catch (e) {
      debugPrint('Error parsing BankCaseModel: $e');
      return BankCaseModel(
        id: 'error',
        caseReference: 'ERR-DATA',
        bankId: '',
        branchId: '',
        serviceId: '',
        submitterId: '',
        description: 'Error loading case data',
        status: BankCaseStatus.received,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  static BankCaseStatus _parseStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'RECEIVED': return BankCaseStatus.received;
      case 'UNDER_REVIEW': return BankCaseStatus.underReview;
      case 'INVESTIGATION': return BankCaseStatus.investigation;
      case 'RESOLVED': return BankCaseStatus.resolved;
      case 'ESCALATED': return BankCaseStatus.escalated;
      default: return BankCaseStatus.received;
    }
  }
  
  String get statusLabel {
    switch (status) {
      case BankCaseStatus.received: return 'Received';
      case BankCaseStatus.underReview: return 'Under Review';
      case BankCaseStatus.investigation: return 'Investigation';
      case BankCaseStatus.resolved: return 'Resolved';
      case BankCaseStatus.escalated: return 'Escalated';
    }
  }
}
