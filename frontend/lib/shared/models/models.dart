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
  final String? phone;
  final String? email;
  final String status;

  const UserModel({
    required this.id,
    required this.role,
    this.phone,
    this.email,
    required this.status,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      role: json['role'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }

  bool get isCitizen => role == 'CITIZEN';
  bool get isLeader => role == 'LEADER';
  bool get isAdmin => role == 'ADMIN';
}
