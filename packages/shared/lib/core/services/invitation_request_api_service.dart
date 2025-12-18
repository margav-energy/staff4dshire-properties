import '../config/api_config.dart';
import 'api_service.dart';

class InvitationRequest {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? companyName;
  final String? phoneNumber;
  final String? message;
  final String status;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;

  InvitationRequest({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.companyName,
    this.phoneNumber,
    this.message,
    required this.status,
    required this.createdAt,
    this.approvedAt,
    this.rejectedAt,
    this.rejectionReason,
  });

  factory InvitationRequest.fromJson(Map<String, dynamic> json) {
    return InvitationRequest(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      companyName: json['company_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      message: json['message'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      approvedAt: json['approved_at'] != null 
          ? DateTime.parse(json['approved_at'] as String) 
          : null,
      rejectedAt: json['rejected_at'] != null 
          ? DateTime.parse(json['rejected_at'] as String) 
          : null,
      rejectionReason: json['rejection_reason'] as String?,
    );
  }
}

class InvitationRequestApiService {
  /// Submit an invitation request
  /// companyName is now required - a new company will be created if it doesn't exist
  static Future<Map<String, dynamic>> submitRequest({
    required String email,
    required String firstName,
    required String lastName,
    required String companyName, // Now required
    String? phoneNumber,
    String? message,
  }) async {
    // Validate required fields before sending
    final trimmedCompanyName = companyName.trim();
    if (trimmedCompanyName.isEmpty) {
      throw Exception('Company name is required. Please provide your company name to create an account.');
    }
    
    try {
      final data = <String, dynamic>{
        'email': email.trim().toLowerCase(),
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'company_name': trimmedCompanyName, // Required and validated
      };
      
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        data['phone_number'] = phoneNumber.trim();
      }
      if (message != null && message.isNotEmpty) {
        data['message'] = message.trim();
      }
      
      final response = await ApiService.post('/invitation-requests', data);
      return response as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Get all invitation requests (for superadmins)
  static Future<List<InvitationRequest>> getRequests({String? status}) async {
    try {
      String endpoint = '/invitation-requests';
      if (status != null) {
        endpoint += '?status=$status';
      }
      final response = await ApiService.get(endpoint);
      if (response is List) {
        return response.map((json) => InvitationRequest.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}

