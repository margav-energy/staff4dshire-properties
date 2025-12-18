class CompanyInvitation {
  final String id;
  final String companyId;
  final String email;
  final String invitationToken;
  final String role;
  final String? invitedById;
  final DateTime expiresAt;
  final DateTime? usedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Company details (when fetched with token)
  final String? companyName;
  final String? companyEmail;
  final String? companyPhone;
  final String? companyAddress;
  
  // Invited by details
  final String? invitedByName;
  final String? invitedByLastName;

  CompanyInvitation({
    required this.id,
    required this.companyId,
    required this.email,
    required this.invitationToken,
    required this.role,
    this.invitedById,
    required this.expiresAt,
    this.usedAt,
    required this.createdAt,
    required this.updatedAt,
    this.companyName,
    this.companyEmail,
    this.companyPhone,
    this.companyAddress,
    this.invitedByName,
    this.invitedByLastName,
  });

  factory CompanyInvitation.fromJson(Map<String, dynamic> json) {
    return CompanyInvitation(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      email: json['email'] as String,
      invitationToken: json['invitation_token'] as String,
      role: json['role'] as String,
      invitedById: json['invited_by'] as String?,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      usedAt: json['used_at'] != null ? DateTime.parse(json['used_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      companyName: json['company_name'] as String?,
      companyEmail: json['company_email'] as String?,
      companyPhone: json['company_phone'] as String?,
      companyAddress: json['company_address'] as String?,
      invitedByName: json['invited_by_name'] as String?,
      invitedByLastName: json['invited_by_last_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'email': email,
      'invitation_token': invitationToken,
      'role': role,
      'invited_by': invitedById,
      'expires_at': expiresAt.toIso8601String(),
      'used_at': usedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isExpired => expiresAt.isBefore(DateTime.now());
  bool get isUsed => usedAt != null;
  bool get isValid => !isExpired && !isUsed;
  
  String get fullInvitedByName {
    if (invitedByName != null && invitedByLastName != null) {
      return '$invitedByName $invitedByLastName';
    }
    if (invitedByName != null) return invitedByName!;
    if (invitedByLastName != null) return invitedByLastName!;
    return 'Unknown';
  }
}



