class Company {
  final String id;
  final String name;
  final String? domain;
  final String? address;
  final String? phoneNumber;
  final String? email;
  final String? logoUrl;
  final String? subscriptionTier;
  final int? maxUsers;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Company({
    required this.id,
    required this.name,
    this.domain,
    this.address,
    this.phoneNumber,
    this.email,
    this.logoUrl,
    this.subscriptionTier,
    this.maxUsers,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as String,
      name: json['name'] as String,
      domain: json['domain'] as String?,
      address: json['address'] as String?,
      phoneNumber: json['phone_number'] as String? ?? json['phoneNumber'] as String?,
      email: json['email'] as String?,
      logoUrl: json['logo_url'] as String? ?? json['logoUrl'] as String?,
      subscriptionTier: json['subscription_tier'] as String? ?? json['subscriptionTier'] as String?,
      maxUsers: json['max_users'] as int? ?? json['maxUsers'] as int?,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String? ?? json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String? ?? json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'domain': domain,
      'address': address,
      'phone_number': phoneNumber,
      'email': email,
      'logo_url': logoUrl,
      'subscription_tier': subscriptionTier,
      'max_users': maxUsers,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

