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
