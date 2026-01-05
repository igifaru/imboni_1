// PFTCV Models - Public Fund Transparency & Citizen Verification
import 'package:flutter/material.dart';

enum ProjectSector {
  roads, health, education, water, socialAid, agriculture, energy, other;

  String get label {
    switch (this) {
      case ProjectSector.roads: return 'Imihanda';
      case ProjectSector.health: return 'Ubuzima';
      case ProjectSector.education: return 'Uburezi';
      case ProjectSector.water: return 'Amazi';
      case ProjectSector.socialAid: return 'Ubufasha';
      case ProjectSector.agriculture: return 'Ubuhinzi';
      case ProjectSector.energy: return 'Ingufu';
      case ProjectSector.other: return 'Ibindi';
    }
  }

  IconData get icon {
    switch (this) {
      case ProjectSector.roads: return Icons.add_road;
      case ProjectSector.health: return Icons.local_hospital;
      case ProjectSector.education: return Icons.school;
      case ProjectSector.water: return Icons.water_drop;
      case ProjectSector.socialAid: return Icons.volunteer_activism;
      case ProjectSector.agriculture: return Icons.agriculture;
      case ProjectSector.energy: return Icons.bolt;
      case ProjectSector.other: return Icons.category;
    }
  }

  static ProjectSector fromString(String value) {
    return ProjectSector.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase() || e.name == value,
      orElse: () => ProjectSector.other,
    );
  }
}

enum ProjectStatus { planned, inProgress, completed, suspended, cancelled;
  String get label {
    switch (this) {
      case ProjectStatus.planned: return 'Byateganyijwe';
      case ProjectStatus.inProgress: return 'Birigukorwa';
      case ProjectStatus.completed: return 'Byarangiye';
      case ProjectStatus.suspended: return 'Byahagaritswe';
      case ProjectStatus.cancelled: return 'Byahagaritswe burundu';
    }
  }

  Color get color {
    switch (this) {
      case ProjectStatus.planned: return Colors.blue;
      case ProjectStatus.inProgress: return Colors.orange;
      case ProjectStatus.completed: return Colors.green;
      case ProjectStatus.suspended: return Colors.amber;
      case ProjectStatus.cancelled: return Colors.red;
    }
  }

  static ProjectStatus fromString(String value) {
    final normalized = value.replaceAll('_', '').toLowerCase();
    return ProjectStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == normalized,
      orElse: () => ProjectStatus.planned,
    );
  }
}

enum RiskLevel { normal, needsReview, highRisk;
  String get label {
    switch (this) {
      case RiskLevel.normal: return 'Bisanzwe';
      case RiskLevel.needsReview: return 'Bikeneye Isuzuma';
      case RiskLevel.highRisk: return 'Byihutirwa';
    }
  }

  Color get color {
    switch (this) {
      case RiskLevel.normal: return Colors.green;
      case RiskLevel.needsReview: return Colors.amber;
      case RiskLevel.highRisk: return Colors.red;
    }
  }

  static RiskLevel fromString(String value) {
    final normalized = value.replaceAll('_', '').toLowerCase();
    return RiskLevel.values.firstWhere(
      (e) => e.name.toLowerCase() == normalized,
      orElse: () => RiskLevel.normal,
    );
  }
}

enum DeliveryStatus { fullyDelivered, partiallyDelivered, notDelivered, notStarted;
  String get label {
    switch (this) {
      case DeliveryStatus.fullyDelivered: return 'Byuzuye';
      case DeliveryStatus.partiallyDelivered: return 'Bimwe na bimwe';
      case DeliveryStatus.notDelivered: return 'Ntabyo byagezwe';
      case DeliveryStatus.notStarted: return 'Ntibyo byatangiye';
    }
  }

  static DeliveryStatus fromString(String value) {
    final normalized = value.replaceAll('_', '').toLowerCase();
    return DeliveryStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == normalized,
      orElse: () => DeliveryStatus.notStarted,
    );
  }
}

class Project {
  final String id;
  final String projectCode;
  final String name;
  final ProjectSector sector;
  final String? description;
  final String? locationName;
  final String? locationId;
  final double? gpsLatitude;
  final double? gpsLongitude;
  final double approvedBudget;
  final double totalReleased;
  final String? fundingSource;
  final String? implementingAgency;
  final String? expectedOutputs;
  final DateTime? startDate;
  final DateTime? endDate;
  final ProjectStatus status;
  final RiskLevel riskLevel;
  final int riskScore;
  final int verifiedPercentage;
  final int verificationCount;
  final DateTime createdAt;

  Project({
    required this.id,
    required this.projectCode,
    required this.name,
    required this.sector,
    this.description,
    this.locationName,
    this.locationId,
    this.gpsLatitude,
    this.gpsLongitude,
    required this.approvedBudget,
    this.totalReleased = 0,
    this.fundingSource,
    this.implementingAgency,
    this.expectedOutputs,
    this.startDate,
    this.endDate,
    this.status = ProjectStatus.planned,
    this.riskLevel = RiskLevel.normal,
    this.riskScore = 0,
    this.verifiedPercentage = 0,
    this.verificationCount = 0,
    required this.createdAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    final unit = json['administrativeUnit'] as Map<String, dynamic>?;
    return Project(
      id: json['id'] ?? '',
      projectCode: json['projectCode'] ?? '',
      name: json['name'] ?? '',
      sector: ProjectSector.fromString(json['sector'] ?? 'OTHER'),
      description: json['description'],
      locationName: unit?['name'],
      locationId: json['administrativeUnitId'] ?? unit?['id'],
      gpsLatitude: (json['gpsLatitude'] as num?)?.toDouble(),
      gpsLongitude: (json['gpsLongitude'] as num?)?.toDouble(),
      approvedBudget: (json['approvedBudget'] as num?)?.toDouble() ?? 0,
      totalReleased: (json['totalReleased'] as num?)?.toDouble() ?? 0,
      fundingSource: json['fundingSource'],
      implementingAgency: json['implementingAgency'],
      expectedOutputs: json['expectedOutputs'],
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate']) : null,
      status: ProjectStatus.fromString(json['status'] ?? 'PLANNED'),
      riskLevel: RiskLevel.fromString(json['riskLevel'] ?? 'NORMAL'),
      riskScore: json['riskScore'] ?? 0,
      verifiedPercentage: json['verifiedPercentage'] ?? 0,
      verificationCount: json['verificationCount'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  String get budgetFormatted => 'RWF ${(approvedBudget / 1000000).toStringAsFixed(1)}M';
  String get releasedFormatted => 'RWF ${(totalReleased / 1000000).toStringAsFixed(1)}M';
  double get releaseRatio => approvedBudget > 0 ? totalReleased / approvedBudget : 0;
}

class FundRelease {
  final String id;
  final String projectId;
  final double amount;
  final DateTime releaseDate;
  final String? releaseRef;
  final String? description;

  FundRelease({required this.id, required this.projectId, required this.amount, required this.releaseDate, this.releaseRef, this.description});

  factory FundRelease.fromJson(Map<String, dynamic> json) {
    return FundRelease(
      id: json['id'] ?? '',
      projectId: json['projectId'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      releaseDate: DateTime.tryParse(json['releaseDate'] ?? '') ?? DateTime.now(),
      releaseRef: json['releaseRef'],
      description: json['description'],
    );
  }
}

class CitizenVerification {
  final String id;
  final String projectId;
  final String? verifierId;
  final bool isAnonymous;
  final DeliveryStatus deliveryStatus;
  final int completionPercent;
  final int? qualityRating;
  final String? comment;
  final DateTime verifiedAt;

  CitizenVerification({
    required this.id,
    required this.projectId,
    this.verifierId,
    this.isAnonymous = false,
    required this.deliveryStatus,
    this.completionPercent = 0,
    this.qualityRating,
    this.comment,
    required this.verifiedAt,
  });

  factory CitizenVerification.fromJson(Map<String, dynamic> json) {
    return CitizenVerification(
      id: json['id'] ?? '',
      projectId: json['projectId'] ?? '',
      verifierId: json['verifierId'],
      isAnonymous: json['isAnonymous'] ?? false,
      deliveryStatus: DeliveryStatus.fromString(json['deliveryStatus'] ?? 'NOT_STARTED'),
      completionPercent: json['completionPercent'] ?? 0,
      qualityRating: json['qualityRating'],
      comment: json['comment'],
      verifiedAt: DateTime.tryParse(json['verifiedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class PftcvStats {
  final int totalProjects;
  final double totalBudget;
  final double totalReleased;
  final int totalVerifications;
  final List<StatusCount> byStatus;
  final List<RiskCount> byRisk;

  PftcvStats({
    required this.totalProjects,
    required this.totalBudget,
    required this.totalReleased,
    required this.totalVerifications,
    required this.byStatus,
    required this.byRisk,
  });

  factory PftcvStats.fromJson(Map<String, dynamic> json) {
    return PftcvStats(
      totalProjects: json['totalProjects'] ?? 0,
      totalBudget: (json['totalBudget'] as num?)?.toDouble() ?? 0,
      totalReleased: (json['totalReleased'] as num?)?.toDouble() ?? 0,
      totalVerifications: json['totalVerifications'] ?? 0,
      byStatus: (json['byStatus'] as List?)?.map((e) => StatusCount.fromJson(e)).toList() ?? [],
      byRisk: (json['byRisk'] as List?)?.map((e) => RiskCount.fromJson(e)).toList() ?? [],
    );
  }
}

class StatusCount {
  final ProjectStatus status;
  final int count;
  StatusCount({required this.status, required this.count});
  factory StatusCount.fromJson(Map<String, dynamic> json) => StatusCount(
    status: ProjectStatus.fromString(json['status'] ?? 'PLANNED'),
    count: json['count'] ?? 0,
  );
}

class RiskCount {
  final RiskLevel riskLevel;
  final int count;
  RiskCount({required this.riskLevel, required this.count});
  factory RiskCount.fromJson(Map<String, dynamic> json) => RiskCount(
    riskLevel: RiskLevel.fromString(json['riskLevel'] ?? 'NORMAL'),
    count: json['count'] ?? 0,
  );
}
