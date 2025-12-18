import '../providers/auth_provider.dart' show UserRole;

class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;
  final String? phoneNumber;
  final String? photoUrl;
  final String? companyId;
  final bool isSuperadmin;
  final bool isActive;
  final DateTime? lastLogin;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.phoneNumber,
    this.photoUrl,
    this.companyId,
    this.isSuperadmin = false,
    this.isActive = true,
    this.lastLogin,
  });
  
  bool get canAccessAllCompanies => isSuperadmin || role == UserRole.superadmin;

  String get fullName => '$firstName $lastName';

  // Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role.toString().split('.').last, // Convert enum to string
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'company_id': companyId,
      'is_superadmin': isSuperadmin,
      'isActive': isActive,
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  // Create from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    UserRole userRole = UserRole.staff;
    final roleStr = json['role'] as String?;
    if (roleStr != null) {
      switch (roleStr.toLowerCase()) {
        case 'superadmin':
          userRole = UserRole.superadmin;
          break;
        case 'admin':
          userRole = UserRole.admin;
          break;
        case 'supervisor':
          userRole = UserRole.supervisor;
          break;
        default:
          userRole = UserRole.staff;
      }
    }

    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] ?? json['firstName'] as String,
      lastName: json['last_name'] ?? json['lastName'] as String,
      role: userRole,
      phoneNumber: json['phone_number'] ?? json['phoneNumber'] as String?,
      photoUrl: json['photo_url'] ?? json['photoUrl'] as String?,
      companyId: json['company_id'] ?? json['companyId'] as String?,
      isSuperadmin: (json['is_superadmin'] ?? json['isSuperadmin'] ?? false) as bool,
      isActive: json['is_active'] ?? json['isActive'] as bool? ?? true,
      lastLogin: (json['last_login'] ?? json['lastLogin']) != null
          ? DateTime.parse((json['last_login'] ?? json['lastLogin']) as String)
          : null,
    );
  }
}

