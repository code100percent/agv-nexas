/// Target user roles as specified in product requirements.
enum UserRole {
  factoryOperator('Factory Operator'),
  roboticsEngineer('Robotics Engineer'),
  maintenanceEngineer('Maintenance Engineer'),
  fleetAdmin('Fleet Administrator');

  final String displayName;
  const UserRole(this.displayName);

  static UserRole fromDatabase(String? roleStr) {
    switch (roleStr?.toLowerCase().replaceAll(' ', '')) {
      case 'owner':
      case 'admin':
      case 'fleetadmin':
      case 'fleetadministrator':
        return UserRole.fleetAdmin;
      case 'engineer':
      case 'roboticsengineer':
        return UserRole.roboticsEngineer;
      case 'operator':
      case 'factoryoperator':
        return UserRole.factoryOperator;
      case 'viewer':
      case 'maintenanceengineer':
        return UserRole.maintenanceEngineer;
      default:
        return UserRole.maintenanceEngineer;
    }
  }

  String toDatabase() {
    switch (this) {
      case UserRole.fleetAdmin:
        return 'admin';
      case UserRole.roboticsEngineer:
        return 'engineer';
      case UserRole.factoryOperator:
        return 'operator';
      case UserRole.maintenanceEngineer:
        return 'viewer';
    }
  }
}

/// User profile domain model.
class UserModel {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String organizationId;
  final String organizationName;
  final DateTime createdAt;
  final String? avatarPath;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.organizationId,
    required this.organizationName,
    required this.createdAt,
    this.avatarPath,
  });

  bool get isAdmin => role == UserRole.fleetAdmin;
  bool get canDispatchMissions =>
      role == UserRole.factoryOperator ||
      role == UserRole.roboticsEngineer ||
      role == UserRole.fleetAdmin;
  bool get canModifyConfigurations =>
      role == UserRole.roboticsEngineer || role == UserRole.fleetAdmin;

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    UserRole? role,
    String? organizationId,
    String? organizationName,
    DateTime? createdAt,
    String? avatarPath,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      organizationId: organizationId ?? this.organizationId,
      organizationName: organizationName ?? this.organizationName,
      createdAt: createdAt ?? this.createdAt,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'role': role.toDatabase(),
      'organizationId': organizationId,
      'organizationName': organizationName,
      'createdAt': createdAt.toIso8601String(),
      'avatarPath': avatarPath,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      email: map['email'] as String? ?? '',
      fullName:
          map['fullName'] as String? ??
          map['display_name'] as String? ??
          'Operator',
      role: UserRole.fromDatabase(map['role'] as String?),
      organizationId:
          map['organizationId'] as String? ??
          map['organization_id'] as String? ??
          '',
      organizationName:
          map['organizationName'] as String? ??
          map['organization_name'] as String? ??
          'Nexus Plant 1',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      avatarPath: map['avatarPath'] as String? ?? map['avatar_path'] as String?,
    );
  }

  factory UserModel.fromSupabase({
    required String id,
    required String email,
    required Map<String, dynamic>? profileMap,
    Map<String, dynamic>? memberMap,
    Map<String, dynamic>? orgMap,
  }) {
    final displayName =
        profileMap?['display_name'] as String? ?? email.split('@').first;
    final roleStr = memberMap?['role'] as String?;
    final orgId =
        memberMap?['organization_id'] as String? ??
        orgMap?['id'] as String? ??
        'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
    final orgName = orgMap?['name'] as String? ?? 'Nexus Gigafactory Alpha';
    final createdAtStr = profileMap?['created_at'] as String?;

    return UserModel(
      id: id,
      email: email,
      fullName: displayName,
      role: UserRole.fromDatabase(roleStr),
      organizationId: orgId,
      organizationName: orgName,
      createdAt: createdAtStr != null
          ? DateTime.parse(createdAtStr)
          : DateTime.now(),
      avatarPath: profileMap?['avatar_path'] as String?,
    );
  }
}
