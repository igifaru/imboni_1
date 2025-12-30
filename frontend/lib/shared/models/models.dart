export 'location_selection.dart';
/// Case model for API responses
class CaseModel {
  final String id;
  final String caseReference;
  final String category;
  final String urgency;
  final String title;
  final String description;
  final String currentLevel;
  final String status;
  final bool isAnonymous;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final DateTime? deadline;
  final String? audioUrl;
  final String? imageUrl;
  final String? citizenName;
  final List<EvidenceModel>? evidence;
  final String? locationName;
  final String? administrativeUnitCode;

  const CaseModel({
    required this.id,
    required this.caseReference,
    required this.category,
    required this.urgency,
    required this.title,
    required this.description,
    required this.currentLevel,
    required this.status,
    required this.isAnonymous,
    required this.createdAt,
    this.resolvedAt,
    this.deadline,
    this.audioUrl,
    this.imageUrl,
    this.citizenName,
    this.evidence,
    this.locationName,
    this.administrativeUnitCode,
  });

  factory CaseModel.fromJson(Map<String, dynamic> json) {
    return CaseModel(
      id: json['id'] as String,
      caseReference: json['caseReference'] as String,
      category: json['category'] as String,
      urgency: json['urgency'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      currentLevel: json['currentLevel'] as String,
      status: json['status'] as String,
      isAnonymous: json['submittedAnonymously'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt'] as String) : null,
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline'] as String) : null,
      audioUrl: json['audioUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      citizenName: json['citizenName'] as String?,
      evidence: json['evidence'] != null 
          ? (json['evidence'] as List).map((e) => EvidenceModel.fromJson(e)).toList() 
          : null,
      locationName: json['locationName'] as String?,
      administrativeUnitCode: json['administrativeUnit']?['code'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'caseReference': caseReference,
    'category': category,
    'urgency': urgency,
    'title': title,
    'description': description,
    'currentLevel': currentLevel,
    'status': status,
    'submittedAnonymously': isAnonymous,
    'createdAt': createdAt.toIso8601String(),
    'resolvedAt': resolvedAt?.toIso8601String(),
    'deadline': deadline?.toIso8601String(),
    'audioUrl': audioUrl,
    'imageUrl': imageUrl,
    'citizenName': citizenName,
  };
}

/// Create case request
class CreateCaseRequest {
  final String category;
  final String urgency;
  final String title;
  final String description;
  final String administrativeUnitId;
  final bool submittedAnonymously;

  const CreateCaseRequest({
    required this.category,
    this.urgency = 'NORMAL',
    required this.title,
    required this.description,
    required this.administrativeUnitId,
    this.submittedAnonymously = false,
  });

  Map<String, dynamic> toJson() => {
    'category': category,
    'urgency': urgency,
    'title': title,
    'description': description,
    'administrativeUnitId': administrativeUnitId,
    'submittedAnonymously': submittedAnonymously,
  };
}

/// User model
class UserModel {
  final String id;
  final String role;
  final String? name;
  final String? phone;
  final String? email;
  final String? profilePicture;
  final String status;
  final DateTime? createdAt;
  final String? nationalId;
  // Location hierarchy
  final String? country;
  final String? province;
  final String? district;
  final String? sector;
  final String? cell;
  final String? village;

  const UserModel({
    required this.id,
    required this.role,
    this.name,
    this.phone,
    this.email,
    this.profilePicture,
    required this.status,
    this.createdAt,
    this.nationalId,
    this.country,
    this.province,
    this.district,
    this.sector,
    this.cell,
    this.village,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      role: json['role'] as String,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      profilePicture: json['profilePicture'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      nationalId: json['nationalId'] as String?,
      country: json['country'] as String? ?? 'Rwanda',
      province: json['province'] as String?,
      district: json['district'] as String?,
      sector: json['sector'] as String?,
      cell: json['cell'] as String?,
      village: json['village'] as String?,
    );
  }

  /// Full location string from country to village
  String get fullLocation {
    final parts = <String>[];
    if (country != null) parts.add(country!);
    if (province != null) parts.add(province!);
    if (district != null) parts.add(district!);
    if (sector != null) parts.add(sector!);
    if (cell != null) parts.add(cell!);
    if (village != null) parts.add(village!);
    return parts.isNotEmpty ? parts.join(' → ') : 'Ntabwo yuzuye';
  }

  /// Display name - prefer name, fallback to phone, then email
  String get displayName => name ?? phone ?? email ?? 'User';
  
  /// Initials for avatar
  String get initials {
    if (name != null && name!.isNotEmpty) {
      final parts = name!.split(' ');
      if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      return name!.substring(0, 2).toUpperCase();
    }
    if (phone != null && phone!.length >= 2) return phone!.substring(0, 2).toUpperCase();
    return 'U';
  }

  /// Role display name
  String get roleDisplayName {
    switch (role) {
      case 'CITIZEN': return 'Umuturage';
      case 'LEADER': return 'Umuyobozi';
      case 'ADMIN': return 'Umuyobozi Mukuru';
      case 'OVERSIGHT': return 'Umugenzuzi';
      case 'NGO': return 'ONG';
      default: return role;
    }
  }

  /// Status display name
  String get statusDisplayName {
    switch (status) {
      case 'ACTIVE': return 'Irakora';
      case 'SUSPENDED': return 'Yahagaritswe';
      case 'INACTIVE': return 'Ntikora';
      default: return status;
    }
  }

  bool get isCitizen => role == 'CITIZEN';
  bool get isLeader => role == 'LEADER';
  bool get isAdmin => role == 'ADMIN';
}

/// Performance Metrics model
class PerformanceMetrics {
  final int totalCases;
  final int resolvedCases;
  final int pendingCases;
  final int escalatedCases;
  final double resolutionRate; // Changed to double for precision
  final double avgResponseTimeHours;
  final double escalationRate; // New
  final int overdueCases; // New
  final Map<String, int> casesByCategory;
  final List<DailyTrend> weeklyTrends;
  final List<SubUnitPerformance> subUnitBreakdown; // New

  PerformanceMetrics({
    required this.totalCases,
    required this.resolvedCases,
    required this.pendingCases,
    required this.escalatedCases,
    required this.resolutionRate,
    required this.avgResponseTimeHours,
    required this.escalationRate,
    required this.overdueCases,
    required this.casesByCategory,
    required this.weeklyTrends,
    required this.subUnitBreakdown,
  });

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) {
    var trends = <DailyTrend>[];
    if (json['weeklyTrends'] != null) {
      json['weeklyTrends'].forEach((v) {
        trends.add(DailyTrend.fromJson(v));
      });
    }

    var breakdown = <SubUnitPerformance>[];
    if (json['subUnitBreakdown'] != null) {
      json['subUnitBreakdown'].forEach((v) {
        breakdown.add(SubUnitPerformance.fromJson(v));
      });
    }
    
    return PerformanceMetrics(
      totalCases: json['totalCases'] ?? 0,
      resolvedCases: json['resolvedCases'] ?? 0,
      pendingCases: json['pendingCases'] ?? 0,
      escalatedCases: json['escalatedCases'] ?? 0,
      resolutionRate: (json['resolutionRate'] ?? 0).toDouble(),
      avgResponseTimeHours: (json['avgResponseTimeHours'] ?? 0).toDouble(),
      escalationRate: (json['escalationRate'] ?? 0).toDouble(),
      overdueCases: json['overdueCases'] ?? 0,
      casesByCategory: Map<String, int>.from(json['casesByCategory'] ?? {}),
      weeklyTrends: trends,
      subUnitBreakdown: breakdown,
    );
  }

  factory PerformanceMetrics.empty() {
    return PerformanceMetrics(
      totalCases: 0,
      resolvedCases: 0,
      pendingCases: 0,
      escalatedCases: 0,
      resolutionRate: 0,
      avgResponseTimeHours: 0,
      escalationRate: 0,
      overdueCases: 0,
      casesByCategory: {},
      weeklyTrends: [],
      subUnitBreakdown: [],
    );
  }
}

class DailyTrend {
  final String day;
  final String date;
  final int newCases;
  final int resolvedCases;
  int activeCases; // Added activeCases

  DailyTrend({
    required this.day, 
    required this.date, 
    required this.newCases, 
    required this.resolvedCases,
    this.activeCases = 0,
  });

  factory DailyTrend.fromJson(Map<String, dynamic> json) {
    return DailyTrend(
      day: json['day'] ?? '',
      date: json['date'] ?? '',
      newCases: json['newCases'] ?? 0,
      resolvedCases: json['resolvedCases'] ?? 0,
      activeCases: json['activeCases'] ?? 0,
    );
  }
}

class SubUnitPerformance {
  final String unitId;
  final String unitName;
  final int totalCases;
  final int openCases;
  final int resolvedCases;
  final int escalatedCases;
  final double resolutionRate;
  final double avgResponseTimeHours;
  final double escalationRate;
  final String status; // 'On Track', 'At Risk', 'Behind'

  SubUnitPerformance({
    required this.unitId,
    required this.unitName,
    required this.totalCases,
    this.openCases = 0,
    this.resolvedCases = 0,
    this.escalatedCases = 0,
    required this.resolutionRate,
    required this.avgResponseTimeHours,
    required this.escalationRate,
    required this.status,
  });

  factory SubUnitPerformance.fromJson(Map<String, dynamic> json) {
    return SubUnitPerformance(
      unitId: json['unitId'] ?? '',
      unitName: json['unitName'] ?? 'Unknown',
      totalCases: json['totalCases'] ?? 0,
      openCases: json['openCases'] ?? 0,
      resolvedCases: json['resolvedCases'] ?? 0,
      escalatedCases: json['escalatedCases'] ?? 0,
      resolutionRate: (json['resolutionRate'] ?? 0).toDouble(),
      avgResponseTimeHours: (json['avgResponseTimeHours'] ?? 0).toDouble(),
      escalationRate: (json['escalationRate'] ?? 0).toDouble(),
      status: json['status'] ?? 'On Track',
    );
  }
}

/// Evidence model
class EvidenceModel {
  final String id;
  final String type;
  final String url;
  final String fileName;
  final String mimeType;

  EvidenceModel({
    required this.id,
    required this.type,
    required this.url,
    required this.fileName,
    required this.mimeType,
  });


  factory EvidenceModel.fromJson(Map<String, dynamic> json) {
    return EvidenceModel(
      id: json['id'] as String,
      type: json['type'] as String,
      url: json['url'] as String,
      fileName: json['fileName'] as String,
      mimeType: json['mimeType'] as String,
    );
  }
}

/// Case Action/History model
class CaseAction {
  final String id;
  final String actionType;
  final String? notes;
  final String? performedBy;
  final DateTime createdAt;

  CaseAction({
    required this.id,
    required this.actionType,
    this.notes,
    this.performedBy,
    required this.createdAt,
  });

  factory CaseAction.fromJson(Map<String, dynamic> json) {
    return CaseAction(
      id: json['id'] as String,
      actionType: json['actionType'] as String,
      notes: json['notes'] as String?,
      performedBy: json['performedBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

